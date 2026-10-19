import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode, kReleaseMode;
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';

/// One place that talks HTTP to the Node.js API.
///
/// - turns every failure into an [ApiException] with a message safe to show
/// - adds the access token when `auth: true`
/// - on an expired access token, refreshes once and retries the request
class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  final http.Client _http = http.Client();
  Future<bool>? _refreshInFlight;

  /// Called when the refresh token is rejected, so the app can sign out.
  void Function()? onSessionExpired;

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool auth = false,
  }) {
    return _send('POST', path, body: body, auth: auth);
  }

  Future<Map<String, dynamic>> get(
    String path, {
    bool auth = false,
    String? baseUrl,
    Map<String, String>? query,
  }) {
    return _send('GET', path, auth: auth, baseUrl: baseUrl, query: query);
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool auth = false,
    bool retried = false,
    String? baseUrl,
    Map<String, String>? query,
    String? tokenUsed, // Tracks which token was used for this specific attempt
  }) async {
        final base = baseUrl ?? ApiConfig.baseUrl;
    var uri = Uri.parse(base + path);
    if (query != null && query.isNotEmpty) {
      uri = uri.replace(queryParameters: query);
    }

    // Passwords and tokens must never travel over plain HTTP in a real build.
    if (kReleaseMode && uri.scheme != 'https') {
      throw const ApiException(
        code: 'INSECURE_CONNECTION',
        message: 'This build must connect to the server over HTTPS. '
            'Set API_BASE_URL to an https:// address.',
      );
    }
    
    final headers = <String, String>{
      'Accept': 'application/json',
    };

    // Only attach Content-Type if the request actually sends a body payload
    if (method != 'GET' && body != null) {
      headers['Content-Type'] = 'application/json';
    }

    String? currentToken;
    if (auth) {
      currentToken = TokenStorage.instance.accessToken;
      if (currentToken != null) {
        headers['Authorization'] = 'Bearer \$currentToken';
      }
    }

    final http.Response response;
    try {
      final request = method == 'GET'
          ? _http.get(uri, headers: headers)
          : _http.post(uri, headers: headers, body: jsonEncode(body ?? {}));
      response = await request.timeout(ApiConfig.timeout);
    } on TimeoutException {
      throw const ApiException(
        code: 'NETWORK_ERROR',
        message: 'The server took too long to respond. Please try again.',
      );
        } catch (e) {
      if (kDebugMode) {
        debugPrint('ApiClient: $method $uri failed: $e');
      }
      throw const ApiException(
        code: 'NETWORK_ERROR',
        message: "Can't reach the server. Check your connection and try again.",
      );
    }

    Map<String, dynamic> data = {};
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) {
        data = decoded;
      }
    } catch (_) {
      // Not JSON (for example an HTML error page from a proxy).
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    final error = data['error'] is Map
        ? Map<String, dynamic>.from(data['error'] as Map)
        : <String, dynamic>{};
    final code = error['code'] as String? ?? 'SERVER_ERROR';

    // Access token expired: refresh once, then repeat the same request.
    if (auth && response.statusCode == 401 && code == 'UNAUTHORIZED') {
      // If we already retried with the freshest token and still got a 401, give up.
      final latestToken = TokenStorage.instance.accessToken;
      if (retried && currentToken == latestToken) {
        throw ApiException(
          code: code,
          message: error['message'] as String? ?? 'Session expired.',
          statusCode: response.statusCode,
          details: error,
        );
      }

      // If a concurrent request already updated the token while this was running,
      // skip refreshing and jump straight to the retry attempt.
      bool refreshed = true;
      if (currentToken == latestToken) {
        refreshed = await _refreshTokens();
      }

      if (refreshed) {
        return _send(
          method,
          path,
          body: body,
          auth: auth,
          retried: true,
          baseUrl: baseUrl, 
          query: query,    
          tokenUsed: TokenStorage.instance.accessToken,
        );
      }
    }

    throw ApiException(
      code: code,
      message: error['message'] as String? ??
          'Something went wrong. Please try again.',
      statusCode: response.statusCode,
      details: error,
    );
  }

  /// Only one refresh runs at a time, even if several requests fail together.
  Future<bool> _refreshTokens() {
    return _refreshInFlight ??=
        _doRefresh().whenComplete(() => _refreshInFlight = null);
  }

  Future<bool> _doRefresh() async {
    final refreshToken = TokenStorage.instance.refreshToken;
    if (refreshToken == null) {
      return false;
    }

    try {
      final data = await _send(
        'POST',
        '/api/auth/refresh',
        body: {'refreshToken': refreshToken},
      );
      await TokenStorage.instance.save(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
      );
      return true;
    } on ApiException catch (e) {
      // Offline is not a reason to sign the user out; a rejected token is.
      if (e.code != 'NETWORK_ERROR') {
        await TokenStorage.instance.clear();
        onSessionExpired?.call();
      }
      return false;
    }
  }
}
