import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'cards.dart';
import 'store.dart';
import 'trade.dart';

/// Remote trades' Firestore side (2026-11-13): `trades/{a}_{b}`, see trade.dart for the
/// logic and firestore.rules for what each side may write.

DocumentReference<Map<String, dynamic>> _doc(String id) =>
    FirebaseFirestore.instance.collection('trades').doc(id);

String? get _uid => FirebaseAuth.instance.currentUser?.uid;

/// The document with the server's Timestamp turned into a DateTime for [RemoteTrade].
RemoteTrade? _read(DocumentSnapshot<Map<String, dynamic>> s, String me) {
  final d = s.data();
  if (d == null) return null;
  return RemoteTrade(s.id, {
    ...d,
    'created': (d['created'] as Timestamp?)?.toDate(),
  }, me);
}

/// The trade with [friend], opened (empty) if there is none yet; then its live updates
/// (null once it's gone: cancelled, expired or completed on both phones).
Stream<RemoteTrade?> watchTrade(String friend) async* {
  final me = _uid!;
  final ref = _doc(tradeId(me, friend));
  if (!(await ref.get()).exists) {
    final (a, b) = me.compareTo(friend) < 0 ? (me, friend) : (friend, me);
    await ref.set({
      'a': a,
      'b': b,
      'aCards': <Object>[],
      'bCards': <Object>[],
      'aOk': null,
      'bOk': null,
      'aDone': false,
      'bDone': false,
      'created': FieldValue.serverTimestamp(),
    });
  }
  yield* ref.snapshots().map((s) => _read(s, me));
}

String _side(RemoteTrade t) => t.id.startsWith('${_uid!}_') ? 'a' : 'b';

/// This player's new offer; their previous validation no longer matches it.
Future<void> setOffer(RemoteTrade t, List<CardData> cards) => _doc(t.id).update(
  {
    '${_side(t)}Cards': [for (final c in cards.take(maxTradeCards)) c.toJson()],
    '${_side(t)}Ok': null,
  },
);

/// "I agree with both offers as they are."
Future<void> validate(RemoteTrade t) =>
    _doc(t.id).update({'${_side(t)}Ok': t.hash});

Future<void> cancelTrade(RemoteTrade t) => _doc(t.id).delete();

/// Applies the swap on this phone, once: the cards offered leave, the friend's arrive;
/// then marks it done, and the last phone to apply deletes the trade. Returns the cards
/// received (empty if it was already applied here).
Future<List<CardData>> applyTrade(Store store, RemoteTrade t) async {
  if (!t.swapping) return const [];
  final key = '${t.id}|${t.hash}';
  var received = const <CardData>[];
  if (!store.tradesApplied.contains(key)) {
    final give = [
      for (final c in t.mine)
        if (store.cards.any((x) => x.key == c.key)) c,
    ];
    received = t.theirs;
    await store.trade(give, received);
    store.tradesApplied = {...store.tradesApplied, key};
  }
  try {
    if (!t.myDone) await _doc(t.id).update({'${_side(t)}Done': true});
    if (t.theirDone) await _doc(t.id).delete();
  } on FirebaseException catch (e) {
    debugPrint('trade: $e'); // done again at the next look
  }
  return received;
}

/// This player's open trades.
Future<List<RemoteTrade>> myTrades() async {
  final me = _uid;
  if (me == null) return const [];
  final col = FirebaseFirestore.instance.collection('trades');
  final both = await Future.wait([
    col.where('a', isEqualTo: me).get(),
    col.where('b', isEqualTo: me).get(),
  ]);
  return [
    for (final q in both)
      for (final s in q.docs) ?_read(s, me),
  ];
}

/// At launch and back from a trade: applies completed swaps, cancels expired trades and
/// sets the profile icon's dot when a trade waits for this player.
Future<void> sweepTrades(Store store) async {
  try {
    var waiting = false;
    for (final t in await myTrades()) {
      if (t.swapping) {
        await applyTrade(store, t);
      } else if (t.expired(DateTime.now()) || t.forged) {
        await cancelTrade(t);
      } else if (t.needsMe) {
        waiting = true;
      }
    }
    store.tradeWaiting = waiting;
  } on Exception catch (e) {
    debugPrint('trade: $e');
  }
}
