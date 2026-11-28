import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'cards.dart';
import 'main.dart' show store;
import 'profile.dart' show social;
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

/// The all-time board's key, beside the months (2026-11-27): every card's points.
const allTime = 'all';

/// The reward card's rarity for finishing a month at [rank]: the top 10 only (user,
/// 2026-11-27). shortcut: few players yet, back to percentiles when there are many.
String? rankReward(int rank) => switch (rank) {
  1 => 'legendary',
  2 => 'epic',
  3 => 'rare',
  4 || 5 => 'uncommon',
  <= 10 => 'common',
  _ => null,
};

/// One row of the ranking.
typedef RankRow = ({
  String uid,
  String name,
  int points,
  Map<String, dynamic>? avatar,
});

final _db = FirebaseFirestore.instance;
String? get _uid => FirebaseAuth.instance.currentUser?.uid;
CollectionReference<Map<String, dynamic>> _month(String m) =>
    _db.collection('ranks').doc(m).collection('players');

String? _sent; // the last row written, to skip identical writes

/// Writes this player's rows, the current month's and the all-time one, when they changed
/// (with each backup and when the ranking opens). No @name yet or the cloud off: nothing;
/// a board without points: no row there.
Future<void> saveRank(Store store) async {
  final uid = _uid, name = store.username;
  if (uid == null || name == null || store.cloudOff) return;
  final now = DateTime.now();
  final avatar = store.avatar;
  final boards = {
    monthKey(now): monthPoints(store.cards, now),
    allTime: collectionPoints(store.cards),
  }..removeWhere((_, p) => p == 0);
  final row = '$uid|$name|$boards|$avatar';
  if (boards.isEmpty || row == _sent) return;
  try {
    await Future.wait([
      for (final MapEntry(key: board, value: points) in boards.entries)
        _month(board)
            .doc(uid)
            .set({'name': name, 'points': points, 'avatar': ?avatar}),
    ]);
    _sent = row;
  } on Exception catch (e) {
    debugPrint('ranking: $e');
  }
}

final _avatars = <String, Future<Map<String, dynamic>?>>{};

/// A player's avatar from their profile, once per session: rows written before 1.4.0
/// carry none.
Future<Map<String, dynamic>?> profileAvatar(String uid) => _avatars[uid] ??= _db
    .collection('profiles')
    .doc(uid)
    .get()
    .then<Map<String, dynamic>?>(
      (d) => d.data()?['avatar'] as Map<String, dynamic>?,
      onError: (Object _) => null,
    );

/// A board's top 10 (a month's, or [allTime]), live.
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
                avatar: d.data()['avatar'] as Map<String, dynamic>?,
              ),
          ],
        );

/// The all-time board among this player and their friends (2026-11-28), best first: the
/// names and avatars their profiles show now, 0 points for a friend with no row there.
Future<List<RankRow>> friendsBoard() async {
  final uid = _uid;
  if (uid == null) return const [];
  final friends = (await social(store)).friends;
  final players = [
    (uid: uid, name: store.username ?? '', avatar: store.avatar),
    for (final f in friends) (uid: f.uid, name: f.name, avatar: f.avatar),
  ];
  final docs = await Future.wait([
    for (final p in players) _month(allTime).doc(p.uid).get(),
  ]);
  return [
    for (final (i, p) in players.indexed)
      (
        uid: p.uid,
        name: p.name,
        points: docs[i].data()?['points'] as int? ?? 0,
        avatar: p.avatar,
      ),
  ]..sort((a, b) => b.points.compareTo(a.points));
}

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
  // The Podium achievement counts months only.
  if (month != allTime) store.notePodium(rank, total.count!);
  return (rank: rank, total: total.count!, points: points);
}
