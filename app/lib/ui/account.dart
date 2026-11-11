import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../account.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';

/// The account page, opened from the person icon on the Alarms and Training headers.
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(AppLocalizations.of(context).account)),
    body: ListView(
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      children: const [AccountPanel(canDelete: true)],
    ),
  );
}

/// Signed in: the email with a cloud ✓ (and Delete account on the account page).
/// Otherwise: Google, or an email and password (sign in, create, forgot password).
/// Shared by the account page and the onboarding.
class AccountPanel extends StatefulWidget {
  const AccountPanel({this.canDelete = false, super.key});
  final bool canDelete;

  @override
  State<AccountPanel> createState() => _AccountPanelState();
}

class _AccountPanelState extends State<AccountPanel> {
  final _email = TextEditingController(), _password = TextEditingController();
  bool _busy = false;

  // No Firebase in widget tests (or if it failed to start): shown signed out.
  final Stream<User?> _user = Firebase.apps.isEmpty
      ? Stream.value(null)
      : FirebaseAuth.instance.userChanges();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() job, [String? done]) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    void say(String text) =>
        messenger.showSnackBar(SnackBar(content: Text(text)));
    setState(() => _busy = true);
    try {
      await job();
      if (done != null) say(done);
    } on GoogleSignInException catch (e) {
      if (e.code != GoogleSignInExceptionCode.canceled) say(l.accountError);
    } on FirebaseAuthException catch (e) {
      say(switch (e.code) {
        'invalid-credential' ||
        'wrong-password' ||
        'user-not-found' => l.wrongPassword,
        'email-already-in-use' || 'credential-already-in-use' => l.emailInUse,
        'weak-password' => l.weakPassword,
        'invalid-email' || 'missing-email' => l.invalidEmail,
        _ => l.accountError,
      });
    } on Exception catch (e) {
      debugPrint('account: $e');
      say(l.accountError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _askPassword() {
    final l = AppLocalizations.of(context);
    final field = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.password),
        content: TextField(
          controller: field,
          obscureText: true,
          autofocus: true,
          autofillHints: const [AutofillHints.password],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, field.text),
            child: Text(l.delete),
          ),
        ],
      ),
    ).whenComplete(field.dispose);
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
    if (ok == true) {
      await _run(() => deleteAccount(store, _askPassword), l.accountDeleted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    String email() => _email.text.trim();
    return StreamBuilder<User?>(
      stream: _user,
      builder: (context, snap) {
        final user = snap.data;
        if (user != null && !user.isAnonymous) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.cloud_done_outlined, color: scheme.primary),
                title: Text(user.email ?? ''),
              ),
              if (widget.canDelete) ...[
                const SizedBox(height: 24),
                TextButton(
                  onPressed: _busy ? null : _delete,
                  child: Text(l.deleteAccount),
                ),
              ],
            ],
          );
        }
        return AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.accountPitch, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                icon: const Icon(Icons.login),
                label: Text(l.signInGoogle),
                onPressed: _busy
                    ? null
                    : () => _run(() => signInWithGoogle(store)),
              ),
              const SizedBox(height: 16),
              Text(l.orEmail, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: InputDecoration(labelText: l.email),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _password,
                obscureText: true,
                autofillHints: const [AutofillHints.password],
                decoration: InputDecoration(labelText: l.password),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _busy
                          ? null
                          : () => _run(
                              () => createWithEmail(
                                store,
                                email(),
                                _password.text,
                              ),
                            ),
                      child: Text(l.createAccount),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: _busy
                          ? null
                          : () => _run(
                              () => signInWithEmail(
                                store,
                                email(),
                                _password.text,
                              ),
                            ),
                      child: Text(l.signIn),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => _run(
                        () => resetPassword(
                          email(),
                          Localizations.localeOf(context).languageCode,
                        ),
                        l.resetSent,
                      ),
                child: Text(l.forgotPassword),
              ),
              if (_busy) const Center(child: CircularProgressIndicator()),
            ],
          ),
        );
      },
    );
  }
}
