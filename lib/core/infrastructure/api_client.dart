import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:assignum/core/infrastructure/auth_session.dart';

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);
  @override
  String toString() => message;
}

class ApiClient {
  // Override with --dart-define=API_BASE_URL=http://10.0.2.2:3000 to use a local backend.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://assignum-backend.onrender.com',
  );

  /// Token de Firebase vigente. Los tokens duran 1 hora: `getIdToken` devuelve el guardado
  /// si sigue válido y lo renueva solo si está por vencer (o si [forceRefresh]). Sin esto,
  /// quien deja la app abierta más de una hora empieza a recibir 401 en todo.
  static Future<String?> _token({bool forceRefresh = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return AuthSession().idToken;
    try {
      final token = await user.getIdToken(forceRefresh);
      if (token != null && token != AuthSession().idToken) {
        await AuthSession().updateToken(token);
      }
      return token ?? AuthSession().idToken;
    } catch (_) {
      // Sin conexión con Firebase: se intenta con el último token conocido
      return AuthSession().idToken;
    }
  }

  static Future<Map<String, String>> _buildHeaders({
    bool requiresAuth = true,
    bool forceRefresh = false,
  }) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (requiresAuth) {
      final token = await _token(forceRefresh: forceRefresh);
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Envía la solicitud; si el backend responde 401 (token vencido o revocado), renueva el
  /// token y reintenta una sola vez.
  static Future<dynamic> _send(
    Future<http.Response> Function(Map<String, String> headers) request, {
    bool requiresAuth = true,
  }) async {
    var response = await request(await _buildHeaders(requiresAuth: requiresAuth));
    if (requiresAuth && response.statusCode == 401 && FirebaseAuth.instance.currentUser != null) {
      response = await request(await _buildHeaders(forceRefresh: true));
    }
    return _handle(response);
  }

  // Endpoints protegidos (requieren token)
  static Future<dynamic> get(String path) =>
      _send((h) => http.get(Uri.parse('$baseUrl$path'), headers: h));

  static Future<dynamic> post(String path, [Map<String, dynamic>? body]) => _send((h) => http.post(
        Uri.parse('$baseUrl$path'),
        headers: h,
        body: body != null ? jsonEncode(body) : null,
      ));

  static Future<dynamic> put(String path, Map<String, dynamic> body) =>
      _send((h) => http.put(Uri.parse('$baseUrl$path'), headers: h, body: jsonEncode(body)));

  static Future<dynamic> patch(String path, Map<String, dynamic> body) =>
      _send((h) => http.patch(Uri.parse('$baseUrl$path'), headers: h, body: jsonEncode(body)));

  static Future<dynamic> delete(String path) =>
      _send((h) => http.delete(Uri.parse('$baseUrl$path'), headers: h));

  // Endpoints públicos (sin token — register, login, forgot-password)
  static Future<dynamic> postPublic(String path, Map<String, dynamic> body) => _send(
        (h) => http.post(Uri.parse('$baseUrl$path'), headers: h, body: jsonEncode(body)),
        requiresAuth: false,
      );

  static dynamic _handle(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body);
    }
    if (response.statusCode == 429) {
      throw ApiException(
          'Demasiadas solicitudes. Espera un momento e inténtalo de nuevo.', 429);
    }
    String errorMsg = 'Error ${response.statusCode}';
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['error'] != null) errorMsg = body['error'] as String;
    } catch (_) {}
    throw ApiException(errorMsg, response.statusCode);
  }
}
