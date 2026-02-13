import 'dart:async';

import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/date_utils.dart' as app_date_utils;
import '../../data/repositories/health_repository.dart';
import '../../data/repositories/sim_source.dart';
import '../../domain/entities/chart_data.dart';
import '../../domain/entities/health_data.dart';
import 'performance_controller.dart';

class HealthController extends GetxController {
  final HealthRepository _repository;

  HealthController(this._repository);

  final permissionStatus = Rx<HealthPermissionStatus>(
    HealthPermissionStatus(stepsGranted: false, heartRateGranted: false),
  );

  final currentSteps = 0.obs;
  final latestHeartRate = Rxn<HeartRateData>();
  final isLoading = false.obs;
  final errorMessage = Rxn<String>();

  final stepsChartData = Rx<ChartData>(ChartData.empty());
  final heartRateChartData = Rx<ChartData>(ChartData.empty());

  // Raw data storage
  final List<StepsData> _stepsHistory = [];
  final List<HeartRateData> _heartRateHistory = [];

  final isSimulationMode = false.obs;

  // Subscriptions
  StreamSubscription? _healthDataSubscription;
  StreamSubscription? _simDataSubscription;

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  Future<void> _initialize() async {
    await checkPermissions();

    if (permissionStatus.value.allGranted) {
      await loadInitialData();
      _repository.startPolling();
      _subscribeToHealthData();
    }
  }

  Future<void> checkPermissions() async {
    try {
      final status = await _repository.checkPermissions();
      permissionStatus.value = status;
    } catch (e) {
      errorMessage.value = 'Error checking permissions: $e';
    }
  }

  Future<void> requestPermissions() async {
    try {
      isLoading.value = true;
      errorMessage.value = null;

      final status = await _repository.requestPermissions();
      permissionStatus.value = status;

      if (status.allGranted) {
        await loadInitialData();
        // Start polling after permissions granted
        _repository.startPolling();
        _subscribeToHealthData();
      }
    } catch (e) {
      errorMessage.value = 'Error requesting permissions: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadInitialData() async {
    try {
      isLoading.value = true;

      // Load today's steps
      final steps = await _repository.getTodaySteps();
      currentSteps.value = steps;

      // Load latest heart rate
      final hr = await _repository.getLatestHeartRate();
      latestHeartRate.value = hr;

      // Load historical data for charts
      final now = DateTime.now();
      final chartStart = app_date_utils.DateUtils.getChartStartTime(
        AppConstants.stepsChartWindowMinutes,
      );

      final stepsData = await _repository.getStepsData(chartStart, now);
      final hrData = await _repository.getHeartRateData(chartStart, now);

      _stepsHistory.clear();
      _stepsHistory.addAll(stepsData);

      _heartRateHistory.clear();
      _heartRateHistory.addAll(hrData);

      _updateCharts();
    } catch (e) {
      errorMessage.value = 'Error loading data: $e';
    } finally {
      isLoading.value = false;
    }
  }

  void _subscribeToHealthData() {
    if (isSimulationMode.value) {
      _subscribeToSimData();
      return;
    }

    _healthDataSubscription?.cancel();
    _healthDataSubscription = _repository.getHealthDataStream().listen(
      _handleHealthDataUpdate,
      onError: (e) {
        errorMessage.value = 'Error receiving health data: $e';
      },
    );
  }

  void _subscribeToSimData() {
    _simDataSubscription?.cancel();
    _simDataSubscription = SimSource.stream.listen(
      _handleHealthDataUpdate,
      onError: (e) {
        errorMessage.value = 'Error receiving sim data: $e';
      },
    );
  }

  void _handleHealthDataUpdate(HealthDataUpdate update) {
    // Update steps
    if (update.steps != null && update.steps!.isNotEmpty) {
      _stepsHistory.addAll(update.steps!);

      // Get the latest step count (already cumulative from source)
      final latest = update.steps!.last;
      currentSteps.value = latest.count;
    }

    // Update heart rate
    if (update.heartRate != null && update.heartRate!.isNotEmpty) {
      _heartRateHistory.addAll(update.heartRate!);

      // Update latest
      final sorted = List<HeartRateData>.from(update.heartRate!)
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      latestHeartRate.value = sorted.first;
    }

    // Update charts (debounced)
    _debounceUpdateCharts();
  }

  Timer? _chartUpdateTimer;
  void _debounceUpdateCharts() {
    _chartUpdateTimer?.cancel();
    _chartUpdateTimer = Timer(AppConstants.dataUpdateDebounce, () {
      _updateCharts();
    });
  }

  void _updateCharts() {
    final now = DateTime.now();

    // Update steps chart
    final stepsStart = app_date_utils.DateUtils.getChartStartTime(
      AppConstants.stepsChartWindowMinutes,
    );

    final recentSteps =
        _stepsHistory.where((s) => s.timestamp.isAfter(stepsStart)).toList()
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (recentSteps.isNotEmpty) {
      var stepsPoints = recentSteps
          .map(
            (s) => ChartDataPoint(
              timestamp: s.timestamp,
              value: s.count.toDouble(),
            ),
          )
          .toList();

      // Decimate if too many points
      if (stepsPoints.length > AppConstants.maxChartPoints) {
        stepsPoints = ChartData.decimatePoints(stepsPoints, 1000);
      }

      stepsChartData.value = ChartData(
        points: stepsPoints,
        minValue: 0,
        maxValue: recentSteps
            .map((s) => s.count)
            .reduce((a, b) => a > b ? a : b)
            .toDouble(),
        startTime: stepsStart,
        endTime: now,
      );
    }

    // Update heart rate chart
    final hrStart = app_date_utils.DateUtils.getChartStartTime(
      AppConstants.heartRateChartWindowMinutes,
    );

    final recentHR =
        _heartRateHistory.where((hr) => hr.timestamp.isAfter(hrStart)).toList()
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (recentHR.isNotEmpty) {
      var hrPoints = recentHR
          .map(
            (hr) => ChartDataPoint(
              timestamp: hr.timestamp,
              value: hr.bpm.toDouble(),
            ),
          )
          .toList();

      // Decimate if too many points
      if (hrPoints.length > AppConstants.maxChartPoints) {
        hrPoints = ChartData.decimatePoints(hrPoints, 1000);
      }

      heartRateChartData.value = ChartData(
        points: hrPoints,
        minValue:
            recentHR
                .map((hr) => hr.bpm)
                .reduce((a, b) => a < b ? a : b)
                .toDouble() -
            10,
        maxValue:
            recentHR
                .map((hr) => hr.bpm)
                .reduce((a, b) => a > b ? a : b)
                .toDouble() +
            10,
        startTime: hrStart,
        endTime: now,
      );
    }
  }

  void toggleSimulationMode() {
    isSimulationMode.value = !isSimulationMode.value;

    if (isSimulationMode.value) {
      // Stop real health polling
      _repository.stopPolling();
      _healthDataSubscription?.cancel();

      // Reset performance metrics for clean measurement
      Get.find<PerformanceController>().reset();

      // Start simulation
      SimSource.enable();
      _subscribeToSimData();
    } else {
      // Stop simulation
      SimSource.disable();
      _simDataSubscription?.cancel();

      // Resume real health polling if permissions granted
      if (permissionStatus.value.allGranted) {
        _repository.startPolling();
        _subscribeToHealthData();
      }
    }
  }

  @override
  void onClose() {
    _healthDataSubscription?.cancel();
    _simDataSubscription?.cancel();
    _chartUpdateTimer?.cancel();
    _repository.stopPolling();
    SimSource.disable();
    super.onClose();
  }
}
