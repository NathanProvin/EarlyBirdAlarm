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
/// (same uid, its backup stays); if this Google account already has a collection (another
/// phone), both are merged. Throws when cancelled or offline.
Future<void> signInWithGoogle(Store store) async {
  final cred = await _googleCredential();
  final anon = FirebaseAuth.instance.currentUser;
  if (anon != null && anon.isAnonymous) {
    try {
      await anon.linkWithCredential(cred);
      store.cloudOff = false; // notifies: the listener backs up
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
  if (anon != null && anon.isAnonymous) await _doc(anon.uid).delete();
  final User user;
  try {
    user = (await auth.signInWithCredential(cred)).user!;
  } on Exception {
    _sent = null;
    _backup(store);
    rethrow;
  }
  final remote = (await _doc(user.uid).get()).data() ?? const {};
  await store.restore(mergeBackups(store.backup, remote));
  store.cloudOff = false;
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
    await _doc(user.uid)
        .delete(); // while signed in: the rules allow only the owner
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
  if (_googleReady != null) await GoogleSignIn.instance.signOut();
}

void _resume(Store store) {
  _sent = null;
  store.cloudOff = false; // notifies: the listener writes the backup again
}
