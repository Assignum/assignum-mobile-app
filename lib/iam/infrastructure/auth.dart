import 'package:firebase_auth/firebase_auth.dart';
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

    // Firebase Auth must be set BEFORE AuthSession fires the stream.
    // WidgetTree calls _checkProfile() which checks currentUser — if Firebase
    // Auth isn't ready yet, currentUser is null and the app forces a sign-out.
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

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

    // Same ordering guarantee as signIn.
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

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
    await FirebaseAuth.instance.signOut().catchError((_) {});
    await AuthSession().clearSession();
  }
}
