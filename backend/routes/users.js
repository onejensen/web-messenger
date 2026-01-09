const express = require('express');
const router = express.Router();
const { User, Invite } = require('../models');
const authMiddleware = require('../middleware/authMiddleware');
const multer = require('multer');
const path = require('path');
const { encrypt, decrypt } = require('../utils/encryption');
const { Op } = require('sequelize');

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'uploads/');
  },
  filename: (req, file, cb) => {
    cb(null, Date.now() + path.extname(file.originalname));
  }
});

const upload = multer({ 
    storage,
    fileFilter: (req, file, cb) => {
        const filetypes = /jpeg|jpg|png/;
        const mimetype = filetypes.test(file.mimetype);
        const extname = filetypes.test(path.extname(file.originalname).toLowerCase());
        if (mimetype && extname) return cb(null, true);
        cb(new Error("Error: File upload only supports JPEG and PNG"));
    }
});

// Search users
router.get('/search', authMiddleware, async (req, res) => {
  try {
    const { query } = req.query;
    const users = await User.findAll({
      where: {
        [Op.or]: [
          { username: { [Op.like]: `%${query}%` } },
          { email: { [Op.like]: `%${query}%` } }
        ],
        id: { [Op.ne]: req.user.id }
      },
      attributes: ['id', 'username', 'email', 'profilePic', 'aboutMe']
    });

    const processedUsers = users.map(u => {
        const userJson = u.toJSON();
        if (userJson.aboutMe) userJson.aboutMe = decrypt(userJson.aboutMe);
        return userJson;
    });

    res.json(processedUsers);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Invites
router.get('/invites', authMiddleware, async (req, res) => {
    try {
        const invites = await Invite.findAll({
            where: { receiverId: req.user.id, status: 'pending' },
            include: [{ model: User, as: 'sender', attributes: ['username', 'profilePic'] }]
        });
        res.json(invites);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

router.post('/invites', authMiddleware, async (req, res) => {
    try {
        const { receiverId } = req.body;
        const invite = await Invite.create({
            senderId: req.user.id,
            receiverId,
            status: 'pending'
        });
        
        const io = req.app.get('io');
        io.to(`user_${receiverId}`).emit('new_invite', invite);
        
        res.status(201).json(invite);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

router.put('/invites/:id', authMiddleware, async (req, res) => {
    try {
        const { status } = req.body;
        const invite = await Invite.findByPk(req.params.id);
        if (!invite || invite.receiverId !== req.user.id) return res.status(404).json({ error: 'Invite not found' });

        invite.status = status;
        await invite.save();

        if (status === 'accepted') {
            const { Chat, Participant } = require('../models');
            const chat = await Chat.create({ name: 'Private Chat', isGroup: false });
            await Participant.create({ userId: invite.senderId, chatId: chat.id });
            await Participant.create({ userId: req.user.id, chatId: chat.id });
            
            const io = req.app.get('io');
            io.to(`user_${invite.senderId}`).emit('chat_created', { chatId: chat.id });
        }

        res.json(invite);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Profile
router.get('/profile', authMiddleware, async (req, res) => {
    try {
        const user = await User.findByPk(req.user.id);
        const userJson = user.toJSON();
        if (userJson.aboutMe) userJson.aboutMe = decrypt(userJson.aboutMe);
        res.json(userJson);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

router.put('/profile', authMiddleware, upload.single('profilePicture'), async (req, res) => {
  try {
    const { aboutMe } = req.body;
    const user = await User.findByPk(req.user.id);

    if (aboutMe !== undefined) user.aboutMe = encrypt(aboutMe);
    if (req.file) user.profilePic = `/uploads/${req.file.filename}`;

    await user.save();
    
    const userJson = user.toJSON();
    if (userJson.aboutMe) userJson.aboutMe = decrypt(userJson.aboutMe);
    res.json(userJson);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
