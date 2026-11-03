import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../main.dart';

/// The phone's tilt as a -1..1 offset, like a finger on the card (right / bottom positive),
/// relative to how the phone is held: the rest pose slowly follows (~3 s), so a card lies
/// flat however the phone is held and leans when it moves.
Stream<Offset> phoneTilt() {
  Offset? rest;
  var g = Offset.zero;
  return accelerometerEventStream(
    samplingPeriod: SensorInterval.uiInterval,
  ).map((e) {
    final raw = Offset(e.x, e.y); // gravity, m/s²
    g = rest == null ? raw : Offset.lerp(g, raw, 0.25)!; // smoothed
    rest = rest == null ? raw : Offset.lerp(rest, g, 0.005)!;
    final d = g - rest!;
    // 3 m/s² (about 18°) gives the full lean.
    return Offset((-d.dx / 3).clamp(-1.0, 1.0), (d.dy / 3).clamp(-1.0, 1.0));
  });
}

/// Whether cards follow the phone; tests turn it off (no sensor plugin there).
bool Function() gyroOn = () => store.gyro;

/// [gyro]: the phone's tilt while the setting is on and animations aren't turned off
/// (accessibility); zero otherwise, or on a phone without an accelerometer.
mixin GyroTilt<T extends StatefulWidget> on State<T> {
  Offset gyro = Offset.zero;
  StreamSubscription<Offset>? _sub;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final on = gyroOn() && !MediaQuery.disableAnimationsOf(context);
    if (on && _sub == null) {
      _sub = phoneTilt().listen(
        (t) => setState(() => gyro = t),
        onError: (Object _) {}, // no sensor: the card just stays flat
      );
    } else if (!on && _sub != null) {
      _sub!.cancel();
      _sub = null;
      gyro = Offset.zero;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
