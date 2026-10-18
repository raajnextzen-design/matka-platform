import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'models.dart';
import 'token_store.dart';

class AuthController extends ChangeNotifier {
  AuthController({required this.api, required this.tokenStore}) {
    api.onUnauthorized = () => unawaited(_expireSession());
  }

  final ApiClient api;
  final TokenStore tokenStore;
  UserProfile? user;
  bool isLoading = true;
  String? sessionMessage;
  bool _disposed = false;

  bool get isAuthenticated => user != null;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  int? _tokenExpiry(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final claims = jsonDecode(payload) as Map<String, dynamic>;
      return claims['exp'] as int?;
    } catch (_) {
      return null;
    }
  }

  Future<void> restoreSession() async {
    isLoading = true;
    _notify();
    try {
      final token = await tokenStore.read();
      final expiry = token == null ? null : _tokenExpiry(token);
      if (token == null || expiry == null || expiry <= DateTime.now().millisecondsSinceEpoch ~/ 1000) {
        await tokenStore.delete();
        api.setAccessToken(null);
        user = null;
      } else {
        api.setAccessToken(token);
        user = await api.getProfile();
      }
    } on ApiException catch (error) {
      api.setAccessToken(null);
      user = null;
      if (error.isOffline) {
        sessionMessage = 'You are offline. Your saved session is kept; reconnect to continue.';
      } else {
        await tokenStore.delete();
        sessionMessage = 'Your session ended. Please sign in again.';
      }
    } catch (_) {
      await tokenStore.delete();
      api.setAccessToken(null);
      user = null;
      sessionMessage = 'Your session ended. Please sign in again.';
    } finally {
      isLoading = false;
      _notify();
    }
  }

  Future<void> signIn(String email, String password) async {
    final token = await api.login(email.trim(), password);
    final expiry = _tokenExpiry(token);
    if (expiry == null || expiry <= DateTime.now().millisecondsSinceEpoch ~/ 1000) {
      throw const ApiException('The API returned an invalid or expired session.', code: 'INVALID_TOKEN');
    }
    api.setAccessToken(token);
    try {
      await tokenStore.write(token);
      user = await api.getProfile();
      sessionMessage = null;
      _notify();
    } catch (_) {
      api.setAccessToken(null);
      await tokenStore.delete();
      rethrow;
    }
  }

  Future<void> register(String email, String password) async {
    await api.register(email.trim(), password);
    await signIn(email, password);
  }

  Future<void> signOut() async {
    api.setAccessToken(null);
    user = null;
    await tokenStore.delete();
    _notify();
  }

  Future<void> _expireSession() async {
    api.setAccessToken(null);
    user = null;
    sessionMessage = 'Your session expired. Please sign in again.';
    await tokenStore.delete();
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    api.onUnauthorized = null;
    api.close();
    super.dispose();
  }
}