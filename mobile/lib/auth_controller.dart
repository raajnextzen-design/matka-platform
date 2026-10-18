import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'models.dart';
import 'token_store.dart';

class AuthController extends ChangeNotifier {
  static const _storageTimeout = Duration(seconds: 5);
  static const _profileRestoreTimeout = Duration(seconds: 8);

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

  Future<void> _deleteStoredToken() async {
    try {
      await tokenStore.delete().timeout(_storageTimeout);
    } catch (_) {
      // Local navigation must not wait indefinitely for secure storage.
    }
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
    sessionMessage = null;
    _notify();
    try {
      final token = await tokenStore.read().timeout(_storageTimeout);
      final expiry = token == null ? null : _tokenExpiry(token);
      if (token == null) {
        api.setAccessToken(null);
        user = null;
      } else if (expiry == null || expiry <= DateTime.now().millisecondsSinceEpoch ~/ 1000) {
        api.setAccessToken(null);
        user = null;
        await _deleteStoredToken();
      } else {
        api.setAccessToken(token);
        user = await api.getProfile().timeout(_profileRestoreTimeout);
      }
    } on TimeoutException {
      api.setAccessToken(null);
      user = null;
      sessionMessage = 'Session check timed out. Check your connection or retry.';
    } on ApiException catch (error) {
      api.setAccessToken(null);
      user = null;
      if (error.isOffline) {
        sessionMessage = 'Could not verify your saved session. Check your connection or retry.';
      } else {
        await _deleteStoredToken();
        sessionMessage = 'Your session ended. Please sign in again.';
      }
    } catch (_) {
      await _deleteStoredToken();
      api.setAccessToken(null);
      user = null;
      sessionMessage = 'Saved session could not be read. Please sign in or retry.';
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
      await tokenStore.write(token).timeout(_storageTimeout);
      user = await api.getProfile();
      sessionMessage = null;
      _notify();
    } catch (_) {
      api.setAccessToken(null);
      await _deleteStoredToken();
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
    sessionMessage = null;
    _notify();
    await _deleteStoredToken();
  }

  Future<void> _expireSession() async {
    api.setAccessToken(null);
    user = null;
    sessionMessage = 'Your session expired. Please sign in again.';
    _notify();
    await _deleteStoredToken();
  }

  @override
  void dispose() {
    _disposed = true;
    api.onUnauthorized = null;
    api.close();
    super.dispose();
  }
}