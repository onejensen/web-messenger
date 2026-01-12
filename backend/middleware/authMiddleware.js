const jwt = require('jsonwebtoken');
const { User } = require('../models');

const verifyToken = async (req, res, next) => {
  const token = req.header('Authorization'); // "Bearer <token>"
  if (!token) return res.status(401).json({ error: 'Access denied' });

  try {
    // Improved token extraction
    let bearerToken = token;
    if (token.startsWith('Bearer ')) {
      bearerToken = token.split(' ')[1];
    }

    // If token is missing, empty, or string "null" (common from some frontend libs)
    if (!bearerToken || bearerToken === '' || bearerToken === 'null' || bearerToken === 'undefined') {
      console.log('Backend: Authorization header present but token is empty/invalid.');
      return res.status(401).json({ error: 'Invalid token' });
    }

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
