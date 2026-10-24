import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/cart_service.dart';
import 'payment_webview_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _cart = CartService.instance;
  bool _busy = false;

  SupabaseClient get _db => Supabase.instance.client;

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _dialog(String title, String message) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// 1. ask our Edge Function for a Xendit invoice for the whole cart
  /// 2. open the payment page
  /// 3. check the order status afterwards
  Future<void> _checkout() async {
    if (_busy || _cart.isEmpty) return;
    setState(() => _busy = true);

    try {
      final res = await _db.functions.invoke(
        'create-invoice',
        body: {
          'items': [
            for (final l in _cart.lines)
              {'product_id': l.productId, 'quantity': l.quantity},
          ],
        },
      );

      final data = Map<String, dynamic>.from(res.data as Map);
      final invoiceUrl = data['invoice_url'] as String?;
      final externalId = data['external_id'] as String?;
      if (invoiceUrl == null || externalId == null) {
        throw Exception('No payment link was returned.');
      }
      if (!mounted) return;

      final result = await Navigator.of(context).push<PaymentResult>(
        MaterialPageRoute(
          builder: (_) => PaymentWebViewScreen(invoiceUrl: invoiceUrl),
        ),
      );
      if (!mounted) return;

      if (result == PaymentResult.success) {
        _cart.clear();
        final status = await _waitForStatus(externalId);
        if (status == 'PAID') {
          await _dialog('Payment received 🎉', 'Thank you! Your order is paid.');
        } else {
          await _dialog(
            'Confirming payment…',
            'We are still waiting for confirmation. '
                'Check "My orders" in your profile in a moment.',
          );
        }
      } else if (result == PaymentResult.failed) {
        _snack('Payment failed. Your cart is still here.');
      } else {
        _snack('Payment not completed. Your cart is still here.');
      }
    } on FunctionException catch (e) {
      _snack('Checkout failed: ${e.details ?? e.reasonPhrase}');
    } catch (e) {
      _snack('Checkout failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// The webhook updates the order a moment after payment, so check a few times.
  Future<String> _waitForStatus(String externalId) async {
    for (var i = 0; i < 6; i++) {
      final row = await _db
          .from('orders')
          .select('status')
          .eq('external_id', externalId)
          .maybeSingle();
      final status = (row?['status'] as String?) ?? 'PENDING';
      if (status != 'PENDING') return status;
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return 'PENDING';
    }
    return 'PENDING';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My cart')),
      body: Stack(
        children: [
          ListenableBuilder(
            listenable: _cart,
            builder: (context, _) {
              if (_cart.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shopping_cart_outlined,
                          size: 64, color: Theme.of(context).colorScheme.outline),
                      const SizedBox(height: 12),
                      const Text('Your cart is empty'),
                      const SizedBox(height: 4),
                      Text(
                        'Add some cookies from the Home tab.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final lines = _cart.lines;
              return Column(
                children: [
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: lines.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) => _CartRow(line: lines[i]),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      boxShadow: const [
                        BoxShadow(
                          blurRadius: 8,
                          color: Colors.black12,
                          offset: Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Total (${_cart.itemCount} items)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                              Text(
                                '₱${_cart.total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        FilledButton(
                          onPressed: _busy ? null : _checkout,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text('Checkout'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          if (_busy)
            Container(
              color: Colors.black26,
              alignment: Alignment.center,
              child: const CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}

class _CartRow extends StatelessWidget {
  const _CartRow({required this.line});

  final CartLine line;

  @override
  Widget build(BuildContext context) {
    final cart = CartService.instance;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 56,
                height: 56,
                child: line.imageUrl == null
                    ? const _EmojiThumb()
                    : Image.network(
                        line.imageUrl!,
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
                    line.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₱${line.subtotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF8D5A2B),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () => cart.decrease(line.productId),
            ),
            Text(
              '${line.quantity}',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => cart.increase(line.productId),
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
      child: const Text('🍪', style: TextStyle(fontSize: 26)),
    );
  }
}