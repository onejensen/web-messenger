# Kood/Messenger

## Project Overview
Kood/Messenger is a secure, real-time web messaging platform. It features a robust Node.js backend using Sequelize with SQLite, and a premium frontend built with Flutter web. The application prioritizes privacy through end-to-end encryption of sensitive data (messages, profile information, and chat details) before storage.

### Key Features
- **Real-time Web Messaging**: Instant text, image, and video delivery via Socket.io.
- **Security**: AES-256-CBC encryption for all sensitive user data.
- **Authentication**: Secure JWT-based login, 6-digit email verification, and password reset flow.
- **Profile Management**: Customizable profiles with "About Me" sections and avatar uploads.
- **Collaborative Features**: Individual and group chat invitations with real-time notifications.
- **Advanced UX**: Typing indicators, delivery/read receipts, and message search.

---

## Setup Instructions (Web Testing)

### Prerequisites
- **Node.js** (v16+)
- **Flutter SDK** (configured for Web)
- **Google Chrome** (Recommended for testing)

### 1. Backend Setup
1. Navigate to the `backend/` directory:
   ```bash
   cd backend
   ```
2. Install dependencies:
   ```bash
   npm install
   ```
3. Configure the `.env` file (see [Configuration](#configuration) below).
4. Start the server (runs on port **4000**):
   ```bash
   npm start
   ```

### 2. Frontend Setup (Web)
1. Open a new terminal and navigate to the `frontend/` directory:
   ```bash
   cd frontend
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Launch the Web app:
   ```bash
   flutter run -d chrome
   ```

---

## Configuration

The application requires a `.env` file in the `backend/` directory with the following variables:

```env
JWT_SECRET=your_jwt_secret
PORT=4000

# Gmail SMTP Configuration (Recommended)
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=465
EMAIL_USER=your_gmail@gmail.com
EMAIL_PASS=your_app_password
EMAIL_FROM="Kood/Messenger <your_gmail@gmail.com>"
```

> [!TIP]
> Use a Gmail "App Password" for `EMAIL_PASS` if you have 2FA enabled.

---

## Web Testing Guide

### Getting Started
1. **Registration**: Create a new account with a real email. A **6-digit verification code** will be sent to your email address.
2. **Verification**: Enter the code in the app to activate your account.
3. **Login**: Use your verified credentials. The session will persist until you logout.
4. **Multi-Session Test**: Open Chrome in Incognito mode to log in with a different account and test real-time interaction.

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
