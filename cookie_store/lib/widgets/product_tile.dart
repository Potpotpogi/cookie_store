import 'package:flutter/material.dart';

import '../services/cart_service.dart';
import '../services/favorites_service.dart';
import 'cookie_art.dart';

/// Square-ish product card: photo on top, heart, name, price and a + button.
/// Used in the Home carousel and grid.
class ProductTile extends StatelessWidget {
  const ProductTile({super.key, required this.product, this.width});

  final Map<String, dynamic> product;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final id = (product['id'] as num).toInt();
    final name = (product['name'] ?? 'Cookie').toString();
    final imageUrl = (product['image_url'] ?? '').toString();
    final price = num.tryParse((product['price'] ?? 0).toString()) ?? 0;

    return Container(
      width: width,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0E2D3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: imageUrl.isEmpty
                      ? const _Placeholder()
                      : Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const _Placeholder(),
                        ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: ListenableBuilder(
                    listenable: FavoritesService.instance,
                    builder: (context, _) {
                      final isFav = FavoritesService.instance.isFavorite(id);
                      return Material(
                        color: Colors.white,
                        elevation: 1,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => FavoritesService.instance.toggle(id),
                          child: Padding(
                            padding: const EdgeInsets.all(7),
                            child: Icon(
                              isFav ? Icons.favorite : Icons.favorite_border,
                              size: 18,
                              color: isFav ? Colors.red : const Color(0xFF6B3E26),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 10, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2B1A12),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '₱${price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFA8692B),
                        ),
                      ),
                    ],
                  ),
                ),
                Material(
                  color: const Color(0xFF6B3E26),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      CartService.instance.add(product);
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          SnackBar(
                            content: Text('$name added to cart'),
                            duration: const Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.add, size: 20, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown when a cookie has no photo yet: a drawn cookie on a warm background.
class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFE9CC), Color(0xFFFFD3A0)],
        ),
      ),
      alignment: Alignment.center,
      child: LayoutBuilder(
        builder: (context, c) =>
            CookieArt(size: (c.biggest.shortestSide * 0.85).clamp(40.0, 140.0)),
      ),
    );
  }
}