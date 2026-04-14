import 'package:shared_preferences/shared_preferences.dart';
import '../auth_repository.dart';
import '../../models/user.dart';

class MockAuthRepository implements AuthRepository {
  static const String _testEmail = 'test@example.com';
  static const String _testMobile = '03001234567';
  static const String _testPassword = 'password';
  static const String _testOtp = '0000';

  @override
  Future<User> login(String emailOrMobile, String password) async {
    if ((emailOrMobile == _testEmail || emailOrMobile == _testMobile) &&
        password == _testPassword) {
      return User(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        mobileNumber: _testMobile,
        email: _testEmail,
        name: 'Test User',
        profileImage: null,
      );
    }

    throw Exception('Invalid email/mobile or password');
  }

  @override
  Future<void> signUp(String emailOrMobile, String password) async {
    if (password.isEmpty) {
      throw Exception('Password cannot be empty');
    }
  }

  @override
  Future<void> sendOtpForSignUp(String emailOrMobile) async {
  }

  @override
  Future<User> verifySignUpOtp(String emailOrMobile, String otp) async {
    if (otp == _testOtp) {
      return User(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        mobileNumber: emailOrMobile,
        email: emailOrMobile,
        name: 'New User',
        profileImage: null,
      );
    }

    throw Exception('Invalid OTP');
  }

  @override
  Future<void> sendOtpForPasswordReset(String emailOrMobile) async {
  }

  @override
  Future<void> verifyPasswordResetOtp(String emailOrMobile, String otp) async {
    if (otp != _testOtp) {
      throw Exception('Invalid OTP');
    }
  }

  @override
  Future<void> resetPassword(String emailOrMobile, String newPassword) async {
    if (newPassword.isEmpty) {
      throw Exception('Password cannot be empty');
    }
  }

  @override
  Future<void> sendOtp(String mobileNumber) async {

  }

  @override
  Future<User> verifyOtp(String mobileNumber, String otp) async {
    if (otp.length != 4) {
      throw Exception('Invalid OTP format');
    }

    return User(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      mobileNumber: mobileNumber,
      email: 'user@example.com',
      name: 'Test User',
      profileImage: null,
    );
  }

  @override
  Future<User?> getCurrentUser() async {
    // This would typically fetch from local storage
    return null;
  }

  @override
  Future<void> logout() async {
    // Logged out
  }

  @override
  Future<void> saveRememberMe(bool rememberMe) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remember_me', rememberMe);
  }

  @override
  Future<bool> getRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('remember_me') ?? false;
  }
}

