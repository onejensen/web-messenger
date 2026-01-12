const router = require('express').Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { User } = require('../models');
const { Op } = require('sequelize');
const { sendVerificationEmail, sendPasswordResetEmail } = require('../utils/email');

// Register
router.post('/register', async (req, res) => {
  try {
    let { username, email, password } = req.body;
    email = email.toLowerCase();

    // Password Strength Check
    const passwordRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/;
    if (!passwordRegex.test(password)) {
      return res.status(400).json({ 
        error: 'Password must be at least 8 chars, 1 uppercase, 1 lowercase, 1 digit, 1 special char.' 
      });
    }

    // Check existing
    const existingUser = await User.findOne({
      where: {
        [Op.or]: [{ username }, { email }]
      }
    });
    if (existingUser) {
      if(existingUser.username === username) return res.status(400).json({ error: 'Username taken' });
      return res.status(400).json({ error: 'Email already registered' });
    }

    // Generate Verification Code
    const verificationCode = Math.floor(100000 + Math.random() * 900000).toString();

    // Hash Password
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    // Create User (Encryption hook runs automatically for profile fields if added)
    const newUser = await User.create({
      username,
      email,
      password: hashedPassword,
      verificationCode: verificationCode
    });

    // Send Real Email
    console.log(`Verification code for ${email}: ${verificationCode}`); // Log for Render console
    // Send Real Email (Non-blocking to avoid frontend timeout)
    console.log(`Verification code for ${email}: ${verificationCode}`);
    sendVerificationEmail(email, verificationCode).catch(err => {
      console.error('Background email send failed:', err);
    });

    res.status(201).json({ 
      message: 'User registered. Please check your email for the verification code.',
      user: { id: newUser.id, username: newUser.username, email: newUser.email }
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Login
router.post('/login', async (req, res) => {
  try {
    let { email, password } = req.body;
    email = email.toLowerCase();
    const user = await User.findOne({ where: { email } });
    if (!user) return res.status(400).json({ error: 'User not found' });

    if (!user.isVerified) {
      return res.status(403).json({ error: 'Email not verified', email: user.email });
    }

    const validPass = await bcrypt.compare(password, user.password);
    if (!validPass) return res.status(400).json({ error: 'Invalid password' });

    // Create Token
    const token = jwt.sign({ id: user.id, username: user.username }, process.env.JWT_SECRET || 'secret_key_123', { expiresIn: '7d' });

    res.json({ token, user: { id: user.id, username: user.username, email: user.email, profilePicture: user.profilePicture, aboutMe: user.aboutMe } });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Verify Registration
router.post('/verify-registration', async (req, res) => {
  try {
    let { email, code } = req.body;
    email = email.toLowerCase();
    const user = await User.findOne({ where: { email, verificationCode: code } });
    if (!user) return res.status(400).json({ error: 'Invalid verification code' });

    user.isVerified = true;
    user.verificationCode = null;
    await user.save();

    // Create Token to allow auto-login
    const token = jwt.sign({ id: user.id, username: user.username }, process.env.JWT_SECRET || 'secret_key_123', { expiresIn: '7d' });

    res.json({ 
      message: 'Email verified successfully.',
      token,
      user: { id: user.id, username: user.username, email: user.email, profilePicture: user.profilePicture, aboutMe: user.aboutMe }
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Resend Verification Code
router.post('/resend-verification', async (req, res) => {
  try {
    const { email } = req.body;
    const user = await User.findOne({ where: { email } });
    if (!user) return res.status(404).json({ error: 'User not found' });
    if (user.isVerified) return res.status(400).json({ error: 'Email already verified' });

    const newCode = Math.floor(100000 + Math.random() * 900000).toString();
    user.verificationCode = newCode;
    await user.save();

    console.log(`New verification code for ${email}: ${newCode}`);
    sendVerificationEmail(email, newCode).catch(err => {
      console.error('Background email resend failed:', err);
    });
    res.json({ message: 'New verification code sent' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Forgot Password
router.post('/forgot-password', async (req, res) => {
  try {
    const { email } = req.body;
    const user = await User.findOne({ where: { email } });
    if (!user) return res.status(400).json({ error: 'User with this email does not exist' });

    const resetToken = Math.random().toString(36).substring(2, 10);
    user.resetToken = resetToken;
    user.resetTokenExpires = Date.now() + 3600000; // 1 hour
    await user.save();

    // Send Real Email
    try {
      await sendPasswordResetEmail(email, resetToken);
    } catch (err) {
      console.error('Failed to send reset email:', err);
      return res.status(500).json({ error: 'Failed to send reset email. Please try again later.' });
    }

    res.json({ message: 'Password reset email sent' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Reset Password
router.post('/reset-password', async (req, res) => {
  try {
    const { token, newPassword } = req.body;
    const user = await User.findOne({ 
      where: { 
        resetToken: token,
        resetTokenExpires: { [Op.gt]: Date.now() }
      } 
    });
    if (!user) return res.status(400).json({ error: 'Invalid or expired reset token' });

    // Password Strength Check
    const passwordRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/;
    if (!passwordRegex.test(newPassword)) {
      return res.status(400).json({ 
        error: 'Password must be at least 8 chars, 1 uppercase, 1 lowercase, 1 digit, 1 special char.' 
      });
    }

    const salt = await bcrypt.genSalt(10);
    user.password = await bcrypt.hash(newPassword, salt);
    user.resetToken = null;
    user.resetTokenExpires = null;
    await user.save();

    res.json({ message: 'Password has been reset successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

const verifyToken = require('../middleware/authMiddleware');

// Change Password
router.put('/change-password', verifyToken, async (req, res) => {
  try {
    const { oldPassword, newPassword } = req.body;
    const user = await User.findByPk(req.user.id);
    if (!user) return res.status(401).json({ error: 'User not found' });

    const validPass = await bcrypt.compare(oldPassword, user.password);
    if (!validPass) return res.status(400).json({ error: 'Invalid old password' });

    // Password Strength Check
    const passwordRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/;
    if (!passwordRegex.test(newPassword)) {
      return res.status(400).json({ 
        error: 'New password must be at least 8 chars, 1 uppercase, 1 lowercase, 1 digit, 1 special char.' 
      });
    }

    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(newPassword, salt);
    user.password = hashedPassword;
    await user.save();

    res.json({ message: 'Password updated successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
