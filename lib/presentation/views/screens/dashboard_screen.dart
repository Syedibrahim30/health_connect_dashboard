import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_utils.dart' as app_date_utils;
import '../../controllers/health_controller.dart';
import '../../widgets/interactive_chart.dart';
import '../../widgets/performance_hud.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final healthController = Get.find<HealthController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Get.toNamed('/permissions'),
          ),
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () => Get.toNamed('/debug'),
          ),
        ],
      ),
      body: Obx(() {
        if (!healthController.permissionStatus.value.allGranted) {
          return _buildPermissionRequired();
        }

        return Stack(
          children: [
            SingleChildScrollView(
              padding: AppConstants.defaultPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Current Values Cards
                  Row(
                    children: [
                      Expanded(child: _buildStepsCard(healthController)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildHeartRateCard(healthController)),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Steps Chart
                  InteractiveChart(
                    data: healthController.stepsChartData.value,
                    lineColor: AppConstants.stepsColor,
                    fillColor: AppConstants.stepsColor,
                    title:
                        'Steps (Last ${AppConstants.stepsChartWindowMinutes} min)',
                    height: AppConstants.chartHeight,
                  ),

                  const SizedBox(height: 24),

                  // Heart Rate Chart
                  InteractiveChart(
                    data: healthController.heartRateChartData.value,
                    lineColor: AppConstants.heartRateColor,
                    fillColor: AppConstants.heartRateColor,
                    title:
                        'Heart Rate (Last ${AppConstants.heartRateChartWindowMinutes} min)',
                    height: AppConstants.chartHeight,
                  ),

                  const SizedBox(height: 24),

                  // Error Message
                  if (healthController.errorMessage.value != null)
                    _buildErrorBanner(healthController.errorMessage.value!),
                ],
              ),
            ),

            // Performance HUD
            const PerformanceHUD(),
          ],
        );
      }),
    );
  }

  Widget _buildStepsCard(HealthController controller) {
    return Card(
      elevation: AppConstants.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Padding(
        padding: AppConstants.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.directions_walk,
                  color: AppConstants.stepsColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text('Steps Today', style: AppConstants.subtitleStyle),
              ],
            ),
            const SizedBox(height: 12),
            Obx(
              () => Text(
                controller.currentSteps.value.toString(),
                style: AppConstants.valueStyle.copyWith(
                  color: AppConstants.stepsColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeartRateCard(HealthController controller) {
    return Card(
      elevation: AppConstants.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Padding(
        padding: AppConstants.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.favorite,
                  color: AppConstants.heartRateColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text('Heart Rate', style: AppConstants.subtitleStyle),
              ],
            ),
            const SizedBox(height: 12),
            Obx(() {
              final hr = controller.latestHeartRate.value;
              if (hr == null) {
                return const Text('--', style: AppConstants.valueStyle);
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${hr.bpm} bpm',
                    style: AppConstants.valueStyle.copyWith(
                      color: AppConstants.heartRateColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    app_date_utils.DateUtils.getTimeAgo(hr.timestamp),
                    style: AppConstants.labelStyle,
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionRequired() {
    return Center(
      child: Padding(
        padding: AppConstants.defaultPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.health_and_safety, size: 64, color: Colors.grey),
            const SizedBox(height: 24),
            const Text(
              'Health Connect Access Required',
              style: AppConstants.titleStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Please grant permissions to view your health data',
              style: AppConstants.subtitleStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Get.toNamed('/permissions'),
              child: const Text('Grant Permissions'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.errorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: AppConstants.errorColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: AppConstants.errorColor),
            ),
          ),
        ],
      ),
    );
  }
}
