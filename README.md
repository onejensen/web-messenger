# Kood/Messenger

## Project Overview
Kood/Messenger is a secure, real-time messaging platform designed for both Web and Mobile. It features a robust Node.js backend using Sequelize with SQLite, and a cross-platform frontend built with Flutter. The application prioritizes privacy through end-to-end encryption of sensitive data (messages, profile information, and chat details) before storage.

### Key Features
- **Real-time Messaging**: Instant text, image, and video delivery via Socket.io.
- **Security**: AES-256-CBC encryption for all sensitive user data.
- **Authentication**: Secure JWT-based login, 6-digit email verification, and password reset flow.
- **Profile Management**: Customizable profiles with "About Me" sections and avatar uploads.
- **Collaborative Features**: Individual and group chat invitations with real-time notifications.
- **Advanced UX**: Typing indicators, delivery/read receipts, and message search.

---

## Setup Instructions

### Prerequisites
- **Node.js** (v16+)
- **Flutter SDK**
- **SQLite3**

### Backend Setup
1. Navigate to the `backend/` directory:
   ```bash
   cd backend
   ```
2. Install dependencies:
   ```bash
   npm install
   ```
3. (Optional) Configure environment variables in a `.env` file:
   ```env
   PORT=3000
   JWT_SECRET=your_jwt_secret
   ENCRYPTION_KEY=your_32_byte_key
   ```
4. Start the server:
   ```bash
   npm start
   ```

### Frontend Setup (Web)
1. Navigate to the `frontend/` directory:
   ```bash
   cd frontend
   ```
2. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```
3. Run the application for Web:
   ```bash
   flutter run -d chrome
   ```

---

## Usage Guide

### Getting Started
1. **Registration**: Create a new account using a valid email, username, and password.
2. **Verification**: Enter the 6-digit code sent to your email (displayed in the backend console for local development).
3. **Login**: Use your credentials to access your persistent session.

### Messaging
- **Find Contacts**: Use the search bar to find users by email or username.
- **Invitations**: Send a chat invitation to start a 1-on-1 or group conversation.
- **In-Chat**:
  - Attach images or videos using the '+' button.
  - Long-press or right-click messages to **Edit** or **Delete**.
  - Use the top search icon to filter messages within the current chat.

### Profile
- Access your profile from the sidebar to update your "About Me" and upload a profile picture.

### Deployment Note
The application is designed to be deployment-ready. For web hosting, use `flutter build web` and serve the `build/web` directory using any static hosting provider (e.g., Vercel, Netlify). The backend can be deployed to any Node.js compatible environment (e.g., Heroku, DigitalOcean).

---

## Data Encryption
All message content, user "About Me" sections, and group chat names are encrypted using AES-256-CBC before storage in the SQLite database. Encryption keys are managed securely in `backend/utils/encryption.js`.

## Tech Stack
- **Frontend**: Flutter, Provider, Socket.io Client, Shared Preferences.
- **Backend**: Node.js, Express, Sequelize, SQLite, Socket.io, Multer, Bcrypt.
