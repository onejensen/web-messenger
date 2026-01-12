const jwt = require('jsonwebtoken');
const { User } = require('../models');

const verifyToken = async (req, res, next) => {
  const token = req.header('Authorization'); // "Bearer <token>"
  if (!token) return res.status(401).json({ error: 'Access denied' });

  try {
    // Improved token extraction
    // Extremely robust token extraction
    console.log(`Backend: Raw Auth Header: "${token}"`);
    
    let bearerToken = token;
    if (token.toLowerCase().startsWith('bearer')) {
      // Remove 'bearer' prefix case-insensitively and trim
      bearerToken = token.replace(/^bearer/i, '').trim();
    }

    // If double 'bearer' was sent (e.g., "Bearer Bearer <token>")
    if (bearerToken.toLowerCase().startsWith('bearer')) {
      bearerToken = bearerToken.replace(/^bearer/i, '').trim();
    }

    // If token is missing, empty, or string "null"/"undefined"
    if (!bearerToken || bearerToken === '' || bearerToken === 'null' || bearerToken === 'undefined') {
      console.log('Backend: Auth header present but token is effectively empty.');
      return res.status(401).json({ error: 'Invalid token' });
    }

    console.log(`Backend: Verifying Clean Token: "${bearerToken.substring(0, 15)}..."`);
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
