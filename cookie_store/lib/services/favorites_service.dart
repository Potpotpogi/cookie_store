import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Favorites are saved in the `favorites` table in Supabase,
/// so they follow the user across devices.
class FavoritesService extends ChangeNotifier {
  FavoritesService._();
  static final FavoritesService instance = FavoritesService._();

  final Set<int> _ids = {};

  Set<int> get ids => Set.unmodifiable(_ids);
  bool isFavorite(int productId) => _ids.contains(productId);

  SupabaseClient get _db => Supabase.instance.client;

  Future<void> load() async {
    final user = _db.auth.currentUser;
    if (user == null) return;
    try {
      final rows =
          await _db.from('favorites').select('product_id').eq('user_id', user.id);
      _ids
        ..clear()
        ..addAll((rows as List).map((r) => (r['product_id'] as num).toInt()));
      notifyListeners();
    } catch (_) {
      // ignore: favorites are optional, the app still works without them
    }
  }

  Future<void> toggle(int productId) async {
    final user = _db.auth.currentUser;
    if (user == null) return;

    final wasFavorite = _ids.contains(productId);
    if (wasFavorite) {
      _ids.remove(productId);
    } else {
      _ids.add(productId);
    }
    notifyListeners(); // update the heart right away

    try {
      if (wasFavorite) {
        await _db
            .from('favorites')
            .delete()
            .eq('user_id', user.id)
            .eq('product_id', productId);
      } else {
        await _db
            .from('favorites')
            .insert({'user_id': user.id, 'product_id': productId});
      }
    } catch (_) {
      // undo if saving failed
      if (wasFavorite) {
        _ids.add(productId);
      } else {
        _ids.remove(productId);
      }
      notifyListeners();
    }
  }

  void clear() {
    _ids.clear();
    notifyListeners();
  }
}