import 'package:flutter/material.dart';

import 'api_client.dart';
import 'app_theme.dart';
import 'auth_controller.dart';
import 'models.dart';

String shortDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')} ${_month(date.month)} ${date.year}';

String _month(int value) => const [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ][value - 1];

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BrandMark(size: 62),
              const SizedBox(height: 24),
              Text('MATKA  /  PLATFORM', style: Theme.of(context).textTheme.titleSmall?.copyWith(letterSpacing: 1.4, fontWeight: FontWeight.w800)),
              const SizedBox(height: 7),
              const Text('MARKET INFORMATION', style: TextStyle(color: AppColors.quiet, fontSize: 9, letterSpacing: 1.6)),
              const SizedBox(height: 32),
              const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.gold)),
            ],
          ),
        ),
      );
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 42});

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: Transform.rotate(
          angle: .785398,
          child: Container(
            decoration: BoxDecoration(border: Border.all(color: AppColors.gold, width: 1)),
            child: Center(
              child: Transform.rotate(
                angle: -.785398,
                child: Text('M', style: TextStyle(color: AppColors.goldBright, fontFamily: 'serif', fontSize: size * .55)),
              ),
            ),
          ),
        ),
      );
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _slides = [
    _OnboardingSlide(
      icon: Icons.storefront_outlined,
      eyebrow: 'YOUR MARKETS',
      title: 'A clear view\nof the day.',
      description: 'Browse market listings and keep the schedules you follow close at hand.',
    ),
    _OnboardingSlide(
      icon: Icons.calendar_month_outlined,
      eyebrow: 'WEEKLY SCHEDULES',
      title: 'Know what\nopens next.',
      description: 'See each market’s published operating days and hours in one place.',
    ),
    _OnboardingSlide(
      icon: Icons.history_rounded,
      eyebrow: 'PUBLISHED RESULTS',
      title: 'Recent and\npast results.',
      description: 'Review published information and browse the historical record.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page == _slides.length - 1) {
      widget.onComplete();
    } else {
      _controller.nextPage(duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
            child: Column(
              children: [
                Row(children: [const BrandMark(), const SizedBox(width: 12), const Text('MATKA  /  PLATFORM', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: .7)), const Spacer(), TextButton(onPressed: widget.onComplete, child: const Text('Skip'))]),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _slides.length,
                    onPageChanged: (value) => setState(() => _page = value),
                    itemBuilder: (context, index) => _OnboardingPanel(slide: _slides[index], index: index),
                  ),
                ),
                Row(
                  children: [
                    ...List.generate(_slides.length, (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: _page == index ? 23 : 6,
                          height: 4,
                          margin: const EdgeInsets.only(right: 6),
                          color: _page == index ? AppColors.gold : AppColors.line,
                        )),
                    const Spacer(),
                    SizedBox(width: 142, child: FilledButton(onPressed: _next, child: Text(_page == _slides.length - 1 ? 'Get started' : 'Continue'))),
                  ],
                ),
                const SizedBox(height: 18),
                const Text('INFORMATION ONLY  •  NO WAGERING OR PAYMENTS', style: TextStyle(color: AppColors.quiet, fontSize: 8, letterSpacing: .8)),
              ],
            ),
          ),
        ),
      );
}

class _OnboardingSlide {
  const _OnboardingSlide({required this.icon, required this.eyebrow, required this.title, required this.description});
  final IconData icon;
  final String eyebrow;
  final String title;
  final String description;
}

class _OnboardingPanel extends StatelessWidget {
  const _OnboardingPanel({required this.slide, required this.index});
  final _OnboardingSlide slide;
  final int index;

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 94,
                height: 94,
                decoration: BoxDecoration(color: AppColors.surface, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(5)),
                child: Stack(alignment: Alignment.center, children: [Icon(slide.icon, size: 35, color: AppColors.goldBright), Positioned(right: 11, top: 11, child: Text('0${index + 1}', style: const TextStyle(color: AppColors.quiet, fontSize: 9, fontFamily: 'monospace')))]),
              ),
              const SizedBox(height: 34),
              Text(slide.eyebrow, style: const TextStyle(color: AppColors.gold, fontSize: 9, letterSpacing: 1.5)),
              const SizedBox(height: 14),
              Text(slide.title, style: const TextStyle(color: AppColors.text, fontSize: 38, height: 1.13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              Text(slide.description, style: const TextStyle(color: AppColors.muted, fontSize: 13, height: 1.7)),
              const SizedBox(height: 28),
              Container(width: 36, height: 1, color: AppColors.gold),
            ],
          ),
        ),
      );
}

class AuthenticationScreen extends StatefulWidget {
  const AuthenticationScreen({super.key, required this.auth, this.sessionMessage});

  final AuthController auth;
  final String? sessionMessage;

  @override
  State<AuthenticationScreen> createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _registerMode = false;
  bool _hidePassword = true;
  bool _pending = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _pending = true; _error = null; });
    try {
      if (_registerMode) {
        await widget.auth.register(_email.text, _password.text);
      } else {
        await widget.auth.signIn(_email.text, _password.text);
      }
      _password.clear();
    } catch (error) {
      if (mounted) setState(() => _error = error is ApiException ? error.message : 'Unable to sign in. Please try again.');
    } finally {
      if (mounted) setState(() => _pending = false);
    }
  }

  Future<void> _retrySavedSession() async {
    setState(() { _pending = true; _error = null; });
    try {
      await widget.auth.restoreSession();
    } catch (_) {
      if (mounted) setState(() => _error = 'Unable to restore your session. Please try again.');
    } finally {
      if (mounted) setState(() => _pending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: constraints.maxHeight > 650 ? 34 : 18),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [BrandMark(), SizedBox(width: 12), Text('MATKA  /  PLATFORM', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: .7))]),
                      SizedBox(height: constraints.maxHeight > 650 ? 60 : 34),
                      const Text('ACCOUNT ACCESS', style: TextStyle(color: AppColors.gold, fontSize: 9, letterSpacing: 1.5)),
                      const SizedBox(height: 10),
                      Text(_registerMode ? 'Create your profile.' : 'Welcome back.', style: const TextStyle(fontSize: 29, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text(_registerMode ? 'Register to save markets and view your profile.' : 'Sign in to see your saved markets and profile.', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                      const SizedBox(height: 28),
                      if (_error != null) ApiMessage(message: _error!, isError: true),
                      if (_error == null && widget.sessionMessage != null) ...[
                        ApiMessage(message: widget.sessionMessage!, isError: true),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: _pending ? null : _retrySavedSession,
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Retry saved session'),
                          ),
                        ),
                      ],
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.email],
                              decoration: const InputDecoration(labelText: 'Email address', prefixIcon: Icon(Icons.alternate_email, size: 18)),
                              validator: (value) {
                                final email = value?.trim() ?? '';
                                if (!email.contains('@') || !email.contains('.')) return 'Enter a valid email address';
                                return null;
                              },
                            ),
                            const SizedBox(height: 15),
                            TextFormField(
                              controller: _password,
                              obscureText: _hidePassword,
                              textInputAction: TextInputAction.done,
                              autofillHints: _registerMode ? const [AutofillHints.newPassword] : const [AutofillHints.password],
                              onFieldSubmitted: (_) => _submit(),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline, size: 18),
                                suffixIcon: IconButton(tooltip: _hidePassword ? 'Show password' : 'Hide password', onPressed: () => setState(() => _hidePassword = !_hidePassword), icon: Icon(_hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18)),
                              ),
                              validator: (value) {
                                if ((value ?? '').isEmpty) return 'Enter your password';
                                if (_registerMode && value!.length < 8) return 'Use at least 8 characters';
                                return null;
                              },
                            ),
                            if (_registerMode) ...[
                              const SizedBox(height: 9),
                              const Align(alignment: Alignment.centerLeft, child: Text('Use 8–128 characters. Your password is never stored on this device.', style: TextStyle(color: AppColors.quiet, fontSize: 10))),
                            ],
                            const SizedBox(height: 22),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: _pending ? null : _submit,
                                child: _pending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Text(_registerMode ? 'Create account' : 'Sign in'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),
                      Center(child: TextButton(onPressed: _pending ? null : () => setState(() { _registerMode = !_registerMode; _error = null; }), child: Text(_registerMode ? 'Already registered? Sign in' : 'New here? Create an account'))),
                      const SizedBox(height: 20),
                      const InfoBanner(icon: Icons.shield_outlined, text: 'Market schedules and published results are informational only. No wagers, deposits or payouts.'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.auth, required this.api});
  final AuthController auth;
  final ApiClient api;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(api: widget.api, onOpenMarkets: () => setState(() => _index = 1), onOpenResults: () => setState(() => _index = 2)),
      MarketsScreen(api: widget.api),
      ResultsScreen(api: widget.api),
      FavouritesScreen(api: widget.api),
      ProfileScreen(auth: widget.auth, api: widget.api),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Row(mainAxisSize: MainAxisSize.min, children: [BrandMark(size: 26), SizedBox(width: 11), Text('MATKA  /  PLATFORM', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: .7))]),
        actions: [Padding(padding: const EdgeInsets.only(right: 17), child: Center(child: Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle))))],
      ),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront), label: 'Markets'),
          NavigationDestination(icon: Icon(Icons.query_stats_outlined), selectedIcon: Icon(Icons.query_stats), label: 'Results'),
          NavigationDestination(icon: Icon(Icons.favorite_border), selectedIcon: Icon(Icons.favorite), label: 'Saved'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.api, required this.onOpenMarkets, required this.onOpenResults});
  final ApiClient api;
  final VoidCallback onOpenMarkets;
  final VoidCallback onOpenResults;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<_HomeData> _data;

  @override
  void initState() {
    super.initState();
    _data = _load();
  }

  Future<_HomeData> _load() async {
    final responses = await Future.wait([widget.api.getMarkets(), widget.api.getResults(limit: 6)]);
    return _HomeData(responses[0] as List<Market>, responses[1] as List<PublishedResult>);
  }

  void _retry() => setState(() => _data = _load());

  @override
  Widget build(BuildContext context) => RefreshIndicator(
        color: AppColors.gold,
        onRefresh: () async => _retry(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 19, 18, 26),
          children: [
            const Text('YOUR INFORMATION DESK', style: TextStyle(color: AppColors.gold, fontSize: 9, letterSpacing: 1.5)),
            const SizedBox(height: 7),
            Text(_greeting(), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 5),
            const Text('Markets, schedules and published results.', style: TextStyle(color: AppColors.muted, fontSize: 12)),
            const SizedBox(height: 19),
            FutureBuilder<_HomeData>(
              future: _data,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) return const LoadingState(message: 'Loading today’s information');
                if (snapshot.hasError) return ErrorState(error: snapshot.error!, onRetry: _retry);
                final data = snapshot.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [Expanded(child: _StatTile(label: 'MARKETS', value: '${data.markets.length}', icon: Icons.storefront_outlined)), const SizedBox(width: 9), Expanded(child: _StatTile(label: 'PUBLISHED', value: '${data.results.length}', icon: Icons.auto_graph_rounded))]),
                    const SizedBox(height: 23),
                    SectionHeading(title: 'Markets', actionText: 'View all', onAction: widget.onOpenMarkets),
                    const SizedBox(height: 10),
                    if (data.markets.isEmpty) const EmptyState(title: 'No markets available', message: 'Published markets will appear here when available.') else ...data.markets.take(3).map((market) => Padding(padding: const EdgeInsets.only(bottom: 8), child: MarketCard(api: widget.api, market: market, onTap: () => _openMarket(context, widget.api, market)))),
                    const SizedBox(height: 14),
                    SectionHeading(title: 'Recent results', actionText: 'History', onAction: widget.onOpenResults),
                    const SizedBox(height: 10),
                    if (data.results.isEmpty) const EmptyState(title: 'No published results', message: 'Results will appear here after publication.') else ...data.results.take(4).map((result) => ResultCard(result: result, marketName: _marketName(data.markets, result.marketId))),
                    const SizedBox(height: 17),
                    const InfoBanner(icon: Icons.info_outline, text: 'This app displays informational market data only. No real-money activity is available.'),
                  ],
                );
              },
            ),
          ],
        ),
      );
}

String _greeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good morning.';
  if (hour < 17) return 'Good afternoon.';
  return 'Good evening.';
}

String? _marketName(List<Market> markets, int marketId) {
  for (final market in markets) {
    if (market.id == marketId) return market.name;
  }
  return null;
}

class _HomeData {
  const _HomeData(this.markets, this.results);
  final List<Market> markets;
  final List<PublishedResult> results;
}

class MarketsScreen extends StatefulWidget {
  const MarketsScreen({super.key, required this.api});
  final ApiClient api;

  @override
  State<MarketsScreen> createState() => _MarketsScreenState();
}

class _MarketsScreenState extends State<MarketsScreen> {
  late Future<_MarketData> _data;
  final _search = TextEditingController();
  String _query = '';
  bool _onlySaved = false;

  @override
  void initState() {
    super.initState();
    _data = _load();
  }

  Future<_MarketData> _load() async {
    final responses = await Future.wait([widget.api.getMarkets(), widget.api.getFavourites()]);
    return _MarketData(responses[0], responses[1].map((m) => m.id).toSet());
  }

  void _reload() => setState(() => _data = _load());

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<_MarketData>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const LoadingState(message: 'Loading markets');
          if (snapshot.hasError) return ErrorState(error: snapshot.error!, onRetry: _reload);
          final data = snapshot.data!;
          final filtered = data.markets.where((market) {
            final matches = '${market.name} ${market.slug} ${market.description ?? ''}'.toLowerCase().contains(_query.toLowerCase());
            return matches && (!_onlySaved || data.savedIds.contains(market.id));
          }).toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('MARKET DIRECTORY', style: TextStyle(color: AppColors.gold, fontSize: 9, letterSpacing: 1.4)),
                  const SizedBox(height: 6),
                  Text('Markets', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 13),
                  TextField(controller: _search, onChanged: (value) => setState(() => _query = value), decoration: const InputDecoration(prefixIcon: Icon(Icons.search, size: 19), hintText: 'Search markets')),
                  const SizedBox(height: 9),
                  Row(children: [FilterChip(label: const Text('Saved only'), selected: _onlySaved, onSelected: (value) => setState(() => _onlySaved = value), avatar: const Icon(Icons.favorite_border, size: 15)), const Spacer(), Text('${filtered.length} MARKETS', style: const TextStyle(color: AppColors.quiet, fontSize: 9, letterSpacing: .6))]),
                ]),
              ),
              Expanded(child: filtered.isEmpty ? EmptyState(title: data.markets.isEmpty ? 'No markets yet' : 'No matches', message: data.markets.isEmpty ? 'Market listings are not available yet. Try again later.' : 'Try another search or clear the saved-only filter.') : ListView.separated(padding: const EdgeInsets.fromLTRB(16, 2, 16, 18), itemCount: filtered.length, separatorBuilder: (_, __) => const SizedBox(height: 8), itemBuilder: (context, index) => MarketCard(api: widget.api, market: filtered[index], isSaved: data.savedIds.contains(filtered[index].id), onSavedChanged: _reload, onTap: () => _openMarket(context, widget.api, filtered[index])))),
            ],
          );
        },
      );
}

class _MarketData {
  const _MarketData(this.markets, this.savedIds);
  final List<Market> markets;
  final Set<int> savedIds;
}

class MarketDetailScreen extends StatefulWidget {
  const MarketDetailScreen({super.key, required this.api, required this.market});
  final ApiClient api;
  final Market market;

  @override
  State<MarketDetailScreen> createState() => _MarketDetailScreenState();
}

class _MarketDetailScreenState extends State<MarketDetailScreen> {
  late Future<_DetailData> _data;
  bool _saved = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _data = _load();
  }

  Future<_DetailData> _load() async {
    final responses = await Future.wait([widget.api.getMarketDetail(widget.market.id), widget.api.getResults(marketId: widget.market.id), widget.api.getFavourites()]);
    final favourites = responses[2] as List<Market>;
    _saved = favourites.any((item) => item.id == widget.market.id);
    return _DetailData(responses[0] as MarketDetail, responses[1] as List<PublishedResult>);
  }

  Future<void> _toggleSaved() async {
    setState(() => _saving = true);
    try {
      if (_saved) {
        await widget.api.removeFavourite(widget.market.id);
      } else {
        await widget.api.addFavourite(widget.market.id);
      }
      if (mounted) setState(() => _saved = !_saved);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error is ApiException ? error.message : 'Could not update favourites')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Market details', style: TextStyle(fontSize: 15)), actions: [IconButton(tooltip: _saved ? 'Remove from saved' : 'Save market', onPressed: _saving ? null : _toggleSaved, icon: Icon(_saved ? Icons.favorite : Icons.favorite_border, color: _saved ? AppColors.goldBright : null))]),
        body: FutureBuilder<_DetailData>(
          future: _data,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) return const LoadingState(message: 'Loading market details');
            if (snapshot.hasError) return ErrorState(error: snapshot.error!, onRetry: () => setState(() => _data = _load()));
            final data = snapshot.data!;
            return ListView(padding: const EdgeInsets.fromLTRB(18, 8, 18, 28), children: [
              Text(data.detail.market.slug.toUpperCase(), style: const TextStyle(color: AppColors.gold, fontSize: 9, letterSpacing: 1.4)),
              const SizedBox(height: 8),
              Text(data.detail.market.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
              if ((data.detail.market.description ?? '').isNotEmpty) ...[const SizedBox(height: 8), Text(data.detail.market.description!, style: const TextStyle(color: AppColors.muted, height: 1.6))],
              const SizedBox(height: 24),
              const SectionHeading(title: 'Weekly schedule'),
              const SizedBox(height: 9),
              if (data.detail.schedules.isEmpty) const EmptyState(title: 'No schedule published', message: 'There are no active hours listed for this market.') else ...data.detail.schedules.where((s) => s.isActive).map((schedule) => _ScheduleRow(schedule: schedule)),
              const SizedBox(height: 23),
              const SectionHeading(title: 'Published results'),
              const SizedBox(height: 9),
              if (data.results.isEmpty) const EmptyState(title: 'No results published', message: 'Published results for this market will appear here.') else ...data.results.take(8).map((result) => ResultCard(result: result, marketName: data.detail.market.name)),
            ]);
          },
        ),
      );
}

class _DetailData {
  const _DetailData(this.detail, this.results);
  final MarketDetail detail;
  final List<PublishedResult> results;
}

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key, required this.api});
  final ApiClient api;

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  bool _history = false;
  late Future<List<PublishedResult>> _results;

  @override
  void initState() {
    super.initState();
    _results = widget.api.getResults();
  }

  void _load() => setState(() => _results = widget.api.getResults(history: _history));

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(17, 18, 17, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('PUBLICATIONS', style: TextStyle(color: AppColors.gold, fontSize: 9, letterSpacing: 1.4)),
              const SizedBox(height: 6),
              Text('Results', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 13),
              SegmentedButton<bool>(
                segments: const [ButtonSegment(value: false, label: Text('Recent')), ButtonSegment(value: true, label: Text('History'))],
                selected: {_history},
                onSelectionChanged: (selection) => setState(() { _history = selection.first; _results = widget.api.getResults(history: _history); }),
                showSelectedIcon: false,
              ),
            ]),
          ),
          Expanded(child: FutureBuilder<List<PublishedResult>>(
            future: _results,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) return const LoadingState(message: 'Loading published results');
              if (snapshot.hasError) return ErrorState(error: snapshot.error!, onRetry: _load);
              final rows = snapshot.data!;
              return rows.isEmpty ? EmptyState(title: _history ? 'No historical results' : 'No recent results', message: _history ? 'Older published results will appear here.' : 'Newly published results will appear here.') : ListView.separated(padding: const EdgeInsets.fromLTRB(16, 2, 16, 18), itemCount: rows.length, separatorBuilder: (_, __) => const SizedBox(height: 8), itemBuilder: (_, index) => ResultCard(result: rows[index]));
            },
          )),
        ],
      );
}

class FavouritesScreen extends StatefulWidget {
  const FavouritesScreen({super.key, required this.api});
  final ApiClient api;

  @override
  State<FavouritesScreen> createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends State<FavouritesScreen> {
  late Future<List<Market>> _favourites;

  @override
  void initState() {
    super.initState();
    _favourites = widget.api.getFavourites();
  }

  void _reload() => setState(() => _favourites = widget.api.getFavourites());

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.fromLTRB(17, 18, 17, 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('YOUR COLLECTION', style: TextStyle(color: AppColors.gold, fontSize: 9, letterSpacing: 1.4)), const SizedBox(height: 6), Text('Saved markets', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700))])),
          Expanded(child: FutureBuilder<List<Market>>(
            future: _favourites,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) return const LoadingState(message: 'Loading saved markets');
              if (snapshot.hasError) return ErrorState(error: snapshot.error!, onRetry: _reload);
              final rows = snapshot.data!;
              if (rows.isEmpty) return const EmptyState(title: 'No saved markets', message: 'Use the heart on a market to add it to your collection.');
              return ListView.separated(padding: const EdgeInsets.fromLTRB(16, 2, 16, 18), itemCount: rows.length, separatorBuilder: (_, __) => const SizedBox(height: 8), itemBuilder: (context, index) => MarketCard(api: widget.api, market: rows[index], isSaved: true, onSavedChanged: _reload, onTap: () => _openMarket(context, widget.api, rows[index])));
            },
          )),
        ],
      );
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.auth, required this.api});
  final AuthController auth;
  final ApiClient api;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<UserProfile> _profile;

  @override
  void initState() {
    super.initState();
    _profile = widget.api.getProfile();
  }

  void _reload() => setState(() => _profile = widget.api.getProfile());

  @override
  Widget build(BuildContext context) => FutureBuilder<UserProfile>(
        future: _profile,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const LoadingState(message: 'Loading profile');
          if (snapshot.hasError) return ErrorState(error: snapshot.error!, onRetry: _reload);
          final user = snapshot.data!;
          return ListView(padding: const EdgeInsets.fromLTRB(18, 20, 18, 28), children: [
            const Text('ACCOUNT', style: TextStyle(color: AppColors.gold, fontSize: 9, letterSpacing: 1.4)),
            const SizedBox(height: 7),
            Text('Your profile', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 21),
            Card(child: Padding(padding: const EdgeInsets.all(17), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Container(width: 43, height: 43, alignment: Alignment.center, decoration: BoxDecoration(color: AppColors.gold.withValues(alpha: .12), border: Border.all(color: AppColors.gold.withValues(alpha: .3)), borderRadius: BorderRadius.circular(4)), child: Text(user.email.isEmpty ? '?' : user.email[0].toUpperCase(), style: const TextStyle(color: AppColors.goldBright, fontSize: 18, fontWeight: FontWeight.w700))), const SizedBox(width: 13), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(user.email, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)), const SizedBox(height: 4), const Text('Registered member', style: TextStyle(color: AppColors.muted, fontSize: 10))]))]),
              const Divider(height: 28),
              _ProfileField(label: 'ACCOUNT ID', value: '${user.id}'),
              const SizedBox(height: 14),
              _ProfileField(label: 'EMAIL', value: user.email),
              const SizedBox(height: 14),
              _ProfileField(label: 'MEMBER SINCE', value: shortDate(user.createdAt)),
            ]))),
            const SizedBox(height: 15),
            const InfoBanner(icon: Icons.shield_outlined, text: 'Your access token is stored using Android secure storage and removed when you sign out.'),
            const SizedBox(height: 17),
            OutlinedButton.icon(onPressed: widget.auth.signOut, icon: const Icon(Icons.logout, size: 18), label: const Text('Sign out'), style: OutlinedButton.styleFrom(foregroundColor: AppColors.red, side: const BorderSide(color: Color(0x553B302D)), minimumSize: const Size.fromHeight(47))),
            const SizedBox(height: 16),
            const Center(child: Text('INFORMATION ONLY  •  NO WAGERS  •  NO PAYMENTS', style: TextStyle(color: AppColors.quiet, fontSize: 8, letterSpacing: .5))),
          ]);
        },
      );
}

class MarketCard extends StatefulWidget {
  const MarketCard({super.key, required this.api, required this.market, required this.onTap, this.isSaved = false, this.onSavedChanged});
  final ApiClient api;
  final Market market;
  final VoidCallback onTap;
  final bool isSaved;
  final VoidCallback? onSavedChanged;

  @override
  State<MarketCard> createState() => _MarketCardState();
}

class _MarketCardState extends State<MarketCard> {
  late bool _saved;
  bool _pending = false;

  @override
  void initState() {
    super.initState();
    _saved = widget.isSaved;
  }

  @override
  void didUpdateWidget(covariant MarketCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isSaved != widget.isSaved) _saved = widget.isSaved;
  }

  Future<void> _toggle() async {
    setState(() => _pending = true);
    try {
      if (_saved) {
        await widget.api.removeFavourite(widget.market.id);
      } else {
        await widget.api.addFavourite(widget.market.id);
      }
      if (mounted) {
        setState(() => _saved = !_saved);
        widget.onSavedChanged?.call();
      }
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error is ApiException ? error.message : 'Could not update saved markets')));
    } finally {
      if (mounted) setState(() => _pending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(5),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(13, 13, 7, 13),
            child: Row(children: [
              Container(width: 38, height: 38, alignment: Alignment.center, decoration: BoxDecoration(color: AppColors.gold.withValues(alpha: .08), border: Border.all(color: AppColors.gold.withValues(alpha: .16)), borderRadius: BorderRadius.circular(4)), child: const Icon(Icons.storefront_outlined, color: AppColors.gold, size: 18)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(widget.market.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)), const SizedBox(height: 4), Text(widget.market.description?.isNotEmpty == true ? widget.market.description! : widget.market.slug, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontSize: 10))])),
              IconButton(tooltip: _saved ? 'Remove saved market' : 'Save market', onPressed: _pending ? null : _toggle, icon: Icon(_saved ? Icons.favorite : Icons.favorite_border, color: _saved ? AppColors.goldBright : AppColors.quiet, size: 19)),
              const Icon(Icons.chevron_right, color: AppColors.quiet, size: 18),
            ]),
          ),
        ),
      );
}

class ResultCard extends StatelessWidget {
  const ResultCard({super.key, required this.result, this.marketName});
  final PublishedResult result;
  final String? marketName;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
          child: Row(children: [
            Container(width: 37, height: 37, alignment: Alignment.center, decoration: BoxDecoration(color: AppColors.gold.withValues(alpha: .08), borderRadius: BorderRadius.circular(4)), child: const Icon(Icons.auto_graph_rounded, color: AppColors.gold, size: 18)),
            const SizedBox(width: 11),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(marketName ?? 'Market ${result.marketId}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)), const SizedBox(height: 4), Text(shortDate(result.resultDate), style: const TextStyle(color: AppColors.muted, fontSize: 9))])),
            const SizedBox(width: 8),
            Text(result.value, style: const TextStyle(color: AppColors.goldBright, fontFamily: 'monospace', fontSize: 14, fontWeight: FontWeight.w600)),
          ]),
        ),
      );
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({required this.schedule});
  final MarketSchedule schedule;

  static const _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12), child: Row(children: [const Icon(Icons.schedule_outlined, color: AppColors.gold, size: 17), const SizedBox(width: 10), Expanded(child: Text(_days[schedule.weekday], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))), Text('${schedule.opensAt.substring(0, 5)} – ${schedule.closesAt.substring(0, 5)}', style: const TextStyle(color: AppColors.muted, fontFamily: 'monospace', fontSize: 10))])));
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(13), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: AppColors.gold, size: 17), const SizedBox(height: 12), Text(value, style: const TextStyle(fontSize: 24, fontFamily: 'monospace')), const SizedBox(height: 3), Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 9, letterSpacing: .7))])));
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: AppColors.quiet, fontSize: 8, letterSpacing: .9)), const SizedBox(height: 5), Text(value, style: const TextStyle(color: AppColors.text, fontSize: 11))]);
}

class SectionHeading extends StatelessWidget {
  const SectionHeading({super.key, required this.title, this.actionText, this.onAction});
  final String title;
  final String? actionText;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(children: [Expanded(child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700))), if (actionText != null) TextButton(onPressed: onAction, child: Text(actionText!, style: const TextStyle(fontSize: 10)))]);
}

class LoadingState extends StatelessWidget {
  const LoadingState({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 1.8, color: AppColors.gold)), const SizedBox(height: 12), Text(message, style: const TextStyle(color: AppColors.muted, fontSize: 11))])));
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.title, required this.message});
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 25), child: Column(mainAxisSize: MainAxisSize.min, children: [Container(width: 38, height: 38, alignment: Alignment.center, decoration: BoxDecoration(border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(4)), child: const Icon(Icons.remove, color: AppColors.gold, size: 18)), const SizedBox(height: 12), Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)), const SizedBox(height: 6), Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, fontSize: 10, height: 1.5))])));
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final (offline, message) = switch (error) {
      ApiException(:final isOffline, :final message) => (isOffline, message),
      _ => (false, 'Something went wrong. Please try again.'),
    };
    return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(offline ? Icons.wifi_off_rounded : Icons.error_outline, color: offline ? AppColors.gold : AppColors.red, size: 24), const SizedBox(height: 10), Text(offline ? 'You’re offline' : 'Couldn’t load this view', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)), const SizedBox(height: 6), Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, fontSize: 10, height: 1.5)), const SizedBox(height: 13), OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh, size: 16), label: const Text('Try again'))])));
  }
}

class InfoBanner extends StatelessWidget {
  const InfoBanner({super.key, required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.surface, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(4)), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: AppColors.gold, size: 16), const SizedBox(width: 10), Expanded(child: Text(text, style: const TextStyle(color: AppColors.muted, fontSize: 9, height: 1.5)))]));
}

class ApiMessage extends StatelessWidget {
  const ApiMessage({super.key, required this.message, this.isError = false});
  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) => Container(width: double.infinity, margin: const EdgeInsets.only(bottom: 14), padding: const EdgeInsets.all(11), decoration: BoxDecoration(color: (isError ? AppColors.red : AppColors.green).withValues(alpha: .08), border: Border.all(color: (isError ? AppColors.red : AppColors.green).withValues(alpha: .22)), borderRadius: BorderRadius.circular(3)), child: Text(message, style: TextStyle(color: isError ? const Color(0xFFE1ADA3) : AppColors.green, fontSize: 10)));
}

void _openMarket(BuildContext context, ApiClient api, Market market) {
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => MarketDetailScreen(api: api, market: market)));
}