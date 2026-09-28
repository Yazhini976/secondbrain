import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:second_brain/core/config/api_config.dart';
import 'package:second_brain/core/network/api_exception.dart';

class ApiClient {
  final http.Client _client;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  Duration get _timeout {
    final isTestEnv = Zone.current[#flutter.test] != null ||
        (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST'));
    return isTestEnv ? const Duration(milliseconds: 100) : const Duration(seconds: 10);
  }

  Future<Map<String, String>> _getHeaders() async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    String? token;
    if (ApiConfig.authTokenProvider != null) {
      token = await ApiConfig.authTokenProvider!();
    }

    // Default fallback for development testing against backend
    token ??= 'test-token-flutter-device-user';
    headers['Authorization'] = 'Bearer $token';

    return headers;
  }

  List<String> get _candidateUrls => [
        ApiConfig.baseUrl,
        ...ApiConfig.candidateUrls.where((u) => u != ApiConfig.baseUrl),
      ];

  Uri _buildUri(String baseUrl, String path, [Map<String, String>? queryParameters]) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final fullUrl = '$baseUrl$cleanPath';
    final uri = Uri.parse(fullUrl);
    if (queryParameters != null && queryParameters.isNotEmpty) {
      return uri.replace(queryParameters: queryParameters);
    }
    return uri;
  }

  Future<dynamic> _executeWithFallback(
    Future<http.Response> Function(String baseUrl, Map<String, String> headers) makeRequest,
  ) async {
    final headers = await _getHeaders();
    final urls = _candidateUrls;

    for (int i = 0; i < urls.length; i++) {
      final base = urls[i];
      try {
        final response = await makeRequest(base, headers).timeout(_timeout);
        ApiConfig.baseUrl = base;
        return _processResponse(response);
      } catch (e) {
        if (e is ApiException) rethrow;
        // If last candidate failed, throw clear exception
        if (i == urls.length - 1) {
          throw ApiException(0, 'Could not connect to server. Check your network connection.');
        }
        // Try next candidate URL
        continue;
      }
    }
    throw ApiException(0, 'Could not connect to server. Check your network connection.');
  }

  Future<dynamic> get(String path, {Map<String, String>? queryParameters}) async {
    return _executeWithFallback((base, headers) {
      final uri = _buildUri(base, path, queryParameters);
      return _client.get(uri, headers: headers);
    });
  }

  Future<dynamic> post(String path, {dynamic body}) async {
    return _executeWithFallback((base, headers) {
      final uri = _buildUri(base, path);
      return _client.post(uri, headers: headers, body: jsonEncode(body));
    });
  }

  Future<dynamic> patch(String path, {dynamic body}) async {
    return _executeWithFallback((base, headers) {
      final uri = _buildUri(base, path);
      return _client.patch(uri, headers: headers, body: jsonEncode(body));
    });
  }

  Future<dynamic> delete(String path) async {
    return _executeWithFallback((base, headers) {
      final uri = _buildUri(base, path);
      return _client.delete(uri, headers: headers);
    });
  }

  dynamic _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }

    String errorMessage = 'Server error occurred.';
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body.containsKey('detail')) {
        errorMessage = body['detail'].toString();
      }
    } catch (_) {}

    if (response.statusCode == 401) {
      throw ApiException(401, 'Your session has expired. Please sign in again.');
    } else if (response.statusCode == 404) {
      throw ApiException(404, errorMessage.isNotEmpty ? errorMessage : 'Resource not found.');
    }

    throw ApiException(response.statusCode, errorMessage);
  }
}
