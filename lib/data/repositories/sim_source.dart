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
    _startSimulation();
  }

  static void disable() {
    if (!_enabled) return;
    _enabled = false;
    _timer?.cancel();
    _timer = null;
  }

  static Stream<HealthDataUpdate> get stream => _controller.stream;

  static void _startSimulation() {
    _currentSteps = _random.nextInt(5000);
    _currentHeartRate = 60 + _random.nextInt(40); // 60-100 bpm

    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!_enabled) return;

      final now = DateTime.now();

      _currentSteps += _random.nextInt(11);

      _currentHeartRate = (60 + _random.nextInt(61)).clamp(60, 120);

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
    return true;
  }
}
