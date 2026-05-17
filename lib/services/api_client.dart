// ─────────────────────────────────────────────────────────────────────────────
//  ApiClient — single source of truth for HTTP calls to the FastAPI backend.
//  ─────────────────────────────────────────────────────────────────────────────
//  - Stores access + refresh tokens in flutter_secure_storage.
//  - Auto-refreshes the access token on 401 once, then retries.
//  - Surfaces a typed ApiException so screens can show user-friendly messages.
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

/// Base URL of the FastAPI backend.
///
/// IMPORTANT: change this for your environment.
///   • Android Emulator → http://10.0.2.2:8000/api/v1
///   • iOS Simulator    → http://127.0.0.1:8000/api/v1
///   • Physical device  → http://<your-PC-LAN-IP>:8000/api/v1
class ApiConfig {
  static String get baseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;

    if (kIsWeb) {
      // On Web, use a relative path if the backend is on the same URL
      return 'http://localhost:8000/api/v1';
    }

    // Default for Android Emulator
    return 'http://10.0.2.2:8000/api/v1';
  }

  static const Duration timeout = Duration(seconds: 20);
}

/// Typed error that carries an HTTP status + a server message.
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final dynamic data;

  const ApiException(this.statusCode, this.message, [this.data]);

  bool get isUnauthorized => statusCode == 401;
  bool get isNetwork => statusCode == 0;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  static const _accessKey = 'jwt_access';
  static const _refreshKey = 'jwt_refresh';
  static const _legacyKey = 'jwt_token'; // older builds used this name

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final http.Client _http = http.Client();

  // Prevents two refresh attempts running in parallel.
  Future<bool>? _ongoingRefresh;

  // ─── Token helpers ─────────────────────────────────────────────────────────
  Future<String?> getAccessToken() async {
    final t = await _storage.read(key: _accessKey);
    if (t != null && t.isNotEmpty) return t;
    // Fallback for users upgrading from the old PHP build.
    return await _storage.read(key: _legacyKey);
  }

  Future<String?> getRefreshToken() => _storage.read(key: _refreshKey);

  Future<void> saveTokens({
    required String access,
    required String refresh,
  }) async {
    await _storage.write(key: _accessKey, value: access);
    await _storage.write(key: _refreshKey, value: refresh);
    // Keep legacy key for any leftover screen still reading it.
    await _storage.write(key: _legacyKey, value: access);
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
    await _storage.delete(key: _legacyKey);
  }

  Future<bool> isLoggedIn() async => (await getAccessToken()) != null;

  // ─── HTTP verbs ────────────────────────────────────────────────────────────
  Future<dynamic> get(String path, {Map<String, dynamic>? query, bool auth = true}) =>
      _send('GET', path, query: query, auth: auth);

  Future<dynamic> post(String path,
          {Object? body, Map<String, dynamic>? query, bool auth = true}) =>
      _send('POST', path, body: body, query: query, auth: auth);

  Future<dynamic> patch(String path, {Object? body, bool auth = true}) =>
      _send('PATCH', path, body: body, auth: auth);

  Future<dynamic> delete(String path, {Object? body, bool auth = true}) =>
      _send('DELETE', path, body: body, auth: auth);

  // ─── Core send + auto-refresh ──────────────────────────────────────────────
  Future<dynamic> _send(
    String method,
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    bool auth = true,
    bool isRetry = false,
  }) async {
    final uri = _buildUri(path, query);
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (auth) {
      final token = await getAccessToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }

    http.Response resp;
    try {
      resp = await _do(method, uri, headers, body).timeout(ApiConfig.timeout);
    } on SocketException {
      throw const ApiException(0, 'Network error. Check your connection.');
    } on TimeoutException {
      throw const ApiException(0, 'Request timed out. Please try again.');
    } catch (e) {
      throw ApiException(0, 'Network error: $e');
    }

    // Auto-refresh on 401 (once)
    if (resp.statusCode == 401 && auth && !isRetry) {
      final refreshed = await _refreshIfPossible();
      if (refreshed) {
        return _send(method, path,
            body: body, query: query, auth: auth, isRetry: true);
      }
      // Couldn't refresh — clear tokens, surface unauthorized.
      await clearTokens();
    }

    return _parse(resp);
  }

  Future<http.Response> _do(
    String method,
    Uri uri,
    Map<String, String> headers,
    Object? body,
  ) {
    final encoded = body == null ? null : jsonEncode(body);
    switch (method) {
      case 'GET':
        return _http.get(uri, headers: headers);
      case 'POST':
        return _http.post(uri, headers: headers, body: encoded);
      case 'PATCH':
        return _http.patch(uri, headers: headers, body: encoded);
      case 'DELETE':
        return _http.delete(uri, headers: headers, body: encoded);
      default:
        throw UnsupportedError('HTTP method $method not supported');
    }
  }

  Uri _buildUri(String path, Map<String, dynamic>? query) {
    final fullPath = '${ApiConfig.baseUrl}$path';
    final uri = Uri.parse(fullPath);
    if (query == null || query.isEmpty) return uri;
    final stringified = <String, String>{};
    query.forEach((k, v) {
      if (v != null) stringified[k] = v.toString();
    });
    return uri.replace(queryParameters: {
      ...uri.queryParameters,
      ...stringified,
    });
  }

  dynamic _parse(http.Response resp) {
    final code = resp.statusCode;
    dynamic body;
    if (resp.body.isNotEmpty) {
      try {
        body = jsonDecode(utf8.decode(resp.bodyBytes));
      } catch (_) {
        body = resp.body;
      }
    }
    if (code >= 200 && code < 300) return body;

    String message = 'Request failed';
    if (body is Map) {
      // FastAPI uses "detail" for HTTPException; our handlers use "message".
      message = (body['message'] ??
              body['detail'] ??
              body['error'] ??
              message)
          .toString();
      // detail can also be a list of {loc, msg} from validation
      if (body['detail'] is List && (body['detail'] as List).isNotEmpty) {
        final first = (body['detail'] as List).first;
        if (first is Map && first['msg'] != null) {
          message = first['msg'].toString();
        }
      }
    }
    throw ApiException(code, message, body);
  }

  // ─── Refresh logic ─────────────────────────────────────────────────────────
  Future<bool> _refreshIfPossible() {
    return _ongoingRefresh ??= _doRefresh().whenComplete(() {
      _ongoingRefresh = null;
    });
  }

  Future<bool> _doRefresh() async {
    final refresh = await getRefreshToken();
    if (refresh == null || refresh.isEmpty) return false;

    try {
      final resp = await _http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/auth/refresh'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refresh_token': refresh}),
          )
          .timeout(ApiConfig.timeout);
      if (resp.statusCode != 200) return false;

      final data = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
      await saveTokens(
        access: data['access_token'] as String,
        refresh: data['refresh_token'] as String,
      );
      return true;
    } catch (e) {
      if (kDebugMode) print('Token refresh failed: $e');
      return false;
    }
  }
}
