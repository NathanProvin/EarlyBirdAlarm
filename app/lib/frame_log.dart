import 'dart:ui';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Frame times in logcat, for performance work only (`--dart-define=FRAME_LOG=true`;
/// 2026-11-27): every 120 frames, the UI (build) and GPU (raster) thread times at the
/// 50th / 90th / 99th percentile and the share of frames over the screen's budget.
const frameLog = bool.fromEnvironment('FRAME_LOG');

void startFrameLog() {
  final hz = PlatformDispatcher.instance.views.first.display.refreshRate;
  final budget = 1000 / hz;
  final build = <double>[], raster = <double>[];
  debugPrint('frames: display ${hz.toStringAsFixed(0)} Hz');
  SchedulerBinding.instance.addTimingsCallback((timings) {
    for (final t in timings) {
      build.add(t.buildDuration.inMicroseconds / 1000);
      raster.add(t.rasterDuration.inMicroseconds / 1000);
    }
    if (build.length < 120) return;
    String stats(List<double> v) {
      v.sort();
      double p(double q) => v[((v.length - 1) * q).round()];
      final over = v.where((x) => x > budget).length * 100 ~/ v.length;
      return 'p50 ${p(.5).toStringAsFixed(1)} p90 ${p(.9).toStringAsFixed(1)} '
          'p99 ${p(.99).toStringAsFixed(1)} ms, $over % over';
    }

    debugPrint(
      'frames: ${build.length} | ui ${stats(build)} | gpu ${stats(raster)} '
      '| budget ${budget.toStringAsFixed(1)} ms',
    );
    build.clear();
    raster.clear();
  });
}
