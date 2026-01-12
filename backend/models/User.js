const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');
const { encrypt, decrypt } = require('../utils/encryption');

const User = sequelize.define('User', {
  username: {
    type: DataTypes.STRING,
    allowNull: false,
    unique: true
  },
  email: {
    type: DataTypes.STRING,
    allowNull: false,
    unique: true,
    validate: {
      isEmail: true
    }
  },
  password: {
    type: DataTypes.STRING,
    allowNull: false
  },
  isVerified: {
    type: DataTypes.BOOLEAN,
    defaultValue: false
  },
  verificationCode: {
    type: DataTypes.STRING,
    allowNull: true
  },
  resetToken: {
    type: DataTypes.STRING,
    allowNull: true
  },
  resetTokenExpires: {
    type: DataTypes.DATE,
    allowNull: true
  },
  profilePicture: {
    type: DataTypes.TEXT, // Encrypted URL/Path
    get() {
      const rawValue = this.getDataValue('profilePicture');
      return rawValue ? decrypt(rawValue) : null;
    },
    set(value) {
      if(value) this.setDataValue('profilePicture', encrypt(value));
    }
  },
  aboutMe: {
    type: DataTypes.TEXT, // Encrypted
    get() {
      const rawValue = this.getDataValue('aboutMe');
      return rawValue ? decrypt(rawValue) : '';
    },
    set(value) {
      if(value) this.setDataValue('aboutMe', encrypt(value));
    }
  }
});

module.exports = User;
