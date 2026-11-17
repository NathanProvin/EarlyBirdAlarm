import 'dart:async';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'l10n/app_localizations.dart';
import 'main.dart';

/// Tips, smallest first (consumable: they can be bought again), and Twitch Plus (bought once).
/// The products and their prices live in the Play Console (decisions.md "Tips").
const tipIds = [
  'tip_espresso',
  'tip_cappuccino',
  'tip_breakfast',
  'tip_binoculars',
];
const twitchPlusId = 'twitch_plus';

/// The app's navigator (MaterialApp), to say thank you wherever the purchase ends.
final navigatorKey = GlobalKey<NavigatorState>();

/// After a purchase (a tip or Plus; not a restore): a plain thank-you, no bird icon
/// (user, 2026-11-17); Plus also says what it unlocked.
void _thanks({required bool plus}) {
  final context = navigatorKey.currentContext;
  if (context == null) return;
  final l = AppLocalizations.of(context);
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l.thankYou, textAlign: TextAlign.center),
      content: Text(
        plus ? l.thankYouPlus : l.thankYouBody,
        textAlign: TextAlign.center,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).okButtonLabel),
        ),
      ],
    ),
  );
}

/// Listens to Google Play purchases and restores Twitch Plus (reinstall, new phone).
// shortcut: purchases are trusted on the device (no server check), upgrade if Twitch Plus
// is shared or abused.
Future<void> initPurchases() async {
  try {
    if (!await InAppPurchase.instance.isAvailable()) return;
    InAppPurchase.instance.purchaseStream.listen(_handle, onError: (_) {});
    await InAppPurchase.instance.restorePurchases();
  } on Exception {
    // No Play Store on this phone: no purchases, everything else works.
  }
}

Future<void> _handle(List<PurchaseDetails> purchases) async {
  for (final p in purchases) {
    final ok =
        p.status == PurchaseStatus.purchased ||
        p.status == PurchaseStatus.restored;
    if (ok && p.productID == twitchPlusId) {
      store.twitchPlus = true;
      if (p.status == PurchaseStatus.purchased) _thanks(plus: true);
    } else if (p.status == PurchaseStatus.purchased) {
      _thanks(plus: false);
    }
    if (p.pendingCompletePurchase) {
      await InAppPurchase.instance.completePurchase(p);
    }
  }
}

/// The products with their prices in the player's currency; empty when Play is unavailable.
Future<Map<String, ProductDetails>> products() async {
  try {
    if (!await InAppPurchase.instance.isAvailable()) return {};
    final r = await InAppPurchase.instance.queryProductDetails({
      ...tipIds,
      twitchPlusId,
    });
    return {for (final p in r.productDetails) p.id: p};
  } on Exception {
    return {};
  }
}

/// Opens Google Play's payment sheet; the result arrives through [initPurchases]' listener.
Future<void> buy(ProductDetails product) {
  final param = PurchaseParam(productDetails: product);
  return product.id == twitchPlusId
      ? InAppPurchase.instance.buyNonConsumable(purchaseParam: param)
      : InAppPurchase.instance.buyConsumable(purchaseParam: param);
}
