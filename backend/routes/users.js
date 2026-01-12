const router = require('express').Router();
const { User, Invite, Chat, Message } = require('../models');
const { Op, fn, col, where } = require('sequelize');
const verifyToken = require('../middleware/authMiddleware');
const multer = require('multer');
const path = require('path');

// Multer Setup
const storage = multer.diskStorage({
    destination: (req, file, cb) => cb(null, 'uploads/'),
    filename: (req, file, cb) => cb(null, Date.now() + '-' + file.originalname)
});
const upload = multer({ 
    storage, 
    limits: { fileSize: 5 * 1024 * 1024 }, // 5MB
    fileFilter: (req, file, cb) => {
        // Allow images based on standard mimes OR if octet-stream (often from mobile) check extension
        const allowedMimes = ['image/jpeg', 'image/png', 'image/jpg'];
        if(allowedMimes.includes(file.mimetype)) {
            cb(null, true);
        } else if (file.mimetype === 'application/octet-stream') {
             // Basic extension check
             const ext = path.extname(file.originalname).toLowerCase();
             if(['.jpg', '.jpeg', '.png'].includes(ext)) cb(null, true);
             else cb(new Error('Invalid file extension'), false);
        } else {
            cb(new Error('Only JPEG and PNG allowed'), false);
        }
    }
});

// Search Users
router.get('/search', verifyToken, async (req, res) => {
    try {
        const { query } = req.query;
        console.log(`Backend: Received search query: "${query}" from user ${req.user.id}`);
        
        if(!query) return res.json([]);
        
        const lowerQuery = `%${query.toLowerCase()}%`;
        console.log(`Backend: Searching for query pattern: ${lowerQuery}`);
        
        const users = await User.findAll({
            where: {
                [Op.and]: [
                    {
                        [Op.or]: [
                            { username: { [Op.like]: lowerQuery } },
                            { email: { [Op.like]: lowerQuery } }
                        ]
                    },
                    { id: { [Op.ne]: req.user.id } }
                ]
            },
            attributes: ['id', 'username', 'email', 'profilePicture', 'aboutMe'] 
        });
        
        console.log(`Backend: Found ${users.length} users matching "${query}"`);
        res.json(users);
    } catch (e) {
        console.error('Backend: Search error:', e);
        res.status(500).json({ error: e.message });
    }
});

// Get Profile
router.get('/profile', verifyToken, async (req, res) => {
    try {
        const user = await User.findByPk(req.user.id, {
             attributes: { exclude: ['password'] }
        });
        if (!user) return res.status(401).json({ error: 'User not found' });
        res.json(user);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

// Update Profile
router.put('/profile', verifyToken, upload.single('profilePicture'), async (req, res) => {
    try {
        console.log('Update Profile Request Body:', req.body);
        console.log('Update Profile File:', req.file);
        
        const { aboutMe } = req.body;
        const updateData = {};
        if(aboutMe !== undefined) updateData.aboutMe = aboutMe;
        if(req.file) updateData.profilePicture = req.file.path; // Store path
        
        console.log('Data to update:', updateData);

        await User.update(updateData, { where: { id: req.user.id } });
        const updated = await User.findByPk(req.user.id, { attributes: { exclude: ['password'] }});
        res.json(updated);
    } catch (e) {
        console.error('Profile update error:', e);
        res.status(500).json({ error: e.message });
    }
});

// Send Invite
router.post('/invites', verifyToken, async (req, res) => {
    console.log('--- POST /invites ---');
    console.log('Body:', req.body);
    console.log('User:', req.user);
    try {
        const { receiverId, chatId, groupName } = req.body;
        console.log(`Sending invite from ${req.user.id} to ${receiverId} for chat ${chatId}`);
        const existing = await Invite.findOne({
            where: { senderId: req.user.id, receiverId, ChatId: chatId || null, status: 'pending' }
        });
        if(existing) {
            console.log('Invite already exists');
            return res.status(400).json({ error: 'Invite already sent' });
        }
        
        // Check if already friends/chat exists? Skipping for simplicity, allowed to send.
        
        await Invite.create({ 
            senderId: req.user.id, 
            receiverId,
            ChatId: chatId || null,
            groupName: groupName
        });
        
        console.log(`Backend: Single invite created for user ${receiverId}. Emitting 'new_invite' to user_${receiverId}`);
        const io = req.app.get('io');
        io.to(`user_${receiverId}`).emit('new_invite', { sender: req.user.username });
        
        res.json({ message: 'Invite sent' });
    } catch (e) {
         res.status(500).json({ error: e.message });
    }
});

// Get Invites
router.get('/invites', verifyToken, async (req, res) => {
    try {
        const user = await User.findByPk(req.user.id);
        if (!user) return res.status(401).json({ error: 'User not found' });
        const invites = await Invite.findAll({
            where: { receiverId: req.user.id, status: 'pending' },
            include: [
                { model: User, as: 'Sender', attributes: ['username'] },
                { model: Chat, attributes: ['id', 'isGroup'] }
            ]
        });
        console.log(`Found ${invites.length} pending invites for user ${req.user.id}`);
        res.json(invites);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

// Respond to Invite
router.put('/invites/:id', verifyToken, async (req, res) => {
    console.log(`--- PUT /invites/${req.params.id} ---`);
    console.log('Body:', req.body);
    try {
        const { status } = req.body; // accepted, declined
        const invite = await Invite.findOne({ where: { id: req.params.id, receiverId: req.user.id }});
        if(!invite) return res.status(404).json({ error: 'Invite not found' });
        
        if(status === 'accepted') {
            console.log(`Backend: Processing Acceptance for Invite ID ${req.params.id}. Current DB Status: ${invite.status}`);
            
            if (invite.status === 'accepted') {
                console.log('Backend: Invite was already marked as accepted in DB.');
                return res.json({ message: 'Invite already accepted', chat: null });
            }
            
            let chat;
            try {
                if (invite.ChatId) {
                    console.log(`Backend: Adding user ${invite.receiverId} to Group Chat ${invite.ChatId}`);
                    chat = await Chat.findByPk(invite.ChatId);
                    if (!chat) throw new Error(`Group chat ${invite.ChatId} not found`);
                    await chat.addUsers(invite.receiverId);
                } else {
                    console.log(`Backend: Creating Direct Chat for users ${invite.senderId} and ${invite.receiverId}`);
                    chat = await Chat.create({ isGroup: false });
                    console.log(`Backend: Chat created with ID ${chat.id}`);
                    
                    console.log(`Backend: Adding user ${invite.senderId} to Chat ${chat.id}`);
                    await chat.addUsers(invite.senderId);
                    console.log(`Backend: Adding user ${invite.receiverId} to Chat ${chat.id}`);
                    await chat.addUsers(invite.receiverId);
                }
            } catch (innerError) {
                console.error('Backend: Database error during chat creation:', innerError);
                return res.status(500).json({ error: `Database error: ${innerError.message}` });
            }

            // ONLY NOW update the status
            invite.status = 'accepted';
            await invite.save();
            console.log(`Backend: Invite ${req.params.id} marked as accepted in DB.`);

            const io = req.app.get('io');
            const fullChat = await Chat.findByPk(chat.id, {
                include: [{ 
                    model: User, 
                    attributes: ['id', 'username', 'profilePicture'],
                    through: { attributes: [] }
                }]
            });
            
            console.log(`Backend: Emitting chat_created to user_${invite.senderId} and user_${invite.receiverId}`);
            io.to(`user_${invite.senderId}`).emit('chat_created', fullChat);
            io.to(`user_${invite.receiverId}`).emit('chat_created', fullChat);

            res.json({ message: 'Invite accepted', chat: fullChat });
        } else {
            console.log(`Backend: Invite ${req.params.id} declined`);
            invite.status = 'declined';
            await invite.save();
            res.json({ message: 'Invite declined' });
        }
    } catch (e) {
        if (e.name === 'SequelizeValidationError' || e.name === 'SequelizeUniqueConstraintError') {
            const details = e.errors.map(err => `${err.path}: ${err.message}`).join(', ');
            console.error(`Backend: Validation Error Details: ${details}`);
            return res.status(400).json({ error: `Validation error: ${details}` });
        }
        console.error('Backend: GLOBAL RESPOND INVITE ERROR:', e);
        res.status(500).json({ error: `Server error: ${e.message}` });
    }
});

module.exports = router;
