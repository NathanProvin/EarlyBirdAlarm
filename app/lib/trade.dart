import 'birds.dart';
import 'cards.dart';

/// Trades with friends at a distance (2026-11-13; they replace the face-to-face trades
/// over Nearby, Android-only: recoverable from the git tag `face-to-face-trade`). One
/// trade per pair of friends in Firestore (remote_trade.dart, firestore.rules): each side
/// builds its own offer, validates both offers as they are (their hash), and once both
/// validated the same hash each phone applies the swap.
const maxTradeCards = 10; // per side

/// A trade not completed within this is cancelled (its cards unlocked).
const tradeExpiry = Duration(days: 7);

/// The trade document of two players: their uids sorted, so both find the same one.
String tradeId(String me, String friend) =>
    me.compareTo(friend) < 0 ? '${me}_$friend' : '${friend}_$me';

/// Both offers in one canonical string, the same on both phones: what a validation
/// refers to.
String offersHash(List<CardData> mine, List<CardData> theirs) {
  String keys(List<CardData> cards) =>
      (cards.map((c) => c.key).toList()..sort()).join(',');
  return ([keys(mine), keys(theirs)]..sort()).join('|');
}

/// A card offered by the other phone, or null if it can't be genuine: unknown bird or
/// rarity, quality outside 0–100, a stat the species doesn't have or out of the roll's
/// ±3 standard deviations, a date in the future.
CardData? checkCard(Object? json) {
  try {
    final card = CardData.fromJson(json! as Map<String, dynamic>);
    final bird = birdById(card.birdId);
    if (bird == null) return null;
    if (card.rarity != null && !cardTiers.contains(card.rarity)) return null;
    // A photo must be one of this bird's (a variant, or a Shiny one on a Shiny card).
    if (card.photo case final p?
        when bird.photoOf(p).photo != p ||
            (bird.photoOf(p).kind != null) != (card.rarity == 'shiny')) {
      return null;
    }
    if (card.quality < 0 || card.quality > 100) return null;
    if (card.earned.isAfter(DateTime.now().add(const Duration(days: 1)))) {
      return null;
    }
    for (final MapEntry(:key, :value) in card.stats.entries) {
      final s = bird.stats[key];
      if (s == null || !value.isFinite) return null;
      if (value < s.mean - 3 * s.sd - 1e-6 ||
          value > s.mean + 3 * s.sd + 1e-6) {
        return null;
      }
    }
    if (card.recording != null &&
        !bird.recordings.any((r) => r.file == card.recording)) {
      return null;
    }
    return card;
  } on Object {
    return null; // malformed JSON or types
  }
}

/// A trade as this player sees it, from its Firestore document `d` (see firestore.rules):
/// `a` and `b` the two uids, `aCards` / `bCards` the offers, `aOk` / `bOk` the hash each
/// validated, `aDone` / `bDone` whether each phone applied the swap.
class RemoteTrade {
  RemoteTrade(this.id, Map<String, dynamic> d, String me)
    : _me = d['a'] == me ? 'a' : 'b',
      _them = d['a'] == me ? 'b' : 'a',
      friend = (d['a'] == me ? d['b'] : d['a']) as String,
      created = d['created'] is DateTime ? d['created'] as DateTime : null,
      _d = d;
  final String id, friend;
  final DateTime? created; // null until the server stamped it
  final String _me, _them;
  final Map<String, dynamic> _d;

  List<CardData> _cards(String side, {bool check = false}) => [
    for (final j in _d['${side}Cards'] as List? ?? const [])
      ?(check
          ? checkCard(j)
          : CardData.fromJson((j as Map).cast<String, dynamic>())),
  ];

  /// This player's offer, as they wrote it.
  List<CardData> get mine => _cards(_me);

  /// The friend's offer, each card checked (a forged one is left out: see [forged]).
  List<CardData> get theirs => _cards(_them, check: true);

  /// The friend's offer holds a card that can't be genuine: the trade must be cancelled.
  bool get forged =>
      theirs.length != (_d['${_them}Cards'] as List? ?? const []).length;

  String get hash => offersHash(mine, theirs);
  String? get myOk => _d['${_me}Ok'] as String?;
  String? get theirOk => _d['${_them}Ok'] as String?;
  bool get myDone => _d['${_me}Done'] == true;
  bool get theirDone => _d['${_them}Done'] == true;

  /// Each side must offer at least one card (user, 2026-11-13).
  bool get bothOffer => mine.isNotEmpty && theirs.isNotEmpty;

  /// Both validated these very offers: the swap is on, the offers frozen.
  bool get swapping =>
      !forged && myOk != null && myOk == theirOk && myOk == hash;

  bool get iValidated => myOk == hash;
  bool get theyValidated => theirOk == hash;
  bool get canValidate => !forged && bothOffer && !iValidated && !swapping;

  /// Not completed within [tradeExpiry] (a swap in progress never expires).
  bool expired(DateTime now) =>
      !swapping && created != null && now.difference(created!) > tradeExpiry;

  /// Waiting for this player: the swap to apply here, or the friend validated, or the
  /// friend offered cards while this side has none yet.
  bool get needsMe =>
      (swapping && !myDone) ||
      (!swapping && theyValidated && !iValidated) ||
      (theirs.isNotEmpty && mine.isEmpty);
}

/// This player's cards offered in their open trades, except [except]: locked, they can't
/// go in another trade until theirs ends.
Set<String> lockedCards(Iterable<RemoteTrade> trades, {String? except}) => {
  for (final t in trades)
    if (t.id != except && !t.myDone)
      for (final c in t.mine) c.key,
};
