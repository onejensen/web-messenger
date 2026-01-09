const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const User = sequelize.define('User', {
  username: { type: DataTypes.STRING, unique: true, allowNull: false },
  email: { type: DataTypes.STRING, unique: true, allowNull: false, validate: { isEmail: true } },
  password: { type: DataTypes.STRING, allowNull: false },
  profilePic: { type: DataTypes.STRING, defaultValue: '/uploads/default-avatar.png' },
  aboutMe: { type: DataTypes.TEXT },
  isVerified: { type: DataTypes.BOOLEAN, defaultValue: false },
  verificationToken: { type: DataTypes.STRING },
  resetToken: { type: DataTypes.STRING },
});

const Chat = sequelize.define('Chat', {
  name: { type: DataTypes.STRING },
  isGroup: { type: DataTypes.BOOLEAN, defaultValue: false },
  lastMessageId: { type: DataTypes.INTEGER },
});

const Message = sequelize.define('Message', {
  content: { type: DataTypes.TEXT, allowNull: false },
  type: { type: DataTypes.ENUM('text', 'image', 'video'), defaultValue: 'text' },
  status: { type: DataTypes.ENUM('sent', 'delivered', 'read'), defaultValue: 'sent' },
});

const Participant = sequelize.define('Participant', {
  isAdmin: { type: DataTypes.BOOLEAN, defaultValue: false },
});

const Invite = sequelize.define('Invite', {
  status: { type: DataTypes.ENUM('pending', 'accepted', 'declined'), defaultValue: 'pending' },
  isGroup: { type: DataTypes.BOOLEAN, defaultValue: false },
});

// Associations
User.hasMany(Message, { foreignKey: 'senderId' });
Message.belongsTo(User, { as: 'sender', foreignKey: 'senderId' });

Chat.hasMany(Message, { foreignKey: 'chatId' });
Message.belongsTo(Chat, { foreignKey: 'chatId' });

User.belongsToMany(Chat, { through: Participant, foreignKey: 'userId' });
Chat.belongsToMany(User, { through: Participant, foreignKey: 'chatId' });

Invite.belongsTo(User, { as: 'sender', foreignKey: 'senderId' });
Invite.belongsTo(User, { as: 'receiver', foreignKey: 'receiverId' });
Invite.belongsTo(Chat, { foreignKey: 'chatId' });

module.exports = { User, Chat, Message, Participant, Invite };
