import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';

import '../birds.dart';
import '../cards.dart';
import '../content.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import '../trade.dart';
import 'card.dart';
import 'collection.dart';
import 'theme.dart';

const _service = 'com.nathanprovin.earlybird.trade';

enum _Step { searching, pairing, trading, done, failed }

/// Face-to-face trade (see lib/trade.dart): both birders open this screen, the phones
/// find each other over Bluetooth / Wi-Fi (Nearby Connections), both check the same two
/// bird names, build their offers and validate.
class TradeScreen extends StatefulWidget {
  const TradeScreen({super.key});

  @override
  State<TradeScreen> createState() => _TradeScreenState();
}

class _TradeScreenState extends State<TradeScreen> {
  final _nearby = Nearby();
  // A random name for this session only: no account, nothing about the user.
  final _me = Random().nextInt(1 << 31).toRadixString(36);
  _Step _step = _Step.searching;
  String? _endpoint; // the other phone, once found
  (String, String)? _code; // the two bird names both phones show
  bool _accepted = false;
  TradeSession? _session;
  String? _failure, _detail; // what went wrong, and Nearby's own error if any
  bool _needsSettings =
      false; // a permission was refused: back from Settings, retry
  bool _askedLocation = false;
  List<CardData> _received = [];
  late final _lifecycle = AppLifecycleListener(
    onResume: () {
      if (_step == _Step.failed && _needsSettings) _restart();
    },
  );

  @override
  void initState() {
    super.initState();
    _lifecycle; // starts listening
    _start();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    unawaited(_stop());
    super.dispose();
  }

  void _restart() {
    setState(() {
      _step = _Step.searching;
      _failure = _detail = null;
      _needsSettings = _accepted = false;
      _endpoint = null;
      _session = null;
    });
    _start();
  }

  Future<void> _stop() async {
    try {
      await _nearby.stopDiscovery();
      await _nearby.stopAdvertising();
      await _nearby.stopAllEndpoints();
    } on PlatformException {
      // already stopped
    }
  }

  Future<void> _start() async {
    // A search left over from an earlier attempt would refuse to start again.
    await _stop();
    // Granted at once on Android versions that don't have them.
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.nearbyWifiDevices,
    ].request();
    if (!mounted) return;
    final l = AppLocalizations.of(context);
    if (statuses.values.any((s) => !s.isGranted)) {
      return _fail(l.tradePermissions, settings: true);
    }
    try {
      // Both phones advertise and discover; the one with the smaller name asks to connect.
      final ok =
          await _nearby.startAdvertising(
            _me,
            Strategy.P2P_POINT_TO_POINT,
            onConnectionInitiated: _initiated,
            onConnectionResult: _result,
            onDisconnected: (_) => _fail(l.tradeCancelled),
            serviceId: _service,
          ) &&
          await _nearby.startDiscovery(
            _me,
            Strategy.P2P_POINT_TO_POINT,
            onEndpointFound: (id, name, _) {
              if (_endpoint != null || _me.compareTo(name) >= 0) return;
              _endpoint = id;
              _nearby.requestConnection(
                _me,
                id,
                onConnectionInitiated: _initiated,
                onConnectionResult: _result,
                onDisconnected: (_) => _fail(l.tradeCancelled),
              );
            },
            onEndpointLost: (_) {},
            serviceId: _service,
          );
      if (!ok) _fail(l.tradeStartFailed);
    } on PlatformException catch (e) {
      debugPrint('trade: $e');
      // Android 12L and older also need location for Nearby: ask once, then retry.
      if ('${e.message}'.contains('LOCATION') && !_askedLocation) {
        _askedLocation = true;
        if (await Permission.locationWhenInUse.request().isGranted) {
          return _start();
        }
        return _fail(l.tradePermissions, settings: true);
      }
      _fail(l.tradeStartFailed, detail: e.message);
    }
  }

  void _initiated(String id, ConnectionInfo info) {
    if (!mounted || _step != _Step.searching) return;
    final (a, b) = pairingBirds(info.authenticationToken, bundledBirds);
    final locale = AppLocalizations.of(context).localeName;
    String name(String bird) => birdById(bird)?.nameIn(locale) ?? bird;
    setState(() {
      _endpoint = id;
      _code = (name(a), name(b));
      _step = _Step.pairing;
    });
  }

  Future<void> _accept() async {
    setState(() => _accepted = true);
    await _nearby.acceptConnection(
      _endpoint!,
      onPayLoadRecieved: (_, payload) {
        try {
          _session?.receive(
            jsonDecode(utf8.decode(payload.bytes!)) as Map<String, Object?>,
          );
        } on Object {
          _session?.cancel(TradeError.invalid);
        }
      },
    );
  }

  void _result(String id, Status status) {
    if (!mounted) return;
    if (status != Status.CONNECTED) {
      return _fail(AppLocalizations.of(context).tradeCancelled);
    }
    unawaited(_nearby.stopDiscovery());
    unawaited(_nearby.stopAdvertising());
    final session = TradeSession(
      send: (m) => _nearby.sendBytesPayload(
        id,
        Uint8List.fromList(utf8.encode(jsonEncode(m))),
      ),
      onChange: _changed,
    );
    setState(() {
      _session = session;
      _step = _Step.trading;
    });
    session.start();
  }

  Future<void> _changed() async {
    final s = _session!;
    if (!mounted) return;
    final l = AppLocalizations.of(context);
    if (s.done && _step == _Step.trading) {
      _received = s.theirs;
      await store.trade(s.mine, s.theirs);
      if (!mounted) return;
      setState(() => _step = _Step.done);
      unawaited(_nearby.stopAllEndpoints());
    } else if (s.error != null) {
      _fail(switch (s.error!) {
        TradeError.version => l.updateToTrade,
        TradeError.invalid => l.tradeInvalid,
        TradeError.cancelled => l.tradeCancelled,
      });
    } else {
      setState(() {});
    }
  }

  void _fail(String message, {bool settings = false, String? detail}) {
    if (!mounted || _step == _Step.done || _step == _Step.failed) return;
    setState(() {
      _failure = message;
      _detail = detail;
      _needsSettings = settings;
      _step = _Step.failed;
    });
    unawaited(_stop());
  }

  Future<void> _pick() async {
    final s = _session!;
    final picked = await showModalBottomSheet<List<CardData>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _Picker(initial: s.mine),
    );
    if (picked != null) s.offer(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(l.trade)),
      body: SafeArea(
        child: switch (_step) {
          _Step.searching => _Centered(
            children: [
              _Pulse(color: scheme.primary),
              const SizedBox(height: 32),
              Text(
                l.lookingForBirder,
                style: text.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l.lookingHint,
                style: text.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
          _Step.pairing => _Centered(
            children: [
              Text(
                l.checkCode,
                style: text.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              for (final name in [_code!.$1, _code!.$2])
                Text(
                  name,
                  style: text.headlineMedium?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 32),
              if (_accepted)
                Text(l.waitingForThem, style: text.bodyMedium)
              else ...[
                FilledButton(onPressed: _accept, child: Text(l.itMatches)),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l.cancel),
                ),
              ],
            ],
          ),
          _Step.trading => _trading(l, text, scheme),
          _Step.done => _done(l, text),
          _Step.failed => _Centered(
            children: [
              Text(
                _failure!,
                style: text.titleMedium,
                textAlign: TextAlign.center,
              ),
              if (_detail case final d?) ...[
                const SizedBox(height: 8),
                Text(d, style: text.bodySmall, textAlign: TextAlign.center),
              ],
              const SizedBox(height: 24),
              if (_needsSettings) ...[
                FilledButton(
                  onPressed: openAppSettings,
                  child: Text(l.openSettings),
                ),
                const SizedBox(height: 8),
              ],
              FilledButton.tonal(onPressed: _restart, child: Text(l.retry)),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l.done),
              ),
            ],
          ),
        },
      ),
    );
  }

  Widget _trading(AppLocalizations l, TextTheme text, ColorScheme scheme) {
    final s = _session!;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.youGive, style: text.titleMedium),
          const SizedBox(height: 8),
          _Offer(
            cards: s.mine,
            empty: l.nothingYet,
            onAdd: s.ended ? null : _pick,
            addLabel: l.addCards,
          ),
          const SizedBox(height: 24),
          Text(l.youGet, style: text.titleMedium),
          const SizedBox(height: 8),
          _Offer(cards: s.theirs, empty: l.nothingYet),
          const Spacer(),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: [
              if (s.iValidated)
                Chip(
                  avatar: const Icon(Icons.check, size: 18),
                  label: Text(l.youValidated),
                ),
              Chip(
                avatar: Icon(
                  s.theyValidated ? Icons.check : Icons.hourglass_empty,
                  size: 18,
                ),
                label: Text(
                  s.theyValidated ? l.theyValidated : l.waitingForThem,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: s.canValidate ? s.validate : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
            child: Text(s.iValidated ? l.youValidated : l.validate),
          ),
        ],
      ),
    );
  }

  Widget _done(AppLocalizations l, TextTheme text) => Column(
    children: [
      const SizedBox(height: 8),
      Text(l.tradeDone, style: text.titleLarge),
      Expanded(
        // The received cards flip in one by one, like a booster.
        child: PageView(
          children: [
            for (final c in _received)
              if (birdById(c.birdId) case final b?)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: CardDetail(bird: b, card: c, flipIn: true),
                ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
          child: Text(l.done),
        ),
      ),
    ],
  );
}

class _Centered extends StatelessWidget {
  const _Centered({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    ),
  );
}

/// One side's offer: small cards in a row, and an "add" tile for this phone's side.
class _Offer extends StatelessWidget {
  const _Offer({
    required this.cards,
    required this.empty,
    this.onAdd,
    this.addLabel,
  });
  final List<CardData> cards;
  final String empty;
  final VoidCallback? onAdd;
  final String? addLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 132,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          if (onAdd != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Tooltip(
                message: addLabel ?? '',
                child: InkWell(
                  onTap: onAdd,
                  borderRadius: BorderRadius.circular(radius),
                  child: Container(
                    width: 90,
                    decoration: BoxDecoration(
                      border: Border.all(color: scheme.outline, width: 2),
                      borderRadius: BorderRadius.circular(radius),
                    ),
                    child: Icon(Icons.add, size: 32, color: scheme.primary),
                  ),
                ),
              ),
            ),
          if (cards.isEmpty && onAdd == null)
            Center(
              child: Text(empty, style: Theme.of(context).textTheme.bodyMedium),
            ),
          for (final c in cards)
            if (birdById(c.birdId) case final b?)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: SizedBox(
                  width: 90,
                  child: CardTile(bird: b, card: c, heard: false),
                ),
              ),
        ],
      ),
    );
  }
}

/// Choose the cards to give: the whole collection, duplicates first, up to
/// [maxTradeCards].
class _Picker extends StatefulWidget {
  const _Picker({required this.initial});
  final List<CardData> initial;

  @override
  State<_Picker> createState() => _PickerState();
}

class _PickerState extends State<_Picker> {
  late final _chosen = {for (final c in widget.initial) c.key};

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final cards = store.cards;
    final best = {for (final c in bestCards(cards).values) c.key};
    // By bird, then the spare copies before the best one.
    final sorted =
        [
          for (final c in cards)
            if (birdById(c.birdId) != null) c,
        ]..sort((a, b) {
          final n = birdById(a.birdId)!.number - birdById(b.birdId)!.number;
          if (n != 0) return n;
          return (best.contains(a.key) ? 1 : 0) -
              (best.contains(b.key) ? 1 : 0);
        });
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.75,
      child: Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.68,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: sorted.length,
              itemBuilder: (_, i) {
                final c = sorted[i];
                final on = _chosen.contains(c.key);
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    CardTile(
                      bird: birdById(c.birdId)!,
                      card: c,
                      heard: false,
                      compact: true,
                      copies: cards.where((x) => x.birdId == c.birdId).length,
                      onTap: () => setState(() {
                        if (on) {
                          _chosen.remove(c.key);
                        } else if (_chosen.length < maxTradeCards) {
                          _chosen.add(c.key);
                        }
                      }),
                    ),
                    if (on)
                      IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            color: scheme.primary.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(radius - 6),
                          ),
                          child: Icon(
                            Icons.check_circle,
                            size: 36,
                            color: scheme.onPrimary,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop([
                for (final c in sorted)
                  if (_chosen.contains(c.key)) c,
              ]),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
              ),
              child: Text('${l.done} (${_chosen.length}/$maxTradeCards)'),
            ),
          ),
        ],
      ),
    );
  }
}

/// A soft pulse in the theme's accent while the phones look for each other.
class _Pulse extends StatefulWidget {
  const _Pulse({required this.color});
  final Color color;

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 160,
    child: AnimatedBuilder(
      animation: _c,
      builder: (_, _) => Stack(
        alignment: Alignment.center,
        children: [
          for (final phase in [0.0, 0.5])
            Builder(
              builder: (_) {
                final t = (_c.value + phase) % 1;
                return Container(
                  width: 40 + 120 * t,
                  height: 40 + 120 * t,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color.withValues(alpha: 0.35 * (1 - t)),
                  ),
                );
              },
            ),
          Icon(Icons.swap_horiz, size: 40, color: widget.color),
        ],
      ),
    ),
  );
}
