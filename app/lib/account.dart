import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'firebase_options.dart';

/// A silent anonymous Firebase account, the base for the cloud backup (roadmap Phase 1.1).
/// Never awaited and never on an alarm's path: offline or failing, the app works as before
/// and tries again at the next launch.
Future<void> signInQuietly() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) await auth.signInAnonymously();
  } on Exception catch (e) {
    debugPrint('account: $e');
  }
}
