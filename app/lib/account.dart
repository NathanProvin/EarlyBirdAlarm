import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'cards.dart';
import 'firebase_options.dart';
import 'store.dart';

/// Cloud backup (roadmap Phase 1.1): a silent anonymous Firebase account, the collection
/// mirrored to `players/{uid}` after each change, "Sign in with Google" to get it back on
/// another phone. Never awaited and never on an alarm's path: offline or failing, the app
/// works as before (Firestore queues the writes).
Future<void> signInQuietly(Store store) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null && !store.cloudOff) {
      await auth.signInAnonymously();
    }
    store.addListener(() => _backup(store));
    _backup(store);
  } on Exception catch (e) {
    debugPrint('account: $e');
  }
}

DocumentReference<Map<String, dynamic>> _doc(String uid) =>
    FirebaseFirestore.instance.collection('players').doc(uid);

String? _sent; // the last collection written, to skip changes outside it (alarms, theme…)

void _backup(Store store) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null || store.cloudOff) return;
  final data = store.backup;
  final json = '${user.uid} ${jsonEncode(data)}';
  if (json == _sent) return;
  _sent = json;
  // shortcut: one document (1 MB ≈ 4,000 cards); split per card when a player gets near.
  _doc(user.uid).set(data).catchError((Object e) {
    debugPrint('backup: $e');
    _sent = null;
  });
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
/// (same uid, its backup stays). If this Google account already has a collection (another
/// phone), the throwaway anonymous account is deleted and both collections are merged.
/// Throws when cancelled or offline.
Future<void> signInWithGoogle(Store store) async {
  final cred = await _googleCredential();
  final auth = FirebaseAuth.instance;
  final anon = auth.currentUser;
  if (anon != null && anon.isAnonymous) {
    try {
      await anon.linkWithCredential(cred);
      store.cloudOff = false; // notifies: the listener backs up
      return;
    } on FirebaseAuthException catch (e) {
      if (e.code != 'credential-already-in-use') rethrow;
    }
    await _doc(anon.uid).delete();
    await anon.delete();
  }
  final user = (await auth.signInWithCredential(cred)).user!;
  final remote = (await _doc(user.uid).get()).data() ?? const {};
  await store.restore(mergeBackups(store.backup, remote));
  store.cloudOff = false;
}

/// Deletes the cloud backup and the account (Play requirement). The cards stay on the
/// phone; no new account is made until the player signs in with Google again.
Future<void> deleteAccount(Store store) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  store.cloudOff = true;
  await _doc(user.uid).delete();
  try {
    await user.delete();
  } on FirebaseAuthException catch (e) {
    if (e.code != 'requires-recent-login') rethrow;
    await user.reauthenticateWithCredential(await _googleCredential());
    await user.delete();
  }
  if (_googleReady != null) await GoogleSignIn.instance.signOut();
}
