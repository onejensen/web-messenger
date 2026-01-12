const User = require('./User');
const { Chat, Message, Invite, ChatParticipants } = require('./Chat'); // Exported together for now

// Associations

// User - Chat (Many-to-Many)
User.belongsToMany(Chat, { through: ChatParticipants, unique: false });
Chat.belongsToMany(User, { through: ChatParticipants, unique: false });

// Chat - Message (One-to-Many)
Chat.hasMany(Message, { onDelete: 'CASCADE' });
Message.belongsTo(Chat);

// User - Message (One-to-Many)
User.hasMany(Message);
Message.belongsTo(User);

// User - Invite (Sent/Received)
User.hasMany(Invite, { as: 'SentInvites', foreignKey: 'senderId' });
User.hasMany(Invite, { as: 'ReceivedInvites', foreignKey: 'receiverId' });
Invite.belongsTo(User, { as: 'Sender', foreignKey: 'senderId' });
Invite.belongsTo(User, { as: 'Receiver', foreignKey: 'receiverId' });

Invite.belongsTo(Chat);
Chat.hasMany(Invite);

module.exports = { User, Chat, Message, Invite, ChatParticipants };
