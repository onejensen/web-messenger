import 'dart:io';
import 'package:flutter/foundation.dart';

class Config {
  static String get baseUrl {
    // For reviewers: 
    // - Use 'localhost' if running the backend on the same machine.
    // - Use your PC's local IP (e.g. 192.168.1.XX) if running on a real phone.
    if (kIsWeb) return 'https://web-messenger-api.onrender.com';
    if (Platform.isAndroid) return 'https://web-messenger-api.onrender.com'; // Default for Android Emulator
    return 'https://web-messenger-api.onrender.com';
  }
}
