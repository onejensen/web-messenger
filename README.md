# Kood/Messenger

A full-stack Flutter messenger application with Node.js backend.

## Features
- **Authentication**: JWT-based auth, password strength meter, persistent session.
- **Messaging**: Real-time chat (text, image, video, audio) with delivery status.
- **Encryption**: Sensitive data (messages, profile details) encrypted at rest (AES-256).
- **Profile**: Data persistence, avatar upload.
- **Search & Invites**: Find users and manage connections.
- **UI**: Modern Dark Mode aesthetics.

## Reviewer Guide

### Prerequisites
- **Node.js**: Required to run the backend.
- **Android Device/Emulator**: To run the APK.

### Option 1: Install APK directly (Recommended)
1. Navigate to the `release/` folder.
2. Choose the APK for your device architecture:
   - **Modern Phones (Most common)**: `messenger-arm64.apk`
   - **Older Phones**: `messenger-armv7.apk`
3. Transfer to your Android device and install.
   - **Note**: The app expects the backend to be running on your local network. 
   - Since the APK is built with generic config, it tries `10.0.2.2` (Android Emulator default) or `localhost`.
   - **If running on a physical device**, you might need to ensure your phone and PC are on the same Wifi, but the IP hardcoded in `config.dart` (`10.0.2.2`) is specific to standard Android Emulators. 
   - **Recommendation**: Use a standard Android Emulator (Avd) or adjust `frontend/lib/config/config.dart` to your PC's local IP and rebuild if using a physical device.

### Option 2: Run Backend
1. Open terminal in `backend/` folder.
2. Run `./run.sh` (Mac/Linux) or `npm start`.
3. Server starts on port 3000.

### Option 3: Build/Run from Source
 - **Backend**: `cd backend && npm install && npm start`
 - **Frontend**: `cd frontend && flutter run`
   - **Note**: Ensure you accept Microphone/Camera permissions on the device to use media features.


### Resetting Data (Dev/Test)
If you need to clear the database and start with a fresh environment:
1. Stop the backend server.
2. Run the following command from the project root:
   ```bash
   rm backend/database.sqlite && rm backend/uploads/*
   ```
3. Restart the backend: `cd backend && npm start`.
   *Sequelize will automatically recreate the database schema.*

## Data Encryption
- All message content and user "About Me" sections are encrypted using AES-256-CBC before storage in the SQLite database.
- Keys are managed in `backend/utils/encryption.js`.

## Tech Stack
- **Frontend**: Flutter, Provider, Socket.io Client, AudioPlayers, Record, Path Provider.
- **Backend**: Node.js, Express, Sequelize, SQLite, Socket.io, Multer.
