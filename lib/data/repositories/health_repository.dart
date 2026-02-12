import 'dart:async';

import 'package:get_storage/get_storage.dart';
import 'package:health/health.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/date_utils.dart' as app_date_utils;
import '../../domain/entities/health_data.dart';

abstract class HealthRepository {
  Future<HealthPermissionStatus> requestPermissions();
  Future<HealthPermissionStatus> checkPermissions();
  Stream<HealthDataUpdate> getHealthDataStream();
  Future<List<StepsData>> getStepsData(DateTime start, DateTime end);
  Future<List<HeartRateData>> getHeartRateData(DateTime start, DateTime end);
  Future<int> getTodaySteps();
  Future<HeartRateData?> getLatestHeartRate();
}

class HealthRepositoryImpl implements HealthRepository {
  final Health _health = Health();
  final GetStorage _storage = GetStorage();

  // Data types
  static final List<HealthDataType> _types = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
  ];

  // Stream controller for realtime updates
  final _healthDataController = StreamController<HealthDataUpdate>.broadcast();
  Timer? _pollingTimer;
  DateTime? _lastFetchTime;
  final Set<String> _processedRecordIds = {};

  HealthRepositoryImpl() {
    _initializePolling();
  }

  void _initializePolling() {
    _pollingTimer = Timer.periodic(AppConstants.pollingInterval, (_) {
      _pollForChanges();
    });
  }

  Future<void> _pollForChanges() async {
    try {
      final now = DateTime.now();
      final start = _lastFetchTime ?? now.subtract(const Duration(minutes: 1));

      // Fetch new data
      final steps = await getStepsData(start, now);
      final heartRate = await getHeartRateData(start, now);

      // Filter out already processed records
      final newSteps = steps
          .where(
            (s) =>
                s.recordId != null && !_processedRecordIds.contains(s.recordId),
          )
          .toList();

      final newHeartRate = heartRate
          .where(
            (hr) =>
                hr.recordId != null &&
                !_processedRecordIds.contains(hr.recordId),
          )
          .toList();

      // Add to processed set
      for (var s in newSteps) {
        if (s.recordId != null) _processedRecordIds.add(s.recordId!);
      }
      for (var hr in newHeartRate) {
        if (hr.recordId != null) _processedRecordIds.add(hr.recordId!);
      }

      // Emit update if we have new data
      if (newSteps.isNotEmpty || newHeartRate.isNotEmpty) {
        _healthDataController.add(
          HealthDataUpdate(
            steps: newSteps.isEmpty ? null : newSteps,
            heartRate: newHeartRate.isEmpty ? null : newHeartRate,
            timestamp: now,
          ),
        );
      }

      _lastFetchTime = now;

      // Clean up old processed IDs (keep last 1000)
      if (_processedRecordIds.length > 1000) {
        final toRemove = _processedRecordIds.length - 1000;
        _processedRecordIds.removeAll(_processedRecordIds.take(toRemove));
      }
    } catch (e) {
      print('Error polling for changes: $e');
    }
  }

  @override
  Future<HealthPermissionStatus> requestPermissions() async {
    try {
      final permissions = [HealthDataAccess.READ, HealthDataAccess.READ];

      final granted = await _health.requestAuthorization(
        _types,
        permissions: permissions,
      );

      return HealthPermissionStatus(
        stepsGranted: granted,
        heartRateGranted: granted,
      );
    } catch (e) {
      print('Error requesting permissions: $e');
      return HealthPermissionStatus(
        stepsGranted: false,
        heartRateGranted: false,
      );
    }
  }

  @override
  Future<HealthPermissionStatus> checkPermissions() async {
    try {
      final stepsGranted =
          await _health.hasPermissions([HealthDataType.STEPS]) ?? false;
      final heartRateGranted =
          await _health.hasPermissions([HealthDataType.HEART_RATE]) ?? false;

      return HealthPermissionStatus(
        stepsGranted: stepsGranted,
        heartRateGranted: heartRateGranted,
      );
    } catch (e) {
      print('Error checking permissions: $e');
      return HealthPermissionStatus(
        stepsGranted: false,
        heartRateGranted: false,
      );
    }
  }

  @override
  Stream<HealthDataUpdate> getHealthDataStream() {
    return _healthDataController.stream;
  }

  @override
  Future<List<StepsData>> getStepsData(DateTime start, DateTime end) async {
    try {
      final healthData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.STEPS],
        startTime: start,
        endTime: end,
      );

      return healthData.map((data) {
        final value = data.value as NumericHealthValue;
        return StepsData(
          timestamp: data.dateTo,
          count: value.numericValue.toInt(),
          recordId: data.uuid,
        );
      }).toList();
    } catch (e) {
      print('Error fetching steps data: $e');
      return [];
    }
  }

  @override
  Future<List<HeartRateData>> getHeartRateData(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final healthData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.HEART_RATE],
        startTime: start,
        endTime: end,
      );

      return healthData.map((data) {
        final value = data.value as NumericHealthValue;
        return HeartRateData(
          timestamp: data.dateTo,
          bpm: value.numericValue.toInt(),
          recordId: data.uuid,
        );
      }).toList();
    } catch (e) {
      print('Error fetching heart rate data: $e');
      return [];
    }
  }

  @override
  Future<int> getTodaySteps() async {
    try {
      final now = DateTime.now();
      final midnight = app_date_utils.DateUtils.startOfToday;

      final steps = await getStepsData(midnight, now);

      return steps.fold<int>(0, (sum, data) => sum + data.count);
    } catch (e) {
      print('Error getting today steps: $e');
      return 0;
    }
  }

  @override
  Future<HeartRateData?> getLatestHeartRate() async {
    try {
      final now = DateTime.now();
      final start = now.subtract(const Duration(hours: 1));

      final heartRates = await getHeartRateData(start, now);

      if (heartRates.isEmpty) return null;

      heartRates.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return heartRates.first;
    } catch (e) {
      print('Error getting latest heart rate: $e');
      return null;
    }
  }

  void dispose() {
    _pollingTimer?.cancel();
    _healthDataController.close();
  }
}
