import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'birds.dart';
import 'cards.dart';
import 'names.dart';
import 'store.dart';

/// The profile page's cloud side (2026-11-13): the @name (`usernames/{lower}`), what
/// other players see (`profiles/{uid}`), friend requests (`friendRequests/{to}_{from}`)
/// and friends (`friends/{uid}/list/{friend}`). See firestore.rules.

FirebaseFirestore get _db => FirebaseFirestore.instance;
String? get _uid => FirebaseAuth.instance.currentUser?.uid;

DocumentReference<Map<String, dynamic>> _name(String name) =>
    _db.collection('usernames').doc(name.toLowerCase());
DocumentReference<Map<String, dynamic>> _profile(String uid) =>
    _db.collection('profiles').doc(uid);
CollectionReference<Map<String, dynamic>> _friends(String uid) =>
    _db.collection('friends').doc(uid).collection('list');
DocumentReference<Map<String, dynamic>> _request(String to, String from) =>
    _db.collection('friendRequests').doc('${to}_$from');

/// Another player as their profile shows them.
class PlayerProfile {
  PlayerProfile(this.uid, Map<String, dynamic> j)
    : name = j['name'] as String? ?? '',
      avatar = (j['avatar'] as Map?)?.cast<String, dynamic>(),
      hall = [
        for (final c in j['hall'] as List? ?? const [])
          if (c is Map) CardData.fromJson(c.cast<String, dynamic>()),
      ];
  final String uid;
  final String name;
  final Map<String, dynamic>? avatar;
  final List<CardData> hall;
}

/// The cards of the hall of fame, in slot order (an empty slot or a card gone: null).
List<CardData?> hallCards(Store store) => [
  for (final key in store.hall)
    store.cards.where((c) => c.key == key).firstOrNull,
];

/// Writes what other players see: the @name, the avatar, the hall of fame.
Future<void> saveProfile(Store store) async {
  final uid = _uid, name = store.username;
  if (uid == null || name == null) return;
  await _profile(uid).set({
    'name': name,
    'avatar': store.avatar ?? const <String, dynamic>{},
    'hall': [
      for (final c in hallCards(store))
        if (c != null) c.toJson(),
    ],
  });
}

/// The player's profile at launch: read back from the cloud (another phone, a restore),
/// else a new automatic @name. Never awaited; offline it tries again next launch.
Future<void> ensureProfile(Store store) async {
  final uid = _uid;
  if (uid == null || store.username != null) return;
  try {
    final mine = (await _profile(uid).get()).data();
    if (mine != null) {
      final p = PlayerProfile(uid, mine);
      store.avatar = p.avatar;
      store.hall = [
        for (var i = 0; i < 3; i++) i < p.hall.length ? p.hall[i].key : '',
      ];
      store.username = p.name;
      return;
    }
    for (var i = 0; i < 5; i++) {
      final name = autoName(birds);
      if (await _claim(uid, name, null)) {
        store.username = name;
        await saveProfile(store);
        return;
      }
    }
  } on Exception catch (e) {
    debugPrint('profile: $e');
  }
}

/// Takes [name] (and frees [old]) in one batch; false when someone holds it already
/// (the rules refuse the write: an existing document can't be created again).
Future<bool> _claim(String uid, String name, String? old) async {
  final batch = _db.batch()..set(_name(name), {'uid': uid});
  if (old != null && old.toLowerCase() != name.toLowerCase()) {
    batch.delete(_name(old));
  }
  try {
    await batch.commit();
    return true;
  } on FirebaseException catch (e) {
    if (e.code == 'permission-denied') return false;
    rethrow;
  }
}

enum RenameError { invalid, tooSoon, taken, offline }

class RenameException implements Exception {
  const RenameException(this.error, [this.problem]);
  final RenameError error;
  final NameProblem? problem;
}

/// When the player may rename next (null: now). The change from the automatic name is
/// free, then one a week.
DateTime? nextRename(Store store) => switch (store.renamedAt) {
  final t? when DateTime.now().isBefore(t.add(renameEvery)) => t.add(
    renameEvery,
  ),
  _ => null,
};

/// The player picks a new @name. Throws [RenameException].
Future<void> rename(Store store, String name) async {
  final uid = _uid;
  if (uid == null) throw const RenameException(RenameError.offline);
  if (nameProblem(name) case final p?) {
    throw RenameException(RenameError.invalid, p);
  }
  if (nextRename(store) != null) {
    throw const RenameException(RenameError.tooSoon);
  }
  final bool ok;
  try {
    ok = await _claim(uid, name, store.username);
  } on FirebaseException {
    throw const RenameException(RenameError.offline);
  }
  if (!ok) throw const RenameException(RenameError.taken);
  store.username = name;
  store.renamedAt = DateTime.now();
  await saveProfile(store);
}

enum FriendError { notFound, self, already, offline }

class FriendException implements Exception {
  const FriendException(this.error);
  final FriendError error;
}

/// Sends a friend request to @[name]. Throws [FriendException].
Future<void> sendRequest(String name) async {
  final uid = _uid;
  if (uid == null) throw const FriendException(FriendError.offline);
  final clean = name.trim().replaceFirst('@', '');
  if (nameProblem(clean) == NameProblem.length ||
      nameProblem(clean) == NameProblem.characters) {
    throw const FriendException(FriendError.notFound);
  }
  try {
    final to = (await _name(clean).get()).data()?['uid'] as String?;
    if (to == null) throw const FriendException(FriendError.notFound);
    if (to == uid) throw const FriendException(FriendError.self);
    if ((await _friends(uid).doc(to).get()).exists) {
      throw const FriendException(FriendError.already);
    }
    await _request(
      to,
      uid,
    ).set({'from': uid, 'to': to, 'at': FieldValue.serverTimestamp()});
  } on FirebaseException {
    throw const FriendException(FriendError.offline);
  }
}

Future<List<PlayerProfile>> _profiles(Iterable<String> uids) async => [
  for (final p in await Future.wait(uids.map((u) => _profile(u).get())))
    if (p.data() case final d?) PlayerProfile(p.id, d),
];

/// Who asked to be this player's friend (blocked players left out), and their friends.
Future<({List<PlayerProfile> requests, List<PlayerProfile> friends})> social(
  Store store,
) async {
  final uid = _uid;
  if (uid == null) {
    return (requests: <PlayerProfile>[], friends: <PlayerProfile>[]);
  }
  final asked = await _db
      .collection('friendRequests')
      .where('to', isEqualTo: uid)
      .get();
  final friends = await _friends(uid).get();
  final blocked = store.blocked;
  final requests = await _profiles([
    for (final r in asked.docs)
      if (r.data()['from'] case final String from when !blocked.contains(from))
        from,
  ]);
  return (
    requests: requests,
    friends: await _profiles([for (final f in friends.docs) f.id]),
  );
}

/// Accepts [from]'s request: both friend entries and the request's removal, in one batch.
Future<void> accept(String from) async {
  final uid = _uid!;
  await (_db.batch()
        ..set(_friends(uid).doc(from), {})
        ..set(_friends(from).doc(uid), {})
        ..delete(_request(uid, from)))
      .commit();
}

Future<void> decline(String from) => _request(_uid!, from).delete();

/// Ends a friendship, on both sides.
Future<void> removeFriend(String friend) async {
  final uid = _uid!;
  await (_db.batch()
        ..delete(_friends(uid).doc(friend))
        ..delete(_friends(friend).doc(uid)))
      .commit();
}

/// Hides [other] for good: their request is declined and the friendship ended.
Future<void> block(Store store, String other) async {
  store.blocked = {...store.blocked, other};
  final uid = _uid;
  if (uid == null) return;
  // Apart: deleting a request that doesn't exist is refused (the rule reads it).
  for (final job in [
    () => _request(uid, other).delete(),
    () =>
        (_db.batch()
              ..delete(_friends(uid).doc(other))
              ..delete(_friends(other).doc(uid)))
            .commit(),
  ]) {
    try {
      await job();
    } on FirebaseException catch (e) {
      debugPrint('profile: $e'); // blocked on the phone anyway
    }
  }
}

/// Removes everything social of [uid] (account deletion, or the anonymous account left
/// at a sign-in): profile, @name, friendships on both sides, requests both ways.
Future<void> deleteSocial(String uid, String? name) async {
  final friends = await _friends(uid).get();
  final asked = await _db
      .collection('friendRequests')
      .where('to', isEqualTo: uid)
      .get();
  final sent = await _db
      .collection('friendRequests')
      .where('from', isEqualTo: uid)
      .get();
  final batch = _db.batch();
  for (final f in friends.docs) {
    batch
      ..delete(f.reference)
      ..delete(_friends(f.id).doc(uid));
  }
  for (final r in [...asked.docs, ...sent.docs]) {
    batch.delete(r.reference);
  }
  batch.delete(_profile(uid));
  await batch.commit();
  // Apart: a name already freed would make the whole batch fail (the rule reads it).
  if (name != null) {
    try {
      await _name(name).delete();
    } on FirebaseException catch (e) {
      debugPrint('profile: $e');
    }
  }
}
