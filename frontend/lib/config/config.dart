import 'dart:io';
import 'package:flutter/foundation.dart';

class Config {
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:3000';
    // 192.168.1.60 is your machine's local IP
    // This allows physical devices on the same WiFi to connect without ADB reverse
    return 'http://192.168.1.60:3000';
  }
}
