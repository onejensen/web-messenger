# Kood/Messenger 🚀

A robust, full-stack Flutter messenger application with a Node.js backend, built for security, real-time interaction, and a premium user experience.

## 🌟 Key Features

### ✉️ Messaging & Interaction
- **Real-time Chat**: Instant messaging powered by Socket.IO with automatic reconnection and room recovery.
- **Rich Media**: Send and receive text, images, videos, and audio messages.
- **Delivery Status**: Visual indicators for message status:
  - 🕒 `Sending` (Waiting for acknowledgement)
  - ✅ `Sent` (Received by server)
  - ✔️✔️ `Delivered` (Received by peer - grey)
  - 🔵🔵 `Read` (Seen by peer - blue)
- **Typing Indicators**: Real-time feedback when your contacts are typing.
- **Message Management**: Edit and delete messages with ease.
- **Group Chats**: Create and manage group conversations (now available on Web and Mobile).

### 🔍 Advanced Search
- **Global Search**: Find users and send chat invitations by username or email.
- **In-Chat Search**: Search for specific messages within any conversation.
- **Navigation & Highlighting**: Smoothly navigate between search results with automatic scrolling and visual text highlighting.

### 🔐 Security & Privacy (AES-256)
- **End-to-Rest Encryption**: All sensitive data is encrypted before being stored in the database:
  - Message content (Text & File paths)
  - User profile details ("About Me")
  - Chat names (Direct & Group names)
- **Robust JWT Auth**: Secure authentication with persistent sessions and independent device logins.
- **UI Security**: 
  - Password visibility toggles on all input fields.
  - Logout confirmation dialogs to prevent accidental session termination.

### 👤 Profile & UX
- **Customizable Profiles**: Set your username, "About Me" bio, and upload high-quality profile pictures (JPEG/PNG).
- **Default Avatars**: Automatic default profile pictures for new users.
- **English Localization**: The entire UI and system notifications have been fully translated to English.
- **Modern Aesthetics**: Sleek dark mode design with glassmorphism and subtle micro-animations.

## 🚀 Tech Stack

- **Frontend**: Flutter (Mobile & Web), Provider (State Management), Socket.io Client, AudioPlayers, Camera/Video Picker.
- **Backend**: Node.js, Express, Sequelize (ORM), SQLite (Local Storage) / PostgreSQL (Optional), Socket.io, Multer.
- **Database**: SQLite by default for easy setup and testing.

## 🛠️ Getting Started

### Prerequisites
- **Node.js**: Versions 16+ recommended.
- **Flutter SDK**: For building or running from source.
- **Android Device/Emulator**: To run the mobile version.

### 1. Run the Backend
```bash
cd backend
npm install
npm start # Starts server on http://localhost:3000
```
*Note: Make sure to configure your `.env` file with `JWT_SECRET` and `ENCRYPTION_KEY`.*

### 2. Run the Frontend
```bash
cd frontend
flutter pub get
flutter run
```

### 3. Build & Deploy Web
Use the provided script to deploy to GitHub Pages:
```bash
./deploy_web.sh
```

## 📋 Compliance Audit
This project has successfully passed a comprehensive compliance audit, fulfilling requirements for:
- [x] Nuanced Delivery Indicators
- [x] In-chat message search & navigation
- [x] Extended database encryption (Chat names, profiles)
- [x] Robust Socket.IO error recovery
- [x] Full UI translation to English
- [x] Security UX (Password toggles & Logout dialogs)

---
Developed with ❤️ by the team at Kood.
