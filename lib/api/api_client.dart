import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

const String kBaseUrl = 'https://jftsensei-livid.vercel.app';
const String kApiBase = '$kBaseUrl/api/v1';

class ApiException implements Exception {
  final String message, code;
  final int status;
  ApiException(this.message, {this.code = 'error', this.status = 0});
  bool get unauthorized => status == 401;
  @override
  String toString() => message;
}

class ApiClient {
  String? token;
  void Function()? onUnauthorized;
  final http.Client _http = http.Client();

  Map<String, String> get authHeaders => {if (token != null) 'Authorization': 'Bearer $token'};

  /// Absolute URL for an API-provided image path (relative paths need the Bearer header).
  String? absolute(String? url) => url == null ? null : (url.startsWith('http') ? url : '$kBaseUrl$url');
  bool needsAuth(String url) => url.startsWith(kBaseUrl);

  Future<Map<String, dynamic>> request(String method, String path, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$kApiBase$path');
    final headers = {'Content-Type': 'application/json', 'Accept': 'application/json', ...authHeaders};
    try {
      final res = await (method == 'POST'
              ? _http.post(uri, headers: headers, body: jsonEncode(body ?? {}))
              : _http.get(uri, headers: headers))
          .timeout(const Duration(seconds: 30));
      Map<String, dynamic> data = {};
      try {
        final d = jsonDecode(utf8.decode(res.bodyBytes));
        if (d is Map<String, dynamic>) data = d;
      } catch (_) {}
      if (res.statusCode >= 200 && res.statusCode < 300) return data;
      final err = data['error'] as Map<String, dynamic>?;
      final ex = ApiException(err?['message'] ?? 'Something went wrong (${res.statusCode}).',
          code: err?['code'] ?? '${res.statusCode}', status: res.statusCode);
      if (ex.unauthorized && token != null) onUnauthorized?.call();
      throw ex;
    } on TimeoutException {
      throw ApiException('Request timed out. Check your connection.', code: 'timeout');
    } on http.ClientException {
      throw ApiException('Cannot reach the server. Check your connection.', code: 'network');
    }
  }

  Future<Map<String, dynamic>> get(String path) => request('GET', path);
  Future<Map<String, dynamic>> post(String path, [Map<String, dynamic>? body]) => request('POST', path, body: body);
}
