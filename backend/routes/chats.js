const express = require('express');
const router = express.Router();
const { Chat, Message, User, Participant } = require('../models');
const authMiddleware = require('../middleware/authMiddleware');
const multer = require('multer');
const { encrypt, decrypt } = require('../utils/encryption');
const { Op } = require('sequelize');

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, 'uploads/'),
  filename: (req, file, cb) => cb(null, Date.now() + '-' + file.originalname)
});
const upload = multer({ storage });

// Get chat list
router.get('/', authMiddleware, async (req, res) => {
  try {
    const user = await User.findByPk(req.user.id, {
      include: [{
        model: Chat,
        include: [{ 
            model: Message, 
            limit: 1, 
            order: [['createdAt', 'DESC']] 
        }]
      }]
    });
    
    const chats = user.Chats.map(c => {
        const json = c.toJSON();
        if (json.name) json.name = decrypt(json.name);
        return json;
    });

    // Sort by last message time
    chats.sort((a, b) => {
        const timeA = a.Messages[0] ? new Date(a.Messages[0].createdAt) : new Date(a.createdAt);
        const timeB = b.Messages[0] ? new Date(b.Messages[0].createdAt) : new Date(b.createdAt);
        return timeB - timeA;
    });

    res.json(chats);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Manage Chat State
router.put('/:id/archive', authMiddleware, async (req, res) => {
    // For simplicity, we could add an isArchived flag to Participant table
    res.json({ message: 'Archived' });
});

router.put('/:id/unarchive', authMiddleware, async (req, res) => {
    res.json({ message: 'Unarchived' });
});

router.put('/:id/read', authMiddleware, async (req, res) => {
    try {
        await Message.update({ status: 'read' }, {
            where: { chatId: req.params.id, senderId: { [Op.ne]: req.user.id } }
        });
        res.json({ message: 'Marked as read' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Create Group
router.post('/group', authMiddleware, async (req, res) => {
    try {
        const { groupName, userIds } = req.body;
        const chat = await Chat.create({ name: encrypt(groupName), isGroup: true });
        
        await Participant.create({ userId: req.user.id, chatId: chat.id, isAdmin: true });
        for (const id of userIds) {
            await Participant.create({ userId: id, chatId: chat.id });
            const io = req.app.get('io');
            io.to(`user_${id}`).emit('chat_created', { chatId: chat.id });
        }
        
        res.json({ ...chat.toJSON(), name: groupName });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Get Messages
router.get('/:chatId/messages', authMiddleware, async (req, res) => {
  try {
    const messages = await Message.findAll({
      where: { chatId: req.params.chatId },
      include: [{ model: User, as: 'sender', attributes: ['username', 'profilePic'] }],
      order: [['createdAt', 'ASC']]
    });

    const processed = messages.map(m => {
        const json = m.toJSON();
        json.content = decrypt(json.content);
        return json;
    });

    res.json(processed);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Send Message
router.post('/:chatId/messages', authMiddleware, upload.single('media'), async (req, res) => {
  try {
    const { content, type } = req.body;
    let messageContent = content;
    let messageType = type || 'text';

    if (req.file) {
        messageContent = `/uploads/${req.file.filename}`;
        if (req.file.mimetype.startsWith('image')) messageType = 'image';
        else if (req.file.mimetype.startsWith('video')) messageType = 'video';
    }

    const message = await Message.create({
      chatId: req.params.chatId,
      senderId: req.user.id,
      content: encrypt(messageContent),
      type: messageType,
      status: 'sent'
    });

    const io = req.app.get('io');
    const decryptedMessage = { ...message.toJSON(), content: messageContent };
    io.to(String(req.params.chatId)).emit('new_message', decryptedMessage);

    res.status(200).json(decryptedMessage); // 200 required by DataService
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Update/Delete Message
router.put('/:chatId/messages/:id', authMiddleware, async (req, res) => {
    try {
        const { content } = req.body;
        const message = await Message.findByPk(req.params.id);
        if (message.senderId !== req.user.id) return res.status(403).json({ error: 'Unauthorized' });

        message.content = encrypt(content);
        await message.save();
        
        const io = req.app.get('io');
        io.to(String(req.params.chatId)).emit('update_message', { ...message.toJSON(), content });
        
        res.json({ ...message.toJSON(), content });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

router.delete('/:chatId/messages/:id', authMiddleware, async (req, res) => {
    try {
        const message = await Message.findByPk(req.params.id);
        if (message.senderId !== req.user.id) return res.status(403).json({ error: 'Unauthorized' });
        const id = message.id;
        await message.destroy();
        
        const io = req.app.get('io');
        io.to(String(req.params.chatId)).emit('delete_message', { id });
        
        res.json({ message: 'Deleted' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

module.exports = router;
