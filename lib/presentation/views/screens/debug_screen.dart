import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/repositories/sim_source.dart';
import '../../controllers/health_controller.dart';
import '../../controllers/performance_controller.dart';

class DebugScreen extends StatelessWidget {
  const DebugScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final healthController = Get.find<HealthController>();
    final perfController = Get.find<PerformanceController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Debug')),
      body: SingleChildScrollView(
        padding: AppConstants.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Debug Tools', style: AppConstants.titleStyle),
            const SizedBox(height: 24),

            // Simulation Mode Toggle
            if (SimSource.isAvailableInCurrentBuild) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Simulation Mode',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Enable synthetic data for testing without Health Connect',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      Obx(
                        () => SwitchListTile(
                          title: const Text('Synthetic Data Source'),
                          subtitle: Text(
                            healthController.isSimulationMode.value
                                ? 'Using simulated data'
                                : 'Using Health Connect',
                          ),
                          value: healthController.isSimulationMode.value,
                          onChanged: (_) =>
                              healthController.toggleSimulationMode(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Performance Metrics
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Performance Metrics',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () => perfController.reset(),
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Obx(
                      () => Column(
                        children: [
                          _buildMetricRow(
                            'Average Build Time',
                            '${perfController.averageBuildTime.value.toStringAsFixed(2)} ms',
                            perfController.averageBuildTime.value <=
                                AppConstants.maxBuildTimeMs,
                            'Target: ≤ ${AppConstants.maxBuildTimeMs} ms',
                          ),
                          const Divider(),
                          _buildMetricRow(
                            'Last Paint Time',
                            '${perfController.lastPaintTime.value.toStringAsFixed(2)} ms',
                            perfController.lastPaintTime.value <= 16,
                            'Target: ≤ 16 ms',
                          ),
                          const Divider(),
                          _buildMetricRow(
                            'FPS',
                            perfController.currentFps.value.toStringAsFixed(1),
                            perfController.currentFps.value >= 55,
                            'Target: ≥ 55 fps',
                          ),
                          const Divider(),
                          _buildMetricRow(
                            'Jank Frames',
                            '${perfController.jankFrames.value}',
                            perfController.jankFrames.value == 0,
                            'Target: 0',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Data Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Data Statistics',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Obx(
                      () => Column(
                        children: [
                          _buildDataRow(
                            'Steps Data Points',
                            '${healthController.stepsChartData.value.points.length}',
                          ),
                          const Divider(),
                          _buildDataRow(
                            'Heart Rate Data Points',
                            '${healthController.heartRateChartData.value.points.length}',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: () => healthController.loadInitialData(),
              child: const Text('Reload Data'),
            ),

            const SizedBox(height: 16),

            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Back to Dashboard'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(
    String label,
    String value,
    bool meetsTarget,
    String targetInfo,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  targetInfo,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  meetsTarget ? Icons.check_circle : Icons.warning,
                  color: meetsTarget ? Colors.green : Colors.orange,
                  size: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
