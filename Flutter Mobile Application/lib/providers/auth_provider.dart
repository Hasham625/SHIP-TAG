import 'package:flutter/material.dart';
import '../models/user.dart';
import '../repositories/auth_repository.dart';
import '../services/service_locator.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository = getIt<AuthRepository>();

  User? _currentUser;
  bool _isLoading = false;
  bool _isAuthenticated = false;
  bool _rememberMe = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  bool get rememberMe => _rememberMe;
  String? get error => _error;

  // Email/Mobile + Password Login
  Future<bool> login(String emailOrMobile, String password,
      {bool rememberMe = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _authRepository.login(emailOrMobile, password);
      _currentUser = user;
      _isAuthenticated = true;
      _rememberMe = rememberMe;

      if (rememberMe) {
        await _authRepository.saveRememberMe(true);
      }

      return true;
    } catch (e) {
      _error = e.toString();
      _isAuthenticated = false;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Sign Up flow
  Future<bool> signUp(String emailOrMobile, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authRepository.signUp(emailOrMobile, password);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> sendOtpForSignUp(String emailOrMobile) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authRepository.sendOtpForSignUp(emailOrMobile);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifySignUpOtp(String emailOrMobile, String otp) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _authRepository.verifySignUpOtp(emailOrMobile, otp);
      _currentUser = user;
      _isAuthenticated = true;
      return true;
    } catch (e) {
      _error = e.toString();
      _isAuthenticated = false;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Forgot Password flow
  Future<bool> sendOtpForPasswordReset(String emailOrMobile) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authRepository.sendOtpForPasswordReset(emailOrMobile);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyPasswordResetOtp(
      String emailOrMobile, String otp) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authRepository.verifyPasswordResetOtp(emailOrMobile, otp);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> resetPassword(String emailOrMobile, String newPassword) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authRepository.resetPassword(emailOrMobile, newPassword);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Legacy OTP methods
  Future<void> sendOtp(String mobileNumber) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authRepository.sendOtp(mobileNumber);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyOtp(String mobileNumber, String otp) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _authRepository.verifyOtp(mobileNumber, otp);
      _currentUser = user;
      _isAuthenticated = true;
      return true;
    } catch (e) {
      _error = e.toString();
      _isAuthenticated = false;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Check if user can be restored from remember me
  Future<void> checkRememberedUser() async {
    try {
      final rememberMe = await _authRepository.getRememberMe();
      _rememberMe = rememberMe;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  // Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authRepository.logout();
      await _authRepository.saveRememberMe(false);
      _currentUser = null;
      _isAuthenticated = false;
      _rememberMe = false;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

