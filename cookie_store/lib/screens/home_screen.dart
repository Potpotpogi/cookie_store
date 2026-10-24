import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/cookie_art.dart';
import '../widgets/product_card.dart';
import '../widgets/product_tile.dart';
import 'category_products_screen.dart';

class _Category {
  const _Category(this.key, this.label, this.emoji, this.color);
  final String? key; // null = all cookies; must match products.category
  final String label;
  final String emoji;
  final Color color;
}

const _categories = [
  _Category(null, 'All', '🍪', Color(0xFFFFD9A8)),
  _Category('classic', 'Classic', '🍪', Color(0xFFFFE0B2)),
  _Category('chocolate', 'Chocolate', '🍫', Color(0xFFD7B8A3)),
  _Category('oats', 'Oats', '🥣', Color(0xFFF5E6A8)),
  _Category('special', 'Specials', '🎂', Color(0xFFF8BBD0)),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  final _search = TextEditingController();
  String _query = '';

  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    _future = _load();
    // Refresh the greeting when the user's info changes (e.g. a new username).
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final data = await Supabase.instance.client
        .from('products')
        .select()
        .order('id', ascending: true);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  
  String get _displayName {
    final user = Supabase.instance.client.auth.currentUser;
    final username = (user?.userMetadata?['username'] as String?)?.trim();
    if (username != null && username.isNotEmpty) return username;
    final full = (user?.userMetadata?['full_name'] as String?)?.trim();
    if (full == null || full.isEmpty) return 'there';
    return full.split(' ').first;
  }

  void _openCategory(String title, String? key) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CategoryProductsScreen(title: title, categoryKey: key),
      ),
    );
  }

  List<Map<String, dynamic>> _filter(List<Map<String, dynamic>> all) {
    final q = _query.trim().toLowerCase();
    return all
        .where((p) =>
            '${p['name'] ?? ''} ${p['description'] ?? ''}'.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initial = _displayName.characters.first.toUpperCase();

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _future,
            builder: (context, snapshot) {
              final loading = snapshot.connectionState == ConnectionState.waiting;
              final products = snapshot.data ?? const <Map<String, dynamic>>[];
              final searching = _query.trim().isNotEmpty;

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  // Greeting
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back',
                              style: TextStyle(
                                fontSize: 12,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              'Hi, $_displayName 👋',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF2B1A12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: scheme.primaryContainer,
                        child: Text(
                          initial,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Search
                  TextField(
                    controller: _search,
                    onChanged: (v) => setState(() => _query = v),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search cookies',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                _search.clear();
                                setState(() => _query = '');
                              },
                            ),
                      filled: true,
                      fillColor: const Color(0xFFF6EBDD),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (snapshot.hasError)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text('Could not load cookies.\n\n${snapshot.error}'),
                    )
                  else if (searching)
                    ..._searchResults(_filter(products))
                  else
                    ..._sections(products),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ---------- search ----------

  List<Widget> _searchResults(List<Map<String, dynamic>> results) {
    if (results.isEmpty) {
      return [
        const SizedBox(height: 40),
        Center(child: Text('No cookies match "${_query.trim()}" 🍪')),
      ];
    }
    return [
      _SectionHeader(title: '${results.length} result${results.length == 1 ? '' : 's'}'),
      const SizedBox(height: 12),
      for (final p in results) ...[
        ProductCard(product: p),
        const SizedBox(height: 12),
      ],
    ];
  }

  // ---------- normal home ----------

  List<Widget> _sections(List<Map<String, dynamic>> products) {
    return [
      _Banner(onOrder: () => _openCategory('All cookies', null)),
      const SizedBox(height: 24),

      const _SectionHeader(title: 'Categories'),
      const SizedBox(height: 12),
      SizedBox(
        height: 98,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 16),
          itemBuilder: (context, i) {
            final c = _categories[i];
            return _CategoryChip(
              category: c,
              onTap: () => _openCategory(
                c.key == null ? 'All cookies' : c.label,
                c.key,
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 24),

      if (products.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: Text('No cookies yet 🍪')),
        )
      else ...[
        _SectionHeader(
          title: 'Fresh picks',
          onSeeAll: () => _openCategory('All cookies', null),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 236,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: products.length > 6 ? 6 : products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) =>
                ProductTile(product: products[i], width: 160),
          ),
        ),
        const SizedBox(height: 24),
        const _SectionHeader(title: 'All cookies'),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: products.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.78,
          ),
          itemBuilder: (context, i) => ProductTile(product: products[i]),
        ),
      ],
    ];
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.onSeeAll});

  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2B1A12),
            ),
          ),
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF8D5A2B)),
            child: const Text('See all'),
          ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.onOrder});

  final VoidCallback onOrder;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 176,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2B1A12), Color(0xFF5A3522)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -34,
            bottom: -38,
            child: Transform.rotate(
              angle: -0.25,
              child: const CookieArt(size: 190),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Fresh from\nthe oven',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Baked daily, just for you',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: onOrder,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFC98A44),
                      foregroundColor: const Color(0xFF2B1A12),
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                    ),
                    child: const Text(
                      'Order now',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category, required this.onTap});

  final _Category category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: SizedBox(
        width: 68,
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: category.color,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(category.emoji, style: const TextStyle(fontSize: 30)),
            ),
            const SizedBox(height: 6),
            Text(
              category.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF4E2A14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}