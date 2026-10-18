import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:matka_platform_mobile/api_client.dart';
import 'package:matka_platform_mobile/app.dart';
import 'package:matka_platform_mobile/auth_controller.dart';
import 'package:matka_platform_mobile/models.dart';
import 'package:matka_platform_mobile/screens.dart';
import 'package:matka_platform_mobile/token_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MemoryTokenStore implements TokenStore {
  MemoryTokenStore([this.token]);

  String? token;

  @override
  Future<String?> read() async => token;

  @override
  Future<void> write(String value) async => token = value;

  @override
  Future<void> delete() async => token = null;
}

class StallingTokenStore implements TokenStore {
  final _readCompleter = Completer<String?>();

  @override
  Future<String?> read() => _readCompleter.future;

  @override
  Future<void> write(String token) async {}

  @override
  Future<void> delete() async {}
}

String testToken() {
  final encoded = base64Url.encode(utf8.encode(jsonEncode({
    'sub': '8',
    'exp': DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
  })));
  return 'header.${encoded.replaceAll('=', '')}.signature';
}

Map<String, dynamic> marketJson({int id = 4, String name = 'Harbor Market'}) => {
      'id': id,
      'name': name,
      'slug': 'harbor-market',
      'description': 'Daily published schedule',
      'is_active': true,
      'created_at': '2026-09-01T08:00:00Z',
    };

Map<String, dynamic> userJson() => {
      'id': 8,
      'email': 'member@example.com',
      'role': 'user',
      'created_at': '2026-09-01T08:00:00Z',
    };

Map<String, dynamic> resultJson({int id = 2, int marketId = 4}) => {
      'id': id,
      'market_id': marketId,
      'result_date': '2026-10-17',
      'value': '123-45-678',
      'published_at': '2026-10-17T18:30:00Z',
    };

Map<String, dynamic> scheduleJson() => {
      'id': 3,
      'market_id': 4,
      'weekday': 1,
      'opens_at': '09:00:00',
      'closes_at': '17:00:00',
      'is_active': true,
    };

http.Response jsonResponse(Object body, {int status = 200}) => http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json'},
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('splash shows the platform identity while bootstrapping', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));
    expect(find.text('MATKA  /  PLATFORM'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('startup leaves splash and offers retry when secure storage stalls', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final api = ApiClient(baseUrl: 'https://mobile.test');
    await tester.pumpWidget(MatkaApp(
      apiClient: api,
      tokenStore: StallingTokenStore(),
      initialOnboardingComplete: true,
    ));
    await tester.pump();
    await tester.pump(const Duration(seconds: 6));
    await tester.pump();

    expect(find.text('Welcome back.'), findsOneWidget);
    expect(find.text('Session check timed out. Check your connection or retry.'), findsOneWidget);
    expect(find.text('Retry saved session'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('startup leaves splash when profile API verification stalls', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final pendingResponse = Completer<http.Response>();
    final api = ApiClient(
      baseUrl: 'https://mobile.test',
      client: MockClient((_) => pendingResponse.future),
    );
    await tester.pumpWidget(MatkaApp(
      apiClient: api,
      tokenStore: MemoryTokenStore(testToken()),
      initialOnboardingComplete: true,
    ));
    await tester.pump();
    await tester.pump(const Duration(seconds: 9));
    await tester.pump();

    expect(find.text('Welcome back.'), findsOneWidget);
    expect(find.text('Session check timed out. Check your connection or retry.'), findsOneWidget);
    expect(find.text('Retry saved session'), findsOneWidget);

    pendingResponse.complete(jsonResponse(userJson()));
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('onboarding steps lead into the informational app', (tester) async {
    var completed = false;
    await tester.pumpWidget(MaterialApp(home: OnboardingScreen(onComplete: () => completed = true)));
    expect(find.text('YOUR MARKETS'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('WEEKLY SCHEDULES'), findsOneWidget);
    await tester.tap(find.text('Skip'));
    expect(completed, isTrue);
  });

  testWidgets('login calls the actual auth and profile endpoints', (tester) async {
    final token = testToken();
    final requests = <String>[];
    final api = ApiClient(baseUrl: 'https://mobile.test', client: MockClient((request) async {
      requests.add('${request.method} ${request.url.path}');
      if (request.url.path == '/api/auth/login') return jsonResponse({'access_token': token, 'token_type': 'bearer'});
      if (request.url.path == '/api/users/me') return jsonResponse(userJson());
      return jsonResponse({'error': {'code': 'NOT_FOUND', 'message': 'Not found'}}, status: 404);
    }));
    final store = MemoryTokenStore();
    final auth = AuthController(api: api, tokenStore: store);

    await tester.pumpWidget(MaterialApp(home: AuthenticationScreen(auth: auth)));
    await tester.enterText(find.byType(TextFormField).at(0), 'member@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'secure-pass-123');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(requests, contains('POST /api/auth/login'));
    expect(requests, contains('GET /api/users/me'));
    expect(auth.isAuthenticated, isTrue);
    expect(store.token, token);
    auth.dispose();
  });

  testWidgets('registration posts to the registration endpoint then signs in', (tester) async {
    final token = testToken();
    final requests = <String>[];
    final api = ApiClient(baseUrl: 'https://mobile.test', client: MockClient((request) async {
      requests.add('${request.method} ${request.url.path}');
      if (request.url.path == '/api/auth/register') return jsonResponse(userJson(), status: 201);
      if (request.url.path == '/api/auth/login') return jsonResponse({'access_token': token, 'token_type': 'bearer'});
      if (request.url.path == '/api/users/me') return jsonResponse(userJson());
      return jsonResponse([]);
    }));
    final auth = AuthController(api: api, tokenStore: MemoryTokenStore());

    await tester.pumpWidget(MaterialApp(home: AuthenticationScreen(auth: auth)));
    await tester.tap(find.text('New here? Create an account'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'member@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'secure-pass-123');
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(requests, contains('POST /api/auth/register'));
    expect(requests, contains('POST /api/auth/login'));
    expect(auth.isAuthenticated, isTrue);
    auth.dispose();
  });

  testWidgets('home displays actual market and result data', (tester) async {
    final api = ApiClient(baseUrl: 'https://mobile.test', client: MockClient((request) async {
      if (request.url.path == '/api/markets') return jsonResponse([marketJson()]);
      if (request.url.path == '/api/results') return jsonResponse([resultJson()]);
      return jsonResponse([]);
    }));
    await tester.pumpWidget(MaterialApp(home: HomeScreen(api: api, onOpenMarkets: () {}, onOpenResults: () {})));
    await tester.pumpAndSettle();
    expect(find.byType(MarketCard), findsOneWidget);
    expect(find.text('123-45-678'), findsOneWidget);
    api.close();
  });

  testWidgets('market search filters listings returned by the API', (tester) async {
    final api = ApiClient(baseUrl: 'https://mobile.test', client: MockClient((request) async {
      if (request.url.path == '/api/markets') return jsonResponse([marketJson(), marketJson(id: 9, name: 'River Market')]);
      if (request.url.path == '/api/users/me/favourites') return jsonResponse([]);
      return jsonResponse([]);
    }));
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: MarketsScreen(api: api))));
    await tester.pumpAndSettle();
    expect(find.text('Harbor Market'), findsOneWidget);
    expect(find.text('River Market'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'river');
    await tester.pumpAndSettle();
    expect(find.text('River Market'), findsOneWidget);
    expect(find.text('Harbor Market'), findsNothing);
    api.close();
  });

  testWidgets('favourites screen displays saved markets from the user endpoint', (tester) async {
    final api = ApiClient(baseUrl: 'https://mobile.test', client: MockClient((request) async {
      if (request.url.path == '/api/users/me/favourites') return jsonResponse([marketJson()]);
      return jsonResponse([]);
    }));
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: FavouritesScreen(api: api))));
    await tester.pumpAndSettle();
    expect(find.text('Saved markets'), findsOneWidget);
    expect(find.text('Harbor Market'), findsOneWidget);
    api.close();
  });

  testWidgets('market detail shows schedule and published results', (tester) async {
    final api = ApiClient(baseUrl: 'https://mobile.test', client: MockClient((request) async {
      if (request.url.path == '/api/markets/4') return jsonResponse(marketJson());
      if (request.url.path == '/api/markets/4/schedules') return jsonResponse([scheduleJson()]);
      if (request.url.path == '/api/results') return jsonResponse([resultJson()]);
      if (request.url.path == '/api/users/me/favourites') return jsonResponse([]);
      return jsonResponse([]);
    }));
    await tester.pumpWidget(MaterialApp(home: MarketDetailScreen(api: api, market: Market.fromJson(marketJson()))));
    await tester.pumpAndSettle();
    expect(find.text('Weekly schedule'), findsOneWidget);
    expect(find.text('Tuesday'), findsOneWidget);
    expect(find.text('123-45-678'), findsOneWidget);
    api.close();
  });

  testWidgets('results history loads from the published history route', (tester) async {
    final paths = <String>[];
    final api = ApiClient(baseUrl: 'https://mobile.test', client: MockClient((request) async {
      paths.add(request.url.path);
      return jsonResponse([resultJson()]);
    }));
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: ResultsScreen(api: api))));
    await tester.pumpAndSettle();
    expect(find.text('123-45-678'), findsOneWidget);
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(paths, contains('/api/results/history'));
    api.close();
  });

  testWidgets('offline market requests show a retryable offline state', (tester) async {
    final api = ApiClient(baseUrl: 'https://mobile.test', client: MockClient((_) async => throw http.ClientException('offline')));
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: MarketsScreen(api: api))));
    await tester.pumpAndSettle();
    expect(find.text('You’re offline'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    api.close();
  });

  testWidgets('profile displays account fields and signing out clears the token', (tester) async {
    final token = testToken();
    final api = ApiClient(baseUrl: 'https://mobile.test', client: MockClient((request) async => jsonResponse(userJson())));
    final store = MemoryTokenStore(token);
    final auth = AuthController(api: api, tokenStore: store);
    await auth.restoreSession();

    await tester.pumpWidget(MaterialApp(home: ProfileScreen(auth: auth, api: api)));
    await tester.pumpAndSettle();
    expect(find.text('member@example.com'), findsNWidgets(2));
    expect(find.text('MEMBER SINCE'), findsOneWidget);
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(auth.isAuthenticated, isFalse);
    expect(store.token, isNull);
    auth.dispose();
  });
}