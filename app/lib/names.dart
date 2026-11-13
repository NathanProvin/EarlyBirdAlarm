import 'dart:math';

import 'birds.dart';

/// Player @names (profile page, 2026-11-13): 3-20 letters, digits or `_`, unique without
/// regard to case (Firestore `usernames/{lower}`), renamed at most once a week.

/// Why [name] can't be used, or null when it can.
enum NameProblem { length, characters, banned }

NameProblem? nameProblem(String name) {
  if (name.length < 3 || name.length > 20) return NameProblem.length;
  if (!RegExp(r'^[A-Za-z0-9_]+$').hasMatch(name)) return NameProblem.characters;
  final plain = name.toLowerCase().replaceAll('_', '');
  if (bannedNames.any(plain.contains)) return NameProblem.banned;
  return null;
}

/// A first name for a new account: a bird's English name without spaces and 4 digits,
/// e.g. RedRobin4821 (the player can change it once for free).
String autoName(Iterable<Bird> pool, [Random? random]) {
  random ??= Random();
  final camel = [
    for (final b in pool)
      b.name
          .split(RegExp(r'[^A-Za-z]+'))
          .where((w) => w.isNotEmpty)
          .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
          .join(),
  ];
  bool ok(String n) => n.length >= 3 && nameProblem(n) == null; // Dickcissel…
  // Names that fit whole (16 + 4 digits = 20) first: "SpottedFlycatche" reads badly.
  final whole = camel.where((n) => n.length <= 16 && ok(n)).toList();
  final from = whole.isNotEmpty
      ? whole
      : camel.map((n) => n.substring(0, min(n.length, 16))).where(ok).toList();
  final bird = from.isEmpty ? 'Bird' : from[random.nextInt(from.length)];
  final digits = random.nextInt(10000).toString().padLeft(4, '0');
  return '$bird$digits';
}

/// How long after a rename the next one waits (the first change is free).
const renameEvery = Duration(days: 7);

/// Refused anywhere inside a name (lower case, without `_`). A starter list drafted
/// 2026-11-13: reserved names, then insults and slurs in EN / FR / DE / ES.
// shortcut: substring matching, no leetspeak or accents; Report and Block handle the
// rest. TO REVIEW by the user before the release.
const bannedNames = [
  // Reserved: could pass for the app or its staff.
  'admin', 'earlybird', 'support', 'moderat', 'official', 'staff', 'system',
  // English
  'fuck',
  'shit',
  'bitch',
  'cunt',
  'dick',
  'pussy',
  'whore',
  'slut',
  'nigg',
  'fag',
  'retard', 'rape', 'nazi', 'hitler', 'porn',
  // French
  'merde',
  'putain',
  'pute',
  'salope',
  'connard',
  'connasse',
  'encule',
  'batard',
  'pede', 'negro', 'bougnoul',
  // German
  'scheiss', 'arschloch', 'fotze', 'hure', 'wichser', 'schwuchtel', 'neger',
  // Spanish
  'mierda', 'puta', 'cabron', 'gilipollas', 'maricon', 'coño', 'pendejo',
];
