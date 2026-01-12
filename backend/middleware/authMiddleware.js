const jwt = require('jsonwebtoken');
const { User } = require('../models');

const verifyToken = async (req, res, next) => {
  const token = req.header('Authorization'); // "Bearer <token>"
  if (!token) return res.status(401).json({ error: 'Access denied' });

  try {
    // Basic "Bearer <token>" split
    const bearer = token.split(' ');
    const bearerToken = bearer[1] || token;

    console.log(`Backend: Verifying Token: ${bearerToken.substring(0, 10)}...`);
    const verified = jwt.verify(bearerToken, process.env.JWT_SECRET || 'secret_key_123');
    console.log(`Backend: Token Verified for User ID: ${verified.id}`);
    
    const user = await User.findByPk(verified.id);
    if (!user) {
      console.error(`Backend: User ID ${verified.id} from token not found in database.`);
      return res.status(401).json({ error: 'User not found in database. Please log in again.' });
    }

    req.user = verified;
    next();
  } catch (error) {
    console.error('Backend: JWT Verification Error:', error.message);
    res.status(401).json({ error: 'Invalid token' });
  }
};

module.exports = verifyToken;
