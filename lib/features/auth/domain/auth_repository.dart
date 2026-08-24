abstract class AuthRepository {
  bool get hasSession;
  Future<void> signIn(String email, String password);
  Future<void> signUp({
    required String firstName,
    required String surname,
    required String mobile,
    required String email,
    required String password,
  });

  // Optional authentication methods have safe defaults so existing test
  // doubles and alternate repositories do not break when new auth methods
  // are introduced.
  Future<void> sendEmailOtp(String email) async {
    throw AuthException('Email code sign-in is unavailable.');
  }

  Future<void> verifyEmailOtp(String email, String token) async {
    throw AuthException('Email code sign-in is unavailable.');
  }

  Future<void> signInWithGoogle() async {
    throw AuthException('Google sign-in is unavailable.');
  }

  Future<void> signOut();
  Future<void> resetPassword(String email);
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => 'AuthException: $message';
}
