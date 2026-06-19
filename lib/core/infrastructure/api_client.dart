import 'dart:convert';
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
  static const String baseUrl = 'https://assignum-backend.onrender.com';

  static Map<String, String> _buildHeaders({bool requiresAuth = true}) {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (requiresAuth && AuthSession().idToken != null) {
      headers['Authorization'] = 'Bearer ${AuthSession().idToken}';
    }
    return headers;
  }

  // Endpoints protegidos (requieren token)
  static Future<dynamic> get(String path) async {
    final response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: _buildHeaders(),
    );
    return _handle(response);
  }

  static Future<dynamic> post(String path, [Map<String, dynamic>? body]) async {
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: _buildHeaders(),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handle(response);
  }

  static Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse('$baseUrl$path'),
      headers: _buildHeaders(),
      body: jsonEncode(body),
    );
    return _handle(response);
  }

  static Future<dynamic> delete(String path) async {
    final response = await http.delete(
      Uri.parse('$baseUrl$path'),
      headers: _buildHeaders(),
    );
    return _handle(response);
  }

  // Endpoints públicos (sin token — register, login, forgot-password)
  static Future<dynamic> postPublic(String path, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: _buildHeaders(requiresAuth: false),
      body: jsonEncode(body),
    );
    return _handle(response);
  }

  static dynamic _handle(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body);
    }
    String errorMsg = 'Error ${response.statusCode}';
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['error'] != null) errorMsg = body['error'] as String;
    } catch (_) {}
    throw ApiException(errorMsg, response.statusCode);
  }
}
