import 'package:assignum/core/infrastructure/api_client.dart';
import 'package:assignum/core/infrastructure/auth_session.dart';

class Auth {
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final data = await ApiClient.postPublic('/api/auth/login', {
      'email': email,
      'password': password,
    }) as Map<String, dynamic>;

    await AuthSession().setSession(
      idToken: data['idToken'] as String,
      uid: data['uid'] as String,
      email: data['email'] as String,
    );
  }

  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final data = await ApiClient.postPublic('/api/auth/register', {
      'email': email,
      'password': password,
    }) as Map<String, dynamic>;

    await AuthSession().setSession(
      idToken: data['idToken'] as String,
      uid: data['uid'] as String,
      email: data['email'] as String,
    );
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    await ApiClient.postPublic('/api/auth/forgot-password', {'email': email});
  }

  Future<void> signOut() async {
    try {
      await ApiClient.post('/api/auth/logout');
    } catch (_) {}
    await AuthSession().clearSession();
  }
}
