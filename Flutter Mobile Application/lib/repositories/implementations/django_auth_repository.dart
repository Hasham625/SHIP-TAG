import '../auth_repository.dart';
import '../../models/user.dart';

class DjangoAuthRepository implements AuthRepository {
  @override
  Future<User> login(String emailOrMobile, String password) async {
    throw UnimplementedError('Django backend not yet implemented');
  }

  @override
  Future<void> signUp(String emailOrMobile, String password) async {
    throw UnimplementedError('Django backend not yet implemented');
  }

  @override
  Future<void> sendOtpForSignUp(String emailOrMobile) async {
    throw UnimplementedError('Django backend not yet implemented');
  }

  @override
  Future<User> verifySignUpOtp(String emailOrMobile, String otp) async {
    throw UnimplementedError('Django backend not yet implemented');
  }

  @override
  Future<void> sendOtpForPasswordReset(String emailOrMobile) async {
    throw UnimplementedError('Django backend not yet implemented');
  }

  @override
  Future<void> verifyPasswordResetOtp(String emailOrMobile, String otp) async {
    throw UnimplementedError('Django backend not yet implemented');
  }

  @override
  Future<void> resetPassword(String emailOrMobile, String newPassword) async {
    throw UnimplementedError('Django backend not yet implemented');
  }

  @override
  Future<void> sendOtp(String mobileNumber) async {
    throw UnimplementedError('Django backend not yet implemented');
  }

  @override
  Future<User> verifyOtp(String mobileNumber, String otp) async {
    throw UnimplementedError('Django backend not yet implemented');
  }

  @override
  Future<User?> getCurrentUser() async {
    throw UnimplementedError('Django backend not yet implemented');
  }

  @override
  Future<void> logout() async {
    throw UnimplementedError('Django backend not yet implemented');
  }

  @override
  Future<void> saveRememberMe(bool rememberMe) async {
    throw UnimplementedError('Django backend not yet implemented');
  }

  @override
  Future<bool> getRememberMe() async {
    throw UnimplementedError('Django backend not yet implemented');
  }
}
