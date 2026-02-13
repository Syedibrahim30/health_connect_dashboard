import 'dart:async';
import 'dart:math';

import '../../domain/entities/health_data.dart';

class SimSource {
  static bool _enabled = false;
  static final _random = Random();
  static Timer? _timer;
  static final _controller = StreamController<HealthDataUpdate>.broadcast();

  static int _currentSteps = 0;
  static int _currentHeartRate = 70;

  static bool get isEnabled => _enabled;

  static void enable() {
    if (_enabled) return;
    _enabled = true;
    print('SimSource ENABLED - Starting simulation');
    _startSimulation();
  }

  static void disable() {
    if (!_enabled) return;
    _enabled = false;
    _timer?.cancel();
    _timer = null;
    print('SimSource DISABLED - Stopping simulation');
  }

  static Stream<HealthDataUpdate> get stream => _controller.stream;

  static void _startSimulation() {
    _currentSteps = _random.nextInt(5000); // Start with random baseline
    _currentHeartRate = 60 + _random.nextInt(40); // 60-100 bpm

    // Generate updates every 5-10 seconds (more realistic)
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_enabled) return;

      final now = DateTime.now();

      // Simulate steps (increase by 1-5 per update, like natural walking)
      _currentSteps += _random.nextInt(6); // 0-5 steps per 5 seconds

      // Simulate heart rate (small fluctuations)
      final change = _random.nextInt(5) - 2; // -2 to +2 bpm change
      _currentHeartRate = (_currentHeartRate + change).clamp(60, 120);

      final stepsData = StepsData(
        timestamp: now,
        count: _currentSteps,
        recordId: 'sim_steps_${now.millisecondsSinceEpoch}',
      );

      final heartRateData = HeartRateData(
        timestamp: now,
        bpm: _currentHeartRate,
        recordId: 'sim_hr_${now.millisecondsSinceEpoch}',
      );

      _controller.add(
        HealthDataUpdate(
          steps: [stepsData],
          heartRate: [heartRateData],
          timestamp: now,
        ),
      );
    });
  }

  static void dispose() {
    _timer?.cancel();
    _controller.close();
  }

  // This should be disabled in release builds
  static bool get isAvailableInCurrentBuild {
    // In production, this would check:
    // return !kReleaseMode;
    // For now, we'll allow it
    return true;
  }
}
