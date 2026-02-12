import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/entities/chart_data.dart';

class PerformanceController extends GetxController {
  final averageBuildTime = 0.0.obs;
  final lastPaintTime = 0.0.obs;
  final currentFps = 60.0.obs;
  final jankFrames = 0.obs;

  final List<double> _buildTimes = [];
  final List<Duration> _frameTimes = [];

  Timer? _metricsTimer;
  Duration? _lastFrameTime;

  @override
  void onInit() {
    super.onInit();
    _startMonitoring();
  }

  void _startMonitoring() {
    // Monitor frame times
    SchedulerBinding.instance.addTimingsCallback(_onFrameTiming);

    // Update metrics every second
    _metricsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateMetrics();
    });
  }

  void _onFrameTiming(List<FrameTiming> timings) {
    for (final timing in timings) {
      final frameDuration = timing.totalSpan;
      _frameTimes.add(frameDuration);

      // Check for jank (frame took more than 16.67ms for 60fps)
      if (frameDuration.inMilliseconds > 16.67) {
        jankFrames.value++;
      }

      // Keep only recent frames
      if (_frameTimes.length > 60) {
        _frameTimes.removeAt(0);
      }
    }
  }

  void recordBuildTime(double milliseconds) {
    _buildTimes.add(milliseconds);

    // Keep only recent builds
    if (_buildTimes.length > 100) {
      _buildTimes.removeAt(0);
    }
  }

  void recordPaintTime(double milliseconds) {
    lastPaintTime.value = milliseconds;
  }

  void _updateMetrics() {
    // Calculate average build time
    if (_buildTimes.isNotEmpty) {
      final sum = _buildTimes.reduce((a, b) => a + b);
      averageBuildTime.value = sum / _buildTimes.length;
    }

    // Calculate FPS
    if (_frameTimes.isNotEmpty) {
      final avgFrameTime =
          _frameTimes.map((d) => d.inMicroseconds).reduce((a, b) => a + b) /
          _frameTimes.length;

      currentFps.value = 1000000 / avgFrameTime;
    }
  }

  PerformanceMetrics get metrics => PerformanceMetrics(
    averageBuildTime: averageBuildTime.value,
    lastPaintTime: lastPaintTime.value,
    fps: currentFps.value,
    jankFrames: jankFrames.value,
  );

  void reset() {
    _buildTimes.clear();
    _frameTimes.clear();
    jankFrames.value = 0;
    averageBuildTime.value = 0;
    lastPaintTime.value = 0;
    currentFps.value = 60;
  }

  @override
  void onClose() {
    _metricsTimer?.cancel();
    SchedulerBinding.instance.removeTimingsCallback(_onFrameTiming);
    super.onClose();
  }
}
