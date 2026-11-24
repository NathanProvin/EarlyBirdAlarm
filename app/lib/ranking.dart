import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'cards.dart';
import 'main.dart' show store;
import 'store.dart';
import 'ui/profile.dart' show collectionPoints;

/// The monthly world ranking (2026-11-23): `ranks/{month}/players/{uid}` = {name, points},
/// each player writing their own row (firestore.rules: current month only, own @name).
/// Months are UTC, so the whole world turns the page at once: "202611".
String monthKey(DateTime t) {
  final u = t.toUtc();
  return '${u.year * 100 + u.month}';
}

/// The month before [t]'s, as a key: whose reward can be collected.
String lastMonthKey(DateTime t) {
  final u = t.toUtc();
  return monthKey(DateTime.utc(u.year, u.month - 1));
}

/// The month's score: [collectionPoints] of the cards won in [t]'s UTC month.
int monthPoints(List<CardData> cards, DateTime t) {
  final m = monthKey(t);
  return collectionPoints([
    for (final c in cards)
      if (monthKey(c.earned) == m) c,
  ]);
}

/// The reward card's rarity for finishing [rank] of [total]: by top percentile.
String rankReward(int rank, int total) => switch (rank / total) {
  <= 0.01 => 'legendary',
  <= 0.05 => 'epic',
  <= 0.15 => 'rare',
  <= 0.40 => 'uncommon',
  _ => 'common',
};

/// One row of the ranking.
typedef RankRow = ({String uid, String name, int points});

final _db = FirebaseFirestore.instance;
String? get _uid => FirebaseAuth.instance.currentUser?.uid;
CollectionReference<Map<String, dynamic>> _month(String m) =>
    _db.collection('ranks').doc(m).collection('players');

String? _sent; // the last row written, to skip identical writes

/// Writes this player's row for the current month when it changed (with each backup and
/// when the ranking opens). No @name yet, no score, or the cloud off: nothing.
Future<void> saveRank(Store store) async {
  final uid = _uid, name = store.username;
  final now = DateTime.now();
  final points = monthPoints(store.cards, now);
  if (uid == null || name == null || store.cloudOff || points == 0) return;
  final row = '$uid|${monthKey(now)}|$name|$points';
  if (row == _sent) return;
  try {
    await _month(monthKey(now)).doc(uid).set({'name': name, 'points': points});
    _sent = row;
  } on Exception catch (e) {
    debugPrint('ranking: $e');
  }
}

/// The month's top 10, live.
Stream<List<RankRow>> watchTop(String month) =>
    _month(month)
        .orderBy('points', descending: true)
        .limit(10)
        .snapshots()
        .map(
          (q) => [
            for (final d in q.docs)
              (
                uid: d.id,
                name: d.data()['name'] as String? ?? '',
                points: d.data()['points'] as int? ?? 0,
              ),
          ],
        );

/// This player's place in [month] (ties share a rank) and how many players scored; null
/// if they have no row there.
Future<({int rank, int total, int points})?> myRank(String month) async {
  final uid = _uid;
  if (uid == null) return null;
  final points = (await _month(month).doc(uid).get()).data()?['points'] as int?;
  if (points == null) return null;
  final [above, total] = await Future.wait([
    _month(month).where('points', isGreaterThan: points).count().get(),
    _month(month).count().get(),
  ]);
  final rank = above.count! + 1;
  store.notePodium(rank, total.count!); // the Podium achievement
  return (rank: rank, total: total.count!, points: points);
}

/// Removes this player's row of the current month (account deletion).
Future<void> deleteRank(String uid) =>
    _month(monthKey(DateTime.now())).doc(uid).delete();
