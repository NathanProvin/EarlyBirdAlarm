import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../account.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';

/// Settings → Account: Google sign-in for the cloud backup, and account deletion.
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() job, [String? done]) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await job();
      if (done != null) messenger.showSnackBar(SnackBar(content: Text(done)));
    } on GoogleSignInException catch (e) {
      if (e.code != GoogleSignInExceptionCode.canceled) {
        messenger.showSnackBar(SnackBar(content: Text(l.accountError)));
      }
    } on Exception catch (e) {
      debugPrint('account: $e');
      messenger.showSnackBar(SnackBar(content: Text(l.accountError)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.deleteAccount),
        content: Text(l.deleteAccountBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (ok == true) await _run(() => deleteAccount(store), l.accountDeleted);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.account)),
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.userChanges(),
        builder: (context, snap) {
          final user = snap.data;
          final google = user != null && !user.isAnonymous;
          return ListView(
            padding: EdgeInsets.fromLTRB(
              24,
              12,
              24,
              24 + MediaQuery.paddingOf(context).bottom,
            ),
            children: [
              Text(
                google ? l.accountSignedIn(user.email ?? '') : l.accountPitch,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              if (!google)
                FilledButton.icon(
                  icon: const Icon(Icons.login),
                  label: Text(l.signInGoogle),
                  onPressed: _busy
                      ? null
                      : () => _run(() => signInWithGoogle(store)),
                ),
              if (_busy) ...[
                const SizedBox(height: 16),
                const Center(child: CircularProgressIndicator()),
              ],
              if (user != null) ...[
                const SizedBox(height: 32),
                TextButton(
                  onPressed: _busy ? null : _delete,
                  child: Text(l.deleteAccount),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
