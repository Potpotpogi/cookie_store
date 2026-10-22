import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Shows the cookies inside one category.
/// [categoryKey] == null means "show everything".
class CategoryProductsScreen extends StatefulWidget {
  const CategoryProductsScreen({
    super.key,
    required this.title,
    this.categoryKey,
  });

  final String title;
  final String? categoryKey;

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final table = Supabase.instance.client.from('products');
    final data = widget.categoryKey == null
        ? await table.select().order('id', ascending: true)
        : await table
            .select()
            .eq('category', widget.categoryKey!)
            .order('id', ascending: true);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Could not load cookies.\n\n${snapshot.error}\n\n'
                      'If it says the "category" column does not exist, run '
                      'supabase_categories.sql in the Supabase SQL Editor.',
                    ),
                  ),
                ],
              );
            }

            final items = snapshot.data ?? [];
            if (items.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('No cookies here yet 🍪')),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _ProductCard(product: items[i]),
            );
          },
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});

  final Map<String, dynamic> product;

  @override
  Widget build(BuildContext context) {
    final name = (product['name'] ?? 'Cookie').toString();
    final description = (product['description'] ?? '').toString();
    final imageUrl = (product['image_url'] ?? '').toString();
    final price = num.tryParse((product['price'] ?? 0).toString()) ?? 0;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 80,
                height: 80,
                child: imageUrl.isEmpty
                    ? const _EmojiThumb()
                    : Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const _EmojiThumb(),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    '₱${price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF8D5A2B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () {
                // TODO: connect to checkout (PaymentService.createInvoice)
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$name: checkout coming next')),
                );
              },
              child: const Text('Buy'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmojiThumb extends StatelessWidget {
  const _EmojiThumb();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFE0B2),
      alignment: Alignment.center,
      child: const Text('🍪', style: TextStyle(fontSize: 36)),
    );
  }
}