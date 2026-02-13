import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

import '../../domain/entities/chart_data.dart';

class PerformanceController extends GetxController {
  final averageBuildTime = 0.0.obs;
  final lastPaintTime = 0.0.obs;
  final currentFps = 60.0.obs;
  final jankFrames = 0.obs;

  final List<double> _buildTimes = [];
  final List<Duration> _frameTimes = [];
  int _totalFrames = 0;

  Timer? _metricsTimer;

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
      _totalFrames++;

      // Check for jank (frame took more than 16.67ms for 60fps)
      if (frameDuration.inMilliseconds > 16.67) {
        jankFrames.value++;
      }

      // Keep only last 120 frames (2 seconds at 60fps)
      if (_frameTimes.length > 120) {
        _frameTimes.removeAt(0);
      }
    }
  }

  void recordBuildTime(double milliseconds) {
    if (milliseconds > 0) {
      _buildTimes.add(milliseconds);

      // Keep only recent builds
      if (_buildTimes.length > 100) {
        _buildTimes.removeAt(0);
      }

      // Update immediately
      _updateBuildTime();
    }
  }

  void recordPaintTime(double milliseconds) {
    if (milliseconds > 0) {
      lastPaintTime.value = milliseconds;
    }
  }

  void _updateBuildTime() {
    if (_buildTimes.isNotEmpty) {
      final sum = _buildTimes.reduce((a, b) => a + b);
      averageBuildTime.value = sum / _buildTimes.length;
    }
  }

  void _updateMetrics() {
    // Calculate average build time
    _updateBuildTime();

    // Calculate FPS from recent frames
    if (_frameTimes.isNotEmpty) {
      final avgFrameTime =
          _frameTimes.map((d) => d.inMicroseconds).reduce((a, b) => a + b) /
          _frameTimes.length;

      if (avgFrameTime > 0) {
        currentFps.value = (1000000 / avgFrameTime).clamp(0.0, 60.0);
      }
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
    _totalFrames = 0;
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
