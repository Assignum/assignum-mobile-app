import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class AuthSession {
  static final AuthSession _instance = AuthSession._internal();
  factory AuthSession() => _instance;
  AuthSession._internal();

  String? _idToken;
  String? _uid;
  String? _email;

  final _controller = StreamController<bool>.broadcast();
  Stream<bool> get authStateChanges => _controller.stream;

  bool get isLoggedIn => _idToken != null;
  String? get idToken => _idToken;
  String? get uid => _uid;
  String? get email => _email;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _idToken = prefs.getString('idToken');
    _uid = prefs.getString('uid');
    _email = prefs.getString('email');
  }

  Future<void> setSession({
    required String idToken,
    required String uid,
    required String email,
  }) async {
    _idToken = idToken;
    _uid = uid;
    _email = email;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('idToken', idToken);
    await prefs.setString('uid', uid);
    await prefs.setString('email', email);
    _controller.add(true);
  }

  Future<void> clearSession() async {
    _idToken = null;
    _uid = null;
    _email = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('idToken');
    await prefs.remove('uid');
    await prefs.remove('email');
    _controller.add(false);
  }
}
