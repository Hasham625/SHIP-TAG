import '../models/user.dart';

abstract class AuthRepository {
  // Email/Mobile + Password Login
  Future<User> login(String emailOrMobile, String password);

  // Sign Up flow
  Future<void> signUp(String emailOrMobile, String password);
  Future<void> sendOtpForSignUp(String emailOrMobile);
  Future<User> verifySignUpOtp(String emailOrMobile, String otp);

  // Forgot Password flow
  Future<void> sendOtpForPasswordReset(String emailOrMobile);
  Future<void> verifyPasswordResetOtp(String emailOrMobile, String otp);
  Future<void> resetPassword(String emailOrMobile, String newPassword);

  // Legacy OTP methods
  Future<void> sendOtp(String mobileNumber);
  Future<User> verifyOtp(String mobileNumber, String otp);

  // Session management
  Future<User?> getCurrentUser();
  Future<void> logout();
  Future<void> saveRememberMe(bool rememberMe);
  Future<bool> getRememberMe();
}
