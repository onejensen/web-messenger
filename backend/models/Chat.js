const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');
const { encrypt, decrypt } = require('../utils/encryption');

const Chat = sequelize.define('Chat', {
  isGroup: {
    type: DataTypes.BOOLEAN,
    defaultValue: false
  },
  name: {
    type: DataTypes.STRING,
    allowNull: true
  },
  lastMessageAt: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW
  },
  archivedBy: { // Comma separated IDs or JSON string of who archived it
     type: DataTypes.TEXT, 
     defaultValue: '[]',
     get() {
        return JSON.parse(this.getDataValue('archivedBy') || '[]');
     },
     set(val) {
        this.setDataValue('archivedBy', JSON.stringify(val));
     }
  },
  deletedBy: { // Specifically for "Delete for me"
     type: DataTypes.TEXT, 
     defaultValue: '[]',
     get() {
        return JSON.parse(this.getDataValue('deletedBy') || '[]');
     },
     set(val) {
        this.setDataValue('deletedBy', JSON.stringify(val));
     }
  }
});

const Message = sequelize.define('Message', {
  type: {
    type: DataTypes.ENUM('text', 'image', 'video', 'audio'),
    defaultValue: 'text'
  },
  content: {
    type: DataTypes.TEXT,
    allowNull: false,
    get() {
      const rawValue = this.getDataValue('content');
      return rawValue ? decrypt(rawValue) : '';
    },
    set(value) {
      if(value) this.setDataValue('content', encrypt(value));
    }
  },
  status: { // sent, delivered, read
    type: DataTypes.ENUM('sent', 'delivered', 'read'),
    defaultValue: 'sent'
  }
});

const Invite = sequelize.define('Invite', {
  status: {
    type: DataTypes.STRING,
    defaultValue: 'pending'
  },
  groupName: {
    type: DataTypes.STRING,
    allowNull: true
  }
});

const ChatParticipants = sequelize.define('ChatParticipants', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  }
}, { timestamps: true });

module.exports = { Chat, Message, Invite, ChatParticipants };
