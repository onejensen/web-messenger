const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { User } = require('../models');
const crypto = require('crypto');
const authMiddleware = require('../middleware/authMiddleware');

const JWT_SECRET = process.env.JWT_SECRET || 'secret_key_123';

// Register
router.post('/register', async (req, res) => {
  try {
    const { username, email, password } = req.body;

    const existingUser = await User.findOne({ where: { email } });
    if (existingUser) return res.status(400).json({ error: 'Email already in use' });

    const existingUsername = await User.findOne({ where: { username } });
    if (existingUsername) return res.status(400).json({ error: 'Username already in use' });

    const hashedPassword = await bcrypt.hash(password, 10);
    // Requirement says "User's email is verified before creating an account"
    // Usually this means a "pending" state. We'll use isVerified flag.
    const verificationToken = Math.floor(100000 + Math.random() * 900000).toString(); // 6-digit code for frontend VerifyScreen

    await User.create({
      username,
      email,
      password: hashedPassword,
      verificationToken
    });

    res.status(201).json({ message: 'User registered. Please verify your email.', code: verificationToken });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Verify Registration
router.post('/verify-registration', async (req, res) => {
    try {
        const { email, code } = req.body;
        const user = await User.findOne({ where: { email, verificationToken: code } });
        if (!user) return res.status(400).json({ error: 'Invalid verification code' });

        user.isVerified = true;
        user.verificationToken = null;
        await user.save();

        res.json({ message: 'Email verified successfully' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Login
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    const user = await User.findOne({ where: { email } });

    if (!user) return res.status(400).json({ error: 'User not found' });
    if (!user.isVerified) return res.status(400).json({ error: 'Please verify your email first' });

    const validPass = await bcrypt.compare(password, user.password);
    if (!validPass) return res.status(400).json({ error: 'Invalid password' });

    const token = jwt.sign({ id: user.id, username: user.username }, JWT_SECRET);
    res.json({ token, user: { id: user.id, username: user.username, email: user.email, profilePic: user.profilePic, aboutMe: user.aboutMe } });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Change Password
router.put('/change-password', authMiddleware, async (req, res) => {
    try {
        const { oldPassword, newPassword } = req.body;
        const user = await User.findByPk(req.user.id);
        
        const validPass = await bcrypt.compare(oldPassword, user.password);
        if (!validPass) return res.status(400).json({ error: 'Invalid old password' });

        user.password = await bcrypt.hash(newPassword, 10);
        await user.save();
        res.json({ message: 'Password changed successfully' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Forgot Password
router.post('/forgot-password', async (req, res) => {
    try {
        const { email } = req.body;
        const user = await User.findOne({ where: { email } });
        if (!user) return res.status(400).json({ error: 'User not found' });

        const resetToken = crypto.randomBytes(20).toString('hex');
        user.resetToken = resetToken;
        await user.save();

        res.json({ message: 'Password reset token generated', resetToken });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Reset Password
router.post('/reset-password', async (req, res) => {
    try {
        const { token, newPassword } = req.body;
        const user = await User.findOne({ where: { resetToken: token } });
        if (!user) return res.status(400).json({ error: 'Invalid or expired token' });

        user.password = await bcrypt.hash(newPassword, 10);
        user.resetToken = null;
        await user.save();

        res.json({ message: 'Password reset successful' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

module.exports = router;
