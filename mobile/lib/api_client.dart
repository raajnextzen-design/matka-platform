import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'models.dart';

const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');

class ApiException implements Exception {
  const ApiException(
    this.message, {
    this.statusCode,
    this.code = 'API_ERROR',
    this.isOffline = false,
  });

  final String message;
  final int? statusCode;
  final String code;
  final bool isOffline;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({String baseUrl = apiBaseUrl, http.Client? client})
      : _baseUrl = baseUrl.trim().replaceFirst(RegExp(r'/$'), ''),
        _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;
  String? _accessToken;
  void Function()? onUnauthorized;

  bool get hasBaseUrl {
    final uri = Uri.tryParse(_baseUrl);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  void setAccessToken(String? token) => _accessToken = token;

  Future<dynamic> _request(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? body,
    bool authenticated = false,
  }) async {
    if (!hasBaseUrl) {
      throw const ApiException(
        'API URL is not configured. Build with --dart-define=API_BASE_URL=<url>.',
        code: 'API_NOT_CONFIGURED',
      );
    }
    final request = http.Request(method, Uri.parse('$_baseUrl$path'));
    request.headers['Accept'] = 'application/json';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    if (authenticated && _accessToken != null) {
      request.headers['Authorization'] = 'Bearer $_accessToken';
    }

    late http.Response response;
    try {
      response = await http.Response.fromStream(
        await _client.send(request).timeout(const Duration(seconds: 20)),
      );
    } on SocketException {
      throw const ApiException(
        'You appear to be offline. Check your connection and try again.',
        code: 'NETWORK_OFFLINE',
        isOffline: true,
      );
    } on TimeoutException {
      throw const ApiException(
        'The connection timed out. Check your network and retry.',
        code: 'NETWORK_TIMEOUT',
        isOffline: true,
      );
    } on http.ClientException {
      throw const ApiException(
        'The API could not be reached. Check your network and server.',
        code: 'NETWORK_ERROR',
        isOffline: true,
      );
    } on FormatException {
      throw const ApiException('The API URL is invalid.', code: 'INVALID_API_URL');
    }

    if (response.statusCode == 401 && authenticated) {
      onUnauthorized?.call();
    }
    if (response.statusCode == 204 || response.body.isEmpty) return null;

    dynamic payload;
    try {
      payload = jsonDecode(response.body);
    } on FormatException {
      throw ApiException(
        'The API returned an unreadable response (${response.statusCode}).',
        statusCode: response.statusCode,
        code: 'INVALID_RESPONSE',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final envelope = payload is Map<String, dynamic> ? payload['error'] : null;
      final message = envelope is Map<String, dynamic>
          ? envelope['message'] as String? ?? 'Request failed (${response.statusCode}).'
          : 'Request failed (${response.statusCode}).';
      final code = envelope is Map<String, dynamic>
          ? envelope['code'] as String? ?? 'HTTP_ERROR'
          : 'HTTP_ERROR';
      throw ApiException(message, statusCode: response.statusCode, code: code);
    }
    return payload;
  }

  Map<String, dynamic> _map(dynamic value) => value as Map<String, dynamic>;

  List<T> _list<T>(dynamic value, T Function(Map<String, dynamic>) parse) =>
      (value as List<dynamic>).map((item) => parse(_map(item))).toList();

  Future<String> login(String email, String password) async {
    final payload = _map(await _request(
      '/api/auth/login',
      method: 'POST',
      body: {'email': email, 'password': password},
    ));
    return payload['access_token'] as String;
  }

  Future<UserProfile> register(String email, String password) async =>
      UserProfile.fromJson(_map(await _request(
        '/api/auth/register',
        method: 'POST',
        body: {'email': email, 'password': password},
      )));

  Future<UserProfile> getProfile() async => UserProfile.fromJson(
        _map(await _request('/api/users/me', authenticated: true)),
      );

  Future<List<Market>> getMarkets() async =>
      _list(await _request('/api/markets'), Market.fromJson);

  Future<MarketDetail> getMarketDetail(int marketId) async {
    final market = Market.fromJson(
      _map(await _request('/api/markets/$marketId')),
    );
    final schedules = _list(
      await _request('/api/markets/$marketId/schedules'),
      MarketSchedule.fromJson,
    );
    return MarketDetail(market: market, schedules: schedules);
  }

  Future<List<PublishedResult>> getResults({
    int? marketId,
    bool history = false,
    int limit = 100,
  }) async {
    final query = <String, String>{'limit': '$limit'};
    if (marketId != null) query['market_id'] = '$marketId';
    if (history) {
      final now = DateTime.now();
      query['before'] =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    }
    final endpoint = history ? '/api/results/history' : '/api/results';
    final uri = Uri(path: endpoint, queryParameters: query);
    return _list(await _request(uri.toString()), PublishedResult.fromJson);
  }

  Future<List<Market>> getFavourites() async =>
      _list(await _request('/api/users/me/favourites', authenticated: true), Market.fromJson);

  Future<void> addFavourite(int marketId) async {
    await _request('/api/users/me/favourites/$marketId', method: 'PUT', authenticated: true);
  }

  Future<void> removeFavourite(int marketId) async {
    await _request('/api/users/me/favourites/$marketId', method: 'DELETE', authenticated: true);
  }

  void close() => _client.close();
}