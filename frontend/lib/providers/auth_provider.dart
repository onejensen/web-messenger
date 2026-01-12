import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  bool _isAuthenticated = false;
  Map<String, dynamic>? _user;
  String? _token;
  bool _isLoading = false;

  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;

  void updateUser(Map<String, dynamic> userData) {
    _user = userData;
    notifyListeners();
  }

  Future<void> tryAutoLogin() async {
    final token = await _authService.getToken();
    if (token != null) {
      final user = await _authService.getUser();
      if (user != null) {
      _isAuthenticated = true;
      _user = user;
      _token = token;
      notifyListeners();
          }
    }
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _authService.login(email, password);
      _isAuthenticated = true;
      _user = data['user'];
      _token = data['token'];
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(String username, String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.register(username, email, password);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> verifyRegistration(String email, String code) async {
    _isLoading = true;
    notifyListeners();
    try {
      debugPrint('AuthProvider: Verifying $email with code $code');
      final data = await _authService.verifyRegistration(email, code);
      debugPrint('AuthProvider: Verification response received. Token: ${data['token'] != null}');
      if (data['token'] != null) {
        _isAuthenticated = true;
        _user = data['user'];
        _token = data['token'];
        debugPrint('AuthProvider: State updated. isAuthenticated: $_isAuthenticated');
      }
    } catch (e) {
      debugPrint('AuthProvider: Error during verification: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resendVerification(String email) async {
    try {
      await _authService.resendVerification(email);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _isAuthenticated = false;
    _user = null;
    _token = null;
    notifyListeners();
  }
}
