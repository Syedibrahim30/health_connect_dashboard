import 'dart:async';

import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';

import '../../domain/entities/health_data.dart';

abstract class HealthRepository {
  Future<HealthPermissionStatus> requestPermissions();
  Future<HealthPermissionStatus> checkPermissions();
  Stream<HealthDataUpdate> getHealthDataStream();
  Future<List<StepsData>> getStepsData(DateTime start, DateTime end);
  Future<List<HeartRateData>> getHeartRateData(DateTime start, DateTime end);
  Future<int> getTodaySteps();
  Future<HeartRateData?> getLatestHeartRate();
  void startPolling();
  void stopPolling();
}

class HealthRepositoryImpl implements HealthRepository {
  final GetStorage _storage = GetStorage();

  // Platform channels for native Android integration (Passive Listener)
  static const MethodChannel _methodChannel = MethodChannel(
    'health_connect_dashboard/health',
  );
  static const EventChannel _eventChannel = EventChannel(
    'health_connect_dashboard/health_stream',
  );

  // Stream controller for realtime updates
  final _healthDataController = StreamController<HealthDataUpdate>.broadcast();
  StreamSubscription? _nativeStreamSubscription;
  final Set<String> _processedRecordIds = {};

  HealthRepositoryImpl();

  @override
  void startPolling() {
    if (_nativeStreamSubscription != null) return; // Already listening

    print('📡 Starting native Health Connect listener...');

    // Subscribe to native EventChannel (acts as Passive Listener)
    _nativeStreamSubscription = _eventChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        _handleNativeHealthData(event);
      },
      onError: (dynamic error) {
        print('❌ Error receiving native health data: $error');
      },
    );
  }

  @override
  void stopPolling() {
    print('🛑 Stopping native Health Connect listener...');
    _nativeStreamSubscription?.cancel();
    _nativeStreamSubscription = null;
  }

  void _handleNativeHealthData(dynamic data) {
    try {
      final Map<dynamic, dynamic> eventData = data as Map<dynamic, dynamic>;

      List<StepsData>? steps;
      List<HeartRateData>? heartRate;

      // Parse steps data
      if (eventData.containsKey('steps')) {
        final stepsRaw = eventData['steps'] as List<dynamic>;
        steps = stepsRaw
            .map((item) {
              final map = item as Map<dynamic, dynamic>;
              final recordId = map['recordId'] as String;

              // De-duplicate
              if (_processedRecordIds.contains(recordId)) {
                return null;
              }
              _processedRecordIds.add(recordId);

              return StepsData(
                timestamp: DateTime.fromMillisecondsSinceEpoch(
                  map['timestamp'] as int,
                ),
                count: map['count'] as int,
                recordId: recordId,
              );
            })
            .whereType<StepsData>()
            .toList();
      }

      // Parse heart rate data
      if (eventData.containsKey('heartRate')) {
        final hrRaw = eventData['heartRate'] as List<dynamic>;
        heartRate = hrRaw
            .map((item) {
              final map = item as Map<dynamic, dynamic>;
              final recordId = map['recordId'] as String;

              // De-duplicate
              if (_processedRecordIds.contains(recordId)) {
                return null;
              }
              _processedRecordIds.add(recordId);

              return HeartRateData(
                timestamp: DateTime.fromMillisecondsSinceEpoch(
                  map['timestamp'] as int,
                ),
                bpm: map['bpm'] as int,
                recordId: recordId,
              );
            })
            .whereType<HeartRateData>()
            .toList();
      }

      // Emit update if we have new data
      if ((steps != null && steps.isNotEmpty) ||
          (heartRate != null && heartRate.isNotEmpty)) {
        print(
          '✅ Emitting health data update: ${steps?.length ?? 0} steps, ${heartRate?.length ?? 0} HR readings',
        );

        _healthDataController.add(
          HealthDataUpdate(
            steps: steps,
            heartRate: heartRate,
            timestamp: DateTime.now(),
          ),
        );
      }

      // Clean up old processed IDs (keep last 1000)
      if (_processedRecordIds.length > 1000) {
        final toRemove = _processedRecordIds.length - 1000;
        final idsToRemove = _processedRecordIds.take(toRemove).toList();
        _processedRecordIds.removeAll(idsToRemove);
      }
    } catch (e) {
      print('❌ Error parsing native health data: $e');
    }
  }

  @override
  Future<HealthPermissionStatus> requestPermissions() async {
    try {
      final result = await _methodChannel.invokeMethod('requestPermissions');
      final granted = result as bool? ?? false;

      return HealthPermissionStatus(
        stepsGranted: granted,
        heartRateGranted: granted,
      );
    } catch (e) {
      print('❌ Error requesting permissions: $e');
      return HealthPermissionStatus(
        stepsGranted: false,
        heartRateGranted: false,
      );
    }
  }

  @override
  Future<HealthPermissionStatus> checkPermissions() async {
    try {
      final result = await _methodChannel.invokeMethod('checkPermissions');
      final Map<dynamic, dynamic> permissions = result as Map<dynamic, dynamic>;

      return HealthPermissionStatus(
        stepsGranted: permissions['stepsGranted'] as bool? ?? false,
        heartRateGranted: permissions['heartRateGranted'] as bool? ?? false,
      );
    } catch (e) {
      print('❌ Error checking permissions: $e');
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
    // Historical data fetch would need additional native implementation
    // For MVP, this returns empty - data comes through stream
    return [];
  }

  @override
  Future<List<HeartRateData>> getHeartRateData(
    DateTime start,
    DateTime end,
  ) async {
    // Historical data fetch would need additional native implementation
    // For MVP, this returns empty - data comes through stream
    return [];
  }

  @override
  Future<int> getTodaySteps() async {
    try {
      final result = await _methodChannel.invokeMethod('getTodaySteps');
      return result as int? ?? 0;
    } catch (e) {
      print('❌ Error getting today steps: $e');
      return 0;
    }
  }

  @override
  Future<HeartRateData?> getLatestHeartRate() async {
    try {
      final result = await _methodChannel.invokeMethod('getLatestHeartRate');

      if (result == null) return null;

      final Map<dynamic, dynamic> data = result as Map<dynamic, dynamic>;

      return HeartRateData(
        timestamp: DateTime.fromMillisecondsSinceEpoch(
          data['timestamp'] as int,
        ),
        bpm: data['bpm'] as int,
        recordId: data['recordId'] as String,
      );
    } catch (e) {
      print('❌ Error getting latest heart rate: $e');
      return null;
    }
  }

  void dispose() {
    stopPolling();
    _healthDataController.close();
  }
}
