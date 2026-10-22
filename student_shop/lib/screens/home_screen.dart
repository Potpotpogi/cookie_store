import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'category_products_screen.dart';
import 'orders_screen.dart';

class _Category {
  const _Category(this.key, this.label, this.emoji, this.blurb, this.color);
  final String key; // must match products.category in the database
  final String label;
  final String emoji;
  final String blurb;
  final Color color;
}

const _categories = [
  _Category('classic', 'Classic', '🍪', 'Timeless favorites', Color(0xFFFFE0B2)),
  _Category(
      'chocolate', 'Chocolate', '🍫', 'For choco lovers', Color(0xFFD7B8A3)),
  _Category('oats', 'Oats & Fruity', '🥣', 'Soft & wholesome',
      Color(0xFFF5E6A8)),
  _Category('special', 'Specials', '🎂', 'Limited & fancy', Color(0xFFF8BBD0)),
];

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _firstName() {
    final user = Supabase.instance.client.auth.currentUser;
    final full = (user?.userMetadata?['full_name'] as String?)?.trim();
    if (full == null || full.isEmpty) return 'there';
    return full.split(' ').first;
  }

  void _open(BuildContext context, {required String title, String? key}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CategoryProductsScreen(title: title, categoryKey: key),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cookie Store'),
        actions: [
          IconButton(
            tooltip: 'My orders',
            icon: const Icon(Icons.receipt_long),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const OrdersScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: () => Supabase.instance.client.auth.signOut(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Hi, ${_firstName()} 👋',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'What are you craving today?',
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),

          // Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [Color(0xFF8D5A2B), Color(0xFFC98A44)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fresh from the oven',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Baked daily. Pick a category to start.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Text('🍪', style: TextStyle(fontSize: 56)),
              ],
            ),
          ),

          const SizedBox(height: 24),
          Text(
            'Categories',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.0,
            children: [
              for (final c in _categories)
                _CategoryCard(
                  category: c,
                  onTap: () => _open(context, title: c.label, key: c.key),
                ),
            ],
          ),

          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _open(context, title: 'All cookies'),
            icon: const Icon(Icons.grid_view),
            label: const Text('See all cookies'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.onTap});

  final _Category category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: category.color,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(category.emoji, style: const TextStyle(fontSize: 52)),
              const SizedBox(height: 10),
              Text(
                category.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF4E2A14),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                category.blurb,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Color(0xFF6D4C41)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}