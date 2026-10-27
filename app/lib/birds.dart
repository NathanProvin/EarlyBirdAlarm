import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

enum Difficulty { easy, medium, hard }

/// Rarity tiers, most common first, with how often each is picked to ring.
const _weight = {
  'common': 16,
  'uncommon': 8,
  'rare': 4,
  'epic': 2,
  'legendary': 1,
};
const tiers = ['common', 'uncommon', 'rare', 'epic', 'legendary'];
const _allowed = {
  Difficulty.easy: {'common', 'uncommon'},
  Difficulty.medium: {'common', 'uncommon', 'rare'},
  Difficulty.hard: {'common', 'uncommon', 'rare', 'epic', 'legendary'},
};

/// Card stats, in card order.
const statKeys = ['weight', 'wingspan', 'length', 'distance'];

class Bird {
  Bird.fromJson(Map<String, dynamic> j)
    : id = j['id'] as String,
      latin = j['latin'] as String,
      name = j['en'] as String,
      nameFr = j['fr'] as String,
      order = j['order'] as String,
      family = j['family'] as String,
      months = {
        for (final e in (j['months'] as Map<String, dynamic>).entries)
          int.parse(e.key): e.value as String,
      },
      audio = 'assets/content/${j['audio']}',
      photo = 'assets/content/${j['photo']}',
      audioCredit = j['audioCredit'] as String,
      photoCredit = j['photoCredit'] as String,
      rarity = j['rarity'] as String,
      number = j['number'] as int,
      stats = {
        for (final e in (j['stats'] as Map<String, dynamic>).entries)
          if (e.value != null)
            e.key: (
              mean: ((e.value as List)[0] as num).toDouble(),
              sd: ((e.value as List)[1] as num).toDouble(),
            ),
      };

  final String id,
      latin,
      name,
      nameFr,
      order,
      family,
      audio,
      photo,
      audioCredit,
      photoCredit,
      rarity; // card tier: the species' best monthly tier
  final int number; // card number, in taxonomic order
  final Map<String, ({double mean, double sd})> stats; // missing = unknown
  final Map<int, String> months; // month 1-12 -> tier; absent = not around

  String nameIn(String locale) => locale.startsWith('fr') ? nameFr : name;

  /// The tier in [month], or the most common tier of the year when [month] is null.
  String? tierIn(int? month) => month != null
      ? months[month]
      : _weight.keys.where(months.containsValue).firstOrNull;
}

late List<Bird> birds;

/// Reads the bundled catalog built by pipeline/build.py.
Future<void> loadBirds() async => birds = parseCatalog(
  await rootBundle.loadString('assets/content/catalog.json'),
);

List<Bird> parseCatalog(String json) => [
  for (final b in (jsonDecode(json) as Map<String, dynamic>)['birds'] as List)
    Bird.fromJson(b as Map<String, dynamic>),
];

Bird? birdById(String id) => birds.where((b) => b.id == id).firstOrNull;

/// Birds that can ring in [month] (null = any month) at [difficulty], with their pick weight.
/// Falls back to every bird so a ring always has one.
Map<Bird, int> pool(int? month, Difficulty difficulty) {
  final p = {
    for (final b in birds)
      if (_allowed[difficulty]!.contains(b.tierIn(month)))
        b: _weight[b.tierIn(month)]!,
  };
  return p.isNotEmpty ? p : {for (final b in birds) b: 1};
}

/// A weighted random bird for a ring, avoiding [recent] ids when possible.
Bird pickBird(
  List<String> recent,
  int? month,
  Difficulty difficulty, [
  Random? random,
]) {
  final all = pool(month, difficulty);
  final fresh = {...all}..removeWhere((b, _) => recent.contains(b.id));
  final p = fresh.isNotEmpty ? fresh : all;
  var r = (random ?? Random()).nextInt(p.values.reduce((a, b) => a + b));
  return p.entries.firstWhere((e) => (r -= e.value) < 0).key;
}

/// The answer plus 3 wrong birds from the same pool, shuffled. Wrong birds are from another
/// order (easy), the same order (medium) or the same family (hard); when a group runs short
/// the next easier group fills in.
List<Bird> choicesFor(
  Bird answer,
  int? month,
  Difficulty difficulty, [
  Random? random,
]) {
  var others = pool(month, difficulty).keys.where((b) => b != answer).toList();
  if (others.length < 3) others = birds.where((b) => b != answer).toList();
  bool sameFamily(Bird b) => b.family == answer.family;
  bool sameOrder(Bird b) => b.order == answer.order;
  final groups = switch (difficulty) {
    Difficulty.easy => [(Bird b) => !sameOrder(b)],
    Difficulty.medium => [sameOrder],
    Difficulty.hard => [sameFamily, sameOrder],
  };
  final wrong = <Bird>[];
  for (final g in [...groups, (Bird _) => true]) {
    wrong.addAll(
      (others.where((b) => g(b) && !wrong.contains(b)).toList()
            ..shuffle(random))
          .take(3 - wrong.length),
    );
  }
  return [...wrong, answer]..shuffle(random);
}
