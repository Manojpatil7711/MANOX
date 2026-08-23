abstract class AuthRepository {
  Future<void> signIn(String email, String password);
  Future<void> signUp({
    required String firstName,
    required String surname,
    required String mobile,
    required String email,
    required String password,
  });
  Future<void> signOut();
  Future<void> resetPassword(String email);
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => 'AuthException: $message';
}
