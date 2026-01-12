require('dotenv').config();
const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
const path = require('path');
const jwt = require('jsonwebtoken');
const sequelize = require('./config/database');
const fs = require('fs');

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: "*", 
    methods: ["GET", "POST"],
    credentials: true
  },
  transports: ['websocket', 'polling']
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
  
  // Auto-identify via token in headers OR handshake.auth (better for Web)
  const authHeader = socket.handshake.headers['authorization'];
  const authToken = socket.handshake.auth ? socket.handshake.auth.token : null;
  
  const token = (authHeader && authHeader.startsWith('Bearer ')) 
    ? authHeader.split(' ')[1] 
    : authToken;

  if (token) {
      try {
          const decoded = jwt.verify(token, process.env.JWT_SECRET || 'secret');
          const userId = decoded.id;
          socket.userId = userId; 
          socket.join(`user_${userId}`);
          console.log(`Socket ${socket.id} auto-joined room: user_${userId}`);
      } catch (e) {
          console.log('Socket connection auth failed:', e.message);
      }
  } else {
      console.log(`Socket ${socket.id} connected without token (waiting for identify)`);
  }

  socket.on('join_chat', (chatId) => {
    const room = String(chatId);
    socket.join(room);
    console.log(`Socket ${socket.id} joined ChatRoom: ${room}`);
    console.log(`Socket ${socket.id} is now in rooms:`, Array.from(socket.rooms));
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

  socket.on('disconnect', (reason) => {
    console.log(`User disconnected: ${socket.id}. Reason: ${reason}`);
  });
});

// Helper to log all emits if needed (optional, just for debugging)
// io.on('new_invite', ...) // This is for receiving, but we want to log sending.
// Instead, we'll log in the routes where io.to().emit is called.

// Database Sync
const { User, Chat, Message, Invite } = require('./models');

const PORT = process.env.PORT || 3000;

async function startServer() {
  try {
    await sequelize.authenticate();
    
    if (sequelize.getDialect() === 'sqlite') {
        // Check for missing columns in Chats table (SQLite specific check)
        const [results] = await sequelize.query("PRAGMA table_info(Chats)");
        const columns = results.map(c => c.name);
        
        if (results.length > 0) {
            if (!columns.includes('deletedBy')) {
                console.log('Adding missing column deletedBy to Chats table');
                await sequelize.query("ALTER TABLE Chats ADD COLUMN deletedBy TEXT DEFAULT '[]'");
            }
            if (!columns.includes('archivedBy')) {
                console.log('Adding missing column archivedBy to Chats table');
                await sequelize.query("ALTER TABLE Chats ADD COLUMN archivedBy TEXT DEFAULT '[]'");
            }
        }

        // Also check Invites table for groupName (added for group chats)
        const [inviteResults] = await sequelize.query("PRAGMA table_info(Invites)");
        const inviteColumns = inviteResults.map(c => c.name);
        if (inviteResults.length > 0 && !inviteColumns.includes('groupName')) {
            console.log('Adding missing column groupName to Invites table');
            await sequelize.query("ALTER TABLE Invites ADD COLUMN groupName TEXT");
        }
    }

    await sequelize.sync(); 
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
