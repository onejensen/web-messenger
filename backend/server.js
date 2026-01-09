require('dotenv').config();
const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
const path = require('path');
const sequelize = require('./config/database');
const fs = require('fs');

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

// Sidebar: Create uploads directory
const uploadDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadDir)) {
    fs.mkdirSync(uploadDir);
}

// Middleware
app.use(cors());
app.use(express.json());
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Routes Placeholders
app.get('/', (req, res) => {
  res.send('Messenger API Running');
});

// Socket.io
io.on('connection', (socket) => {
  console.log('User connected:', socket.id);

  socket.on('join_chat', (chatId) => {
    const room = String(chatId);
    socket.join(room);
    console.log(`User ${socket.id} joined chat ${room}`);
  });
  
  // New: Identify user for personal notifications
  socket.on('identify', (userId) => {
      const room = `user_${userId}`;
      socket.join(room);
      console.log(`User ${socket.id} (DB ID: ${userId}) joined room: ${room}`);
      console.log('Rooms for this socket:', Array.from(socket.rooms));
  });
  
  socket.on('typing', ({ chatId, username }) => {
     socket.to(String(chatId)).emit('typing', { username, chatId });
  });
  
  socket.on('stop_typing', ({ chatId, username }) => {
     socket.to(String(chatId)).emit('stop_typing', { username, chatId });
  });

  socket.on('disconnect', () => {
    console.log('User disconnected:', socket.id);
  });
});

// Database Sync
const { User, Chat, Message, Participant, Invite } = require('./models');

const PORT = process.env.PORT || 3000;

async function startServer() {
  try {
    await sequelize.sync({ force: false }); // Set force: true to reset DB
    console.log('Database synced');
    server.listen(PORT, () => {
      console.log(`Server running on port ${PORT}`);
    });
  } catch (error) {
    console.error('Unable to connect to the database:', error);
  }
}

// Make io accessible in routes
app.set('io', io);

// Routes
app.use('/api/auth', require('./routes/auth'));
app.use('/api/users', require('./routes/users'));
app.use('/api/chats', require('./routes/chats'));

startServer();
