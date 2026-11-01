import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import 'main.dart';

/// Soft sound effects (2026-11-01; made by pipeline/sounds.py), switched off in Settings.
/// They never take the audio focus, so music playing on the phone goes on.
class Sfx {
  static final _players = <String, (AudioPlayer, Future<void>)>{};

  /// Off in widget tests, which have no audio plugin.
  @visibleForTesting
  static bool enabled = true;

  static Future<void> _play(String name) async {
    if (!enabled || !store.sounds) return;
    try {
      final (player, loaded) = _players[name] ??= () {
        final p = AudioPlayer(handleAudioSessionActivation: false);
        return (p, p.setAsset('assets/sounds/$name.wav').then((_) {}));
      }();
      await loaded;
      await player.seek(Duration.zero);
      await player.play();
    } catch (_) {} // a sound effect never gets in the way
  }

  /// A quiet wooden tick: main buttons.
  static Future<void> tap() => _play('tap');

  /// A faint paper swish: turning a page, tearing a booster.
  static Future<void> swipe() => _play('swipe');

  /// A calm two-note chime: a card turning face up.
  static Future<void> reveal() => _play('reveal');
}
