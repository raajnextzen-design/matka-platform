import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';
import 'app_theme.dart';
import 'auth_controller.dart';
import 'screens.dart';
import 'token_store.dart';

class MatkaApp extends StatefulWidget {
  const MatkaApp({
    super.key,
    this.apiClient,
    this.tokenStore,
    this.initialOnboardingComplete,
  });

  final ApiClient? apiClient;
  final TokenStore? tokenStore;
  final bool? initialOnboardingComplete;

  @override
  State<MatkaApp> createState() => _MatkaAppState();
}

class _MatkaAppState extends State<MatkaApp> {
  late final ApiClient _api;
  late final AuthController _auth;
  bool _booting = true;
  bool _onboardingComplete = false;

  @override
  void initState() {
    super.initState();
    _api = widget.apiClient ?? ApiClient();
    _auth = AuthController(
      api: _api,
      tokenStore: widget.tokenStore ?? const SecureTokenStore(),
    );
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      _onboardingComplete = widget.initialOnboardingComplete ??
          preferences.getBool('onboarding_complete') ??
          false;
      await _auth.restoreSession();
    } catch (_) {
      _onboardingComplete = widget.initialOnboardingComplete ?? false;
    }
    if (mounted) setState(() => _booting = false);
  }

  Future<void> _finishOnboarding() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('onboarding_complete', true);
    if (mounted) setState(() => _onboardingComplete = true);
  }

  @override
  void dispose() {
    _auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Matka Platform',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: AnimatedBuilder(
          animation: _auth,
          builder: (context, _) {
            if (_booting || _auth.isLoading) return const SplashScreen();
            if (!_onboardingComplete) return OnboardingScreen(onComplete: _finishOnboarding);
            if (_auth.isAuthenticated) return MainShell(auth: _auth, api: _api);
            return AuthenticationScreen(auth: _auth, sessionMessage: _auth.sessionMessage);
          },
        ),
      );
}