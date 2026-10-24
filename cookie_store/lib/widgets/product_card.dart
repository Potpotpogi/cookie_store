import 'package:flutter/material.dart';

import '../services/cart_service.dart';
import '../services/favorites_service.dart';

/// One cookie row with a heart (favorite) and an "Add" (to cart) button.
class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product});

  final Map<String, dynamic> product;

  @override
  Widget build(BuildContext context) {
    final id = (product['id'] as num).toInt();
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
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListenableBuilder(
                  listenable: FavoritesService.instance,
                  builder: (context, _) {
                    final isFav = FavoritesService.instance.isFavorite(id);
                    return IconButton(
                      tooltip: isFav ? 'Remove from favorites' : 'Add to favorites',
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        color: isFav ? Colors.red : null,
                      ),
                      onPressed: () => FavoritesService.instance.toggle(id),
                    );
                  },
                ),
                FilledButton(
                  onPressed: () {
                    CartService.instance.add(product);
                    final messenger = ScaffoldMessenger.of(context);
                    messenger
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(
                          content: Text('$name added to cart'),
                          duration: const Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                  },
                  child: const Text('Add'),
                ),
              ],
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