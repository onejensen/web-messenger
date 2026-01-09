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
      } else {
        // Token exists but user doesn't or is invalid
        await logout();
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
  
  Future<void> logout() async {
    await _authService.logout();
    _isAuthenticated = false;
    _user = null;
    _token = null;
    notifyListeners();
  }
  Future<void> verifyRegistration(String email, String code) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.verifyRegistration(email, code);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> requestPasswordReset(String email) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.requestPasswordReset(email);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resetPassword(String token, String newPassword) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.resetPassword(token, newPassword);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
