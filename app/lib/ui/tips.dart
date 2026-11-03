import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../l10n/app_localizations.dart';
import '../main.dart';
import '../purchases.dart';
import 'bird_icon.dart';
import 'theme.dart';

/// Settings → Buy me a coffee: four tips through Google Play, pure thanks (nothing in the game).
class TipsScreen extends StatefulWidget {
  const TipsScreen({super.key});

  @override
  State<TipsScreen> createState() => _TipsScreenState();
}

class _TipsScreenState extends State<TipsScreen> {
  final _products = products();

  @override
  void initState() {
    super.initState();
    onTip = _thanks;
  }

  @override
  void dispose() {
    if (onTip == _thanks) onTip = null;
    super.dispose();
  }

  void _thanks() {
    if (!mounted) return;
    final l = AppLocalizations.of(context);
    final bird = store.theme != 'system'
        ? store.theme
        : Theme.of(context).brightness == Brightness.dark
        ? darkTheme
        : lightTheme;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: SizedBox.square(
          dimension: 72,
          child: CustomPaint(painter: BirdPainter.of(bird)),
        ),
        title: Text(l.thankYou),
        content: Text(l.thankYouBody, textAlign: TextAlign.center),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(MaterialLocalizations.of(context).okButtonLabel),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final tips = [
      (Icons.coffee, l.tipEspresso),
      (Icons.local_cafe, l.tipCappuccino),
      (Icons.bakery_dining, l.tipBreakfast),
      (Icons.remove_red_eye_outlined, l.tipBinoculars),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l.tipsTile)),
      body: FutureBuilder(
        future: _products,
        builder: (context, snap) {
          final found = snap.data ?? const <String, ProductDetails>{};
          return ListView(
            padding: EdgeInsets.fromLTRB(
              24,
              24,
              24,
              24 + MediaQuery.paddingOf(context).bottom,
            ),
            children: [
              Text(l.tipsNote, style: text.bodyMedium),
              const SizedBox(height: 24),
              for (final (i, (icon, name)) in tips.indexed) ...[
                _TipTile(icon, name, found[tipIds[i]]),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 12),
              Text(
                snap.connectionState == ConnectionState.done && found.isEmpty
                    ? l.purchasesUnavailable
                    : l.tipsPayments,
                style: text.bodySmall,
              ),
            ],
          );
        },
      ),
    );
  }
}

/// One tip: its icon and name, Google Play's price on the right; greyed until the price is known.
class _TipTile extends StatelessWidget {
  const _TipTile(this.icon, this.name, this.product);
  final IconData icon;
  final String name;
  final ProductDetails? product;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    style: OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(56),
      padding: const EdgeInsets.symmetric(horizontal: 16),
    ),
    onPressed: product == null ? null : () => buy(product!),
    child: Row(
      children: [
        Icon(icon),
        const SizedBox(width: 16),
        Expanded(child: Text(name)),
        Text(
          product?.price ?? '',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );
}
