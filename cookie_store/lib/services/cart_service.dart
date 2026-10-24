import 'package:flutter/foundation.dart';

class CartLine {
  CartLine({
    required this.productId,
    required this.name,
    required this.price,
    this.imageUrl,
    this.quantity = 1,
  });

  final int productId;
  final String name;
  final num price;
  final String? imageUrl;
  int quantity;

  num get subtotal => price * quantity;
}

/// Simple in-memory cart shared by the whole app.
/// (The cart is cleared when the app is closed or the user logs out.)
class CartService extends ChangeNotifier {
  CartService._();
  static final CartService instance = CartService._();

  final Map<int, CartLine> _lines = {};

  List<CartLine> get lines => _lines.values.toList();
  bool get isEmpty => _lines.isEmpty;
  int get itemCount => _lines.values.fold<int>(0, (sum, l) => sum + l.quantity);
  num get total => _lines.values.fold<num>(0, (sum, l) => sum + l.subtotal);

  void add(Map<String, dynamic> product) {
    final id = (product['id'] as num).toInt();
    final existing = _lines[id];
    if (existing != null) {
      existing.quantity++;
    } else {
      final image = (product['image_url'] ?? '').toString();
      _lines[id] = CartLine(
        productId: id,
        name: (product['name'] ?? 'Cookie').toString(),
        price: num.tryParse((product['price'] ?? 0).toString()) ?? 0,
        imageUrl: image.isEmpty ? null : image,
      );
    }
    notifyListeners();
  }

  void increase(int productId) {
    final line = _lines[productId];
    if (line == null) return;
    line.quantity++;
    notifyListeners();
  }

  void decrease(int productId) {
    final line = _lines[productId];
    if (line == null) return;
    if (line.quantity <= 1) {
      _lines.remove(productId);
    } else {
      line.quantity--;
    }
    notifyListeners();
  }

  void clear() {
    _lines.clear();
    notifyListeners();
  }
}