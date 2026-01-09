const jwt = require('jsonwebtoken');
const { User } = require('../models');

const verifyToken = async (req, res, next) => {
  const token = req.header('Authorization'); // "Bearer <token>"
  if (!token) return res.status(401).json({ error: 'Access denied' });

  try {
    // Basic "Bearer <token>" split
    const bearer = token.split(' ');
    const bearerToken = bearer[1] || token; // Handle if just token is sent or Bearer

    const verified = jwt.verify(bearerToken, process.env.JWT_SECRET || 'secret_key_123'); // Use env in prod
    
    // Check if user still exists (e.g. after DB reset)
    const user = await User.findByPk(verified.id);
    if (!user) return res.status(401).json({ error: 'User not found' });

    req.user = verified;
    next();
  } catch (error) {
    res.status(401).json({ error: 'Invalid token' });
  }
};

module.exports = verifyToken;
