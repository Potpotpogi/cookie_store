import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/favorites_service.dart';
import '../widgets/product_card.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _fav = FavoritesService.instance;
  List<Map<String, dynamic>> _products = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fav.addListener(_load); // reload whenever a heart is tapped anywhere
    _load();
  }

  @override
  void dispose() {
    _fav.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final ids = _fav.ids.toList();
    if (ids.isEmpty) {
      if (mounted) {
        setState(() {
          _products = [];
          _loading = false;
          _error = null;
        });
      }
      return;
    }
    try {
      final data = await Supabase.instance.client
          .from('products')
          .select()
          .inFilter('id', ids)
          .order('id', ascending: true);
      if (!mounted) return;
      setState(() {
        _products = List<Map<String, dynamic>>.from(data);
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Could not load favorites.\n\n$_error'),
        ),
      );
    } else if (_products.isEmpty) {
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite_border,
                size: 64, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            const Text('No favorites yet'),
            const SizedBox(height: 4),
            Text(
              'Tap the heart on a cookie to save it here.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    } else {
      body = ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _products.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) => ProductCard(product: _products[i]),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: body,
    );
  }
}