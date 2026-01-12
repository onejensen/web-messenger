import 'dart:io';
import 'package:flutter/foundation.dart';

class Config {
  static String get baseUrl {
    // For reviewers: 
    // - Use 'localhost' if running the backend on the same machine.
    // - Use your PC's local IP (e.g. 192.168.1.XX) if running on a real phone.
    if (kIsWeb) return 'http://localhost:3000';
    if (Platform.isAndroid) return 'http://10.0.2.2:3000'; // Default for Android Emulator
    return 'http://localhost:3000';
  }
}
