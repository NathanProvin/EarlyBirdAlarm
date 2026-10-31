import 'birds.dart';
import 'cards.dart';

/// Face-to-face trades (decided 2026-10-31): two phones connect directly, each side
/// offers cards, and the swap happens only once both have validated exactly what is
/// shown. No server: the transport (Nearby Connections, see ui/trade.dart) only carries
/// the JSON messages of [TradeSession].
const tradeProtocol =
    1; // bumped when the messages change: older apps refuse to trade
const maxTradeCards = 10; // per side

/// Why a trade ended without a swap.
enum TradeError { version, invalid, cancelled }

/// The two bird names both phones show while pairing, from Nearby's pairing token (the
/// same string on both): if the two birders see the same names, they're connected to
/// each other. [birds] must be the same sorted list on both phones (the bundled birds).
(String, String) pairingBirds(String token, List<String> birds) {
  var h = 17;
  for (final c in token.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  final n = birds.length;
  final i = h % n;
  var j = (h ~/ n) % (n - 1);
  if (j >= i) j++;
  return (birds[i], birds[j]);
}

/// A card offered by the other phone, or null if it can't be genuine: unknown bird or
/// rarity, quality outside 0–100, a stat the species doesn't have or out of the roll's
/// ±3 standard deviations, a date in the future.
CardData? checkCard(Object? json) {
  try {
    final card = CardData.fromJson(json! as Map<String, dynamic>);
    final bird = birdById(card.birdId);
    if (bird == null) return null;
    if (card.rarity != null && !tiers.contains(card.rarity)) return null;
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

/// One trade between this phone and the other. Messages, as JSON maps:
/// `hello{v}` (protocol version), `offer{cards}` (the full offer, after each change),
/// `ok{hash}` (validates both offers as they are), `commit{hash}` (both validations seen).
/// The swap is applied when this phone has sent its commit and received the other's.
class TradeSession {
  TradeSession({required this.send, required this.onChange});

  final void Function(Map<String, Object?> message) send;
  final void Function() onChange;

  List<CardData> mine = [], theirs = [];
  bool iValidated = false, theyValidated = false;
  bool _committed = false, _theyCommitted = false;
  bool done = false; // the swap happened: apply mine → theirs once
  TradeError? error;

  bool get ended => done || error != null;

  /// Both offers in one canonical string, the same on both phones: what a validation
  /// refers to.
  String get hash {
    String keys(List<CardData> cards) =>
        (cards.map((c) => c.key).toList()..sort()).join(',');
    return ([keys(mine), keys(theirs)]..sort()).join('|');
  }

  bool get canValidate =>
      !ended && !iValidated && (mine.isNotEmpty || theirs.isNotEmpty);

  void start() => send({'t': 'hello', 'v': tradeProtocol});

  void offer(List<CardData> cards) {
    if (ended || _committed) return;
    mine = cards.take(maxTradeCards).toList();
    iValidated = theyValidated = false;
    send({
      't': 'offer',
      'cards': [for (final c in mine) c.toJson()],
    });
    onChange();
  }

  void validate() {
    if (!canValidate) return;
    iValidated = true;
    send({'t': 'ok', 'hash': hash});
    _maybeCommit();
    onChange();
  }

  /// Ends the trade without a swap (the other side left or misbehaved).
  void cancel([TradeError why = TradeError.cancelled]) {
    if (ended) return;
    error = why;
    onChange();
  }

  void receive(Map<String, Object?> m) {
    if (ended) return;
    switch (m['t']) {
      case 'hello':
        if (m['v'] != tradeProtocol) return cancel(TradeError.version);
      case 'offer':
        // shortcut: an offer arriving after this phone committed means the two phones
        // crossed messages; cancel rather than guess (nothing applied yet, see commit).
        if (_committed) return cancel();
        final raw = m['cards'];
        if (raw is! List || raw.length > maxTradeCards) {
          return cancel(TradeError.invalid);
        }
        final cards = raw.map(checkCard).toList();
        if (cards.contains(null)) return cancel(TradeError.invalid);
        theirs = cards.cast<CardData>();
        iValidated = theyValidated = false;
      case 'ok':
        theyValidated = m['hash'] == hash;
        _maybeCommit();
      case 'commit':
        if (m['hash'] != hash) return cancel();
        _theyCommitted = true;
        _maybeApply();
      default:
        return cancel(TradeError.invalid);
    }
    onChange();
  }

  void _maybeCommit() {
    if (iValidated && theyValidated && !_committed) {
      _committed = true;
      send({'t': 'commit', 'hash': hash});
      _maybeApply();
    }
  }

  // shortcut: if the link drops between the two commits, one phone may swap and the
  // other not; a journal of unfinished trades would fix it, only if testing shows it.
  void _maybeApply() {
    if (_committed && _theyCommitted) done = true;
  }
}
