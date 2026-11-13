import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'birds.dart';
import 'cards.dart';
import 'firebase_options.dart';
import 'profile.dart';
import 'remote_trade.dart';
import 'store.dart';

/// Cloud backup (roadmap Phase 1.1): a silent anonymous Firebase account, the collection
/// mirrored to Firestore, "Sign in with Google" (or an email) to get it back on another
/// phone. Never awaited and never on an alarm's path: offline or failing, the app works
/// as before (Firestore queues the writes).
///
/// Layout (2026-11-11): `players/{uid}` holds everything but the cards, plus how many
/// card chunks there are; `players/{uid}/cards/{n}` hold the cards, [chunkCards] each
/// (~320 KB: a Firestore document stops at 1 MB, which one document for all reached
/// after ~3,250 cards). Writes are batched: at most every [backupEvery], and when the
/// app goes to the background; only the documents that changed are sent (the free plan
/// allows 20,000 writes a day for all players).
Future<void> signInQuietly(Store store) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null && !store.cloudOff) {
      await auth.signInAnonymously();
    }
    if (auth.currentUser case final user?) {
      unawaited(_readReferrer(store, user.uid));
      unawaited(friendsJoined(store).catchError((_) => store.friends));
      unawaited(ensureProfile(store));
      unawaited(sweepTrades(store));
    }
    store.addListener(() => _backupSoon(store));
    // The binding keeps the listener: written when the app goes to the background.
    AppLifecycleListener(
      onPause: () => unawaited(_flush(store)),
      onDetach: () => unawaited(_flush(store)),
    );
    unawaited(_flush(store));
  } on Exception catch (e) {
    debugPrint('account: $e');
  }
}

DocumentReference<Map<String, dynamic>> _doc(String uid) =>
    FirebaseFirestore.instance.collection('players').doc(uid);

CollectionReference<Map<String, dynamic>> _chunks(String uid) =>
    _doc(uid).collection('cards');

/// Cards per chunk document: 1,000 × ~322 bytes measured ≈ 320 KB, a third of the limit.
const chunkCards = 1000;

/// The longest a collection change waits before it is written.
const backupEvery = Duration(minutes: 5);

/// The cards (a JSON list, as saved) cut into chunks of [chunkCards], oldest first.
List<String> splitCards(String cards) {
  final list = jsonDecode(cards) as List;
  return [
    for (var i = 0; i < list.length; i += chunkCards)
      jsonEncode(list.sublist(i, min(i + chunkCards, list.length))),
  ];
}

/// The chunks back as one JSON list of cards.
String joinCards(List<String> chunks) =>
    jsonEncode([for (final c in chunks) ...jsonDecode(c) as List]);

// What was last written, to send only what changed (null / empty: write everything).
String? _sentUid, _sentMain;
var _sentChunks = <String>[];
Timer? _timer;

void _forget() {
  _sentMain = null;
  _sentChunks = [];
}

/// A collection change: written within [backupEvery] (a change outside the collection,
/// alarms or theme, sends nothing: see [_flush]).
void _backupSoon(Store store) {
  if (_timer?.isActive ?? false) return;
  _timer = Timer(backupEvery, () => unawaited(_flush(store)));
}

/// Writes the documents that changed since the last write, in one batch.
Future<void> _flush(Store store) async {
  _timer?.cancel();
  final user = FirebaseAuth.instance.currentUser;
  if (user == null || store.cloudOff) return;
  if (user.uid != _sentUid) {
    _sentUid = user.uid;
    _forget();
  }
  final data = Map.of(store.backup);
  final chunks = splitCards(data.remove('cards')! as String);
  final main = {...data, 'chunks': chunks.length};
  final mainJson = jsonEncode(main);
  final batch = FirebaseFirestore.instance.batch();
  var writes = 0;
  // First write since the app started: how many chunks the cloud has is unknown, so the
  // extra ones (a collection that shrank: a trade, a restore) are found and deleted.
  if (_sentMain == null) {
    try {
      for (final c in (await _chunks(user.uid).get()).docs) {
        if ((int.tryParse(c.id) ?? 0) >= chunks.length) {
          batch.delete(c.reference);
          writes++;
        }
      }
    } on Exception catch (e) {
      debugPrint('backup: $e'); // offline: the next launch tries again
    }
  }
  if (mainJson != _sentMain) {
    batch.set(
      _doc(user.uid),
      main,
    ); // replaces a pre-chunk document's 'cards' too
    writes++;
  }
  for (var i = 0; i < chunks.length; i++) {
    if (i < _sentChunks.length && chunks[i] == _sentChunks[i]) continue;
    batch.set(_chunks(user.uid).doc('$i'), {'cards': chunks[i]});
    writes++;
  }
  for (var i = chunks.length; i < _sentChunks.length; i++) {
    batch.delete(_chunks(user.uid).doc('$i')); // fewer cards after a trade
    writes++;
  }
  if (writes == 0) return;
  if (devTools) {
    // Dev builds: what each batch sends, to check the chunks on a phone.
    debugPrint(
      'backup: $writes writes, ${chunks.length} chunks '
      '(${[for (var i = 0; i < chunks.length; i++)
        if (i >= _sentChunks.length || chunks[i] != _sentChunks[i]) i]} changed)',
    );
  }
  _sentMain = mainJson;
  _sentChunks = chunks;
  try {
    await batch.commit();
  } on Exception catch (e) {
    debugPrint('backup: $e');
    _forget(); // everything is sent again next time
  }
}

/// A player's backup in [Store.backup]'s shape, from the chunks or from a document
/// written before them (its 'cards' field).
Future<Map<String, Object?>> _readBackup(String uid) async {
  final main = (await _doc(uid).get()).data();
  if (main == null) return const {};
  if (main['cards'] is String) return main;
  final chunks = (await _chunks(uid).get()).docs
    ..sort((a, b) => int.parse(a.id).compareTo(int.parse(b.id)));
  return {
    ...main,
    'cards': joinCards([
      for (final c in chunks.take(main['chunks'] as int? ?? 0))
        c.data()['cards'] as String,
    ]),
  };
}

/// Deletes a player's backup, chunks first (the rules allow only its owner).
Future<void> _deleteBackup(String uid) async {
  for (final c in (await _chunks(uid).get()).docs) {
    await c.reference.delete();
  }
  await _doc(uid).delete();
}

/// Two backups as one: every card of both (a card given away in a trade stays given),
/// heard birds not won since, every collected series, the higher counters.
Map<String, Object?> mergeBackups(
  Map<String, Object?> a,
  Map<String, Object?> b,
) {
  List<CardData> cardsOf(Map<String, Object?> m, String k) => [
    for (final j in jsonDecode(m[k] as String? ?? '[]') as List)
      CardData.fromJson(j as Map<String, dynamic>),
  ];
  final given = {
    for (final c in [...cardsOf(a, 'given'), ...cardsOf(b, 'given')]) c.key: c,
  };
  final cards = {
    for (final c in [...cardsOf(a, 'cards'), ...cardsOf(b, 'cards')])
      if (!given.containsKey(c.key)) c.key: c,
  };
  final won = {
    for (final c in [...cards.values, ...given.values]) c.birdId,
  };
  Set<String> union(String k) => {
    for (final m in [a, b]) ...(m[k] as List? ?? const []).cast<String>(),
  };
  return {
    'cards': jsonEncode(cards.values.toList()),
    'given': jsonEncode(given.values.toList()),
    'heard': union('heard').difference(won).toList(),
    'seriesDone': union('seriesDone').toList(),
    'blocked': union('blocked').toList(),
    for (final k in [
      'streak',
      'bestStreak',
      'alarmStreak',
      'bestAlarmStreak',
      'twitchBonus',
    ])
      k: max(a[k] as int? ?? 0, b[k] as int? ?? 0),
  };
}

Future<void>? _googleReady;

Future<AuthCredential> _googleCredential() async {
  // The web client id comes from google-services.json (default_web_client_id).
  await (_googleReady ??= GoogleSignIn.instance.initialize());
  final account = await GoogleSignIn.instance.authenticate();
  return GoogleAuthProvider.credential(idToken: account.authentication.idToken);
}

/// "Sign in with Google". The first time, the anonymous account becomes the Google one
/// (same uid, its backup stays); if this Google account already has a collection (another
/// phone), both are merged. Throws when cancelled or offline.
Future<void> signInWithGoogle(Store store) async {
  final cred = await _googleCredential();
  final anon = FirebaseAuth.instance.currentUser;
  if (anon != null && anon.isAnonymous) {
    try {
      await anon.linkWithCredential(cred);
      store.cloudOff = false;
      await _flush(store);
      return;
    } on FirebaseAuthException catch (e) {
      if (e.code != 'credential-already-in-use') rethrow;
    }
  }
  await _signInTo(store, cred);
}

/// "Create account" with an email: the anonymous account becomes it (same uid, its backup
/// stays). Throws FirebaseAuthException (email-already-in-use, weak-password, invalid-email…).
// shortcut: the email is not verified; add sendEmailVerification if fake addresses matter.
Future<void> createWithEmail(Store store, String email, String password) async {
  final auth = FirebaseAuth.instance;
  final anon = auth.currentUser;
  if (anon != null && anon.isAnonymous) {
    await anon.linkWithCredential(
      EmailAuthProvider.credential(email: email, password: password),
    );
  } else {
    await auth.createUserWithEmailAndPassword(email: email, password: password);
  }
  store.cloudOff = false;
}

/// "Sign in" with an existing email account: its collection merges with the phone's.
Future<void> signInWithEmail(Store store, String email, String password) =>
    _signInTo(
      store,
      EmailAuthProvider.credential(email: email, password: password),
    );

/// Firebase sends the reset link itself (in the app's language).
Future<void> resetPassword(String email, String language) {
  FirebaseAuth.instance.setLanguageCode(language);
  return FirebaseAuth.instance.sendPasswordResetEmail(email: email);
}

/// Signs in to an account that already exists and merges its backup with the phone's.
/// The anonymous account's backup is deleted first and rewritten if the sign-in fails.
// shortcut: the emptied anonymous account stays in Firebase Auth (no data); turn on
// automatic clean-up of anonymous accounts if they pile up.
Future<void> _signInTo(Store store, AuthCredential cred) async {
  final auth = FirebaseAuth.instance;
  final anon = auth.currentUser;
  if (anon != null && anon.isAnonymous) {
    // The anonymous account's @name and profile go: the account signed in keeps its own.
    // shortcut: its friends aren't carried over; merge them if anonymous players befriend.
    try {
      await deleteSocial(anon.uid, store.username);
    } on Exception catch (e) {
      debugPrint('profile: $e');
    }
    store.username = null;
    await _deleteBackup(anon.uid);
  }
  final User user;
  try {
    user = (await auth.signInWithCredential(cred)).user!;
  } on Exception {
    _forget();
    await _flush(store); // the anonymous backup written back
    rethrow;
  }
  final remote = await _readBackup(user.uid);
  await store.restore(mergeBackups(store.backup, remote));
  store.cloudOff = false;
  await _flush(store); // the merged collection, at once
  await ensureProfile(store); // the account's own profile, or a new name
}

/// Deletes the cloud backup and the account (Play requirement). The cards stay on the
/// phone; no new account is made until the player signs in again. An account signed in
/// long ago signs in again first: Google, or its password ([askPassword]; null cancels).
/// On cancel or failure the account stays and its backup is written back.
Future<void> deleteAccount(
  Store store,
  Future<String?> Function() askPassword,
) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  store.cloudOff = true; // no backup while deleting
  try {
    _timer?.cancel();
    // Who invited this player goes too (the inviter's count drops by one), and their
    // profile, @name and friendships.
    await FirebaseFirestore.instance
        .collection('referrals')
        .doc(user.uid)
        .delete();
    await deleteSocial(user.uid, store.username);
    await _deleteBackup(
      user.uid,
    ); // while signed in: the rules allow only the owner
    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code != 'requires-recent-login') rethrow;
      final email = user.email;
      final AuthCredential cred;
      if (email != null &&
          user.providerData.any((p) => p.providerId == 'password')) {
        final password = await askPassword();
        if (password == null) return _resume(store);
        cred = EmailAuthProvider.credential(email: email, password: password);
      } else {
        cred = await _googleCredential();
      }
      await user.reauthenticateWithCredential(cred);
      await user.delete();
    }
  } on Exception {
    _resume(store);
    rethrow;
  }
  store.username = null; // the profile and @name are gone with the account
  if (_googleReady != null) await GoogleSignIn.instance.signOut();
}

void _resume(Store store) {
  _forget();
  store.cloudOff = false;
  unawaited(_flush(store)); // the backup written back
  // The profile may already be deleted: read again, or a new automatic @name.
  store.username = null;
  unawaited(ensureProfile(store));
}

const _referrer = MethodChannel('early_bird/referrer'); // MainActivity

/// Invite links (2026-11-12): the Play link's referrer carries the inviter's account id
/// (`inviter=`, see `playLink`), read from Google Play once: the friend's referral is
/// written (the inviter counts it) and their welcome card waits for them (main.dart).
/// Tried again at the next launch while the referral couldn't be written (offline).
Future<void> _readReferrer(Store store, String uid) async {
  if (store.referrerDone) return;
  String? inviter;
  try {
    final referrer = await _referrer
        .invokeMethod<String>('get')
        .timeout(const Duration(seconds: 10));
    inviter = Uri.splitQueryString(referrer ?? '')['inviter'];
  } on Exception catch (e) {
    debugPrint(
      'referrer: $e',
    ); // not installed from Play (dev builds): no invite
  }
  if (inviter == null || inviter == uid) {
    store.referrerDone = true;
    return;
  }
  store.invitedBy ??= inviter;
  try {
    await FirebaseFirestore.instance.collection('referrals').doc(uid).set({
      'inviterUid': inviter,
    });
    store.referrerDone = true;
  } on FirebaseException catch (e) {
    // Already written (create-only): a write queued offline went through.
    if (e.code == 'permission-denied') store.referrerDone = true;
    debugPrint('referrer: $e');
  }
}

/// How many friends installed the app through this player's invite links; kept in
/// [Store.friends] for the Influencer achievement.
Future<int> friendsJoined(Store store) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return store.friends;
  final q = await FirebaseFirestore.instance
      .collection('referrals')
      .where('inviterUid', isEqualTo: uid)
      .count()
      .get();
  return store.friends = q.count ?? 0;
}

enum CodeError { unknown, expired, used, offline }

class CodeException implements Exception {
  const CodeException(this.error);
  final CodeError error;
}

/// Redeems a code we handed out (2026-11-12): case-insensitive (stored in lower case),
/// once per account, enforced by the rules with a create-only `redemptions/{uid}_{code}`.
/// Its `reward` is a card tier ('shiny': a Shiny of the region, else a Legendary) or
/// 'none'. Returns the card won (null for 'none'); throws [CodeException].
Future<CardData?> redeemCode(Store store, String word) async {
  final user = FirebaseAuth.instance.currentUser;
  final id = word.trim().toLowerCase();
  if (user == null) throw const CodeException(CodeError.offline);
  if (id.isEmpty || id.contains('/')) {
    throw const CodeException(CodeError.unknown);
  }
  final db = FirebaseFirestore.instance;
  final Map<String, dynamic>? code;
  try {
    code =
        (await db
                .collection('codes')
                .doc(id)
                .get(const GetOptions(source: Source.server)))
            .data();
  } on FirebaseException {
    throw const CodeException(CodeError.offline);
  }
  if (code == null || code['active'] != true) {
    throw const CodeException(CodeError.unknown);
  }
  if (code['end'] case final Timestamp end
      when end.toDate().isBefore(DateTime.now())) {
    throw const CodeException(CodeError.expired);
  }
  try {
    await db.collection('redemptions').doc('${user.uid}_$id').set({
      'uid': user.uid,
      'code': id,
    });
  } on FirebaseException catch (e) {
    throw CodeException(
      e.code == 'permission-denied' ? CodeError.used : CodeError.offline,
    );
  }
  final reward = code['reward'] as String? ?? 'none';
  return cardTiers.contains(reward) ? store.gift(reward) : null;
}
