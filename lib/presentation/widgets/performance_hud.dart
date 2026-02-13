import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:health_connect_dashboard/presentation/controllers/performance_controller.dart';

import '../../../core/constants/app_constants.dart';

class PerformanceHUD extends StatelessWidget {
  const PerformanceHUD({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PerformanceController>();

    return Positioned(
      top: MediaQuery.of(context).padding.right + 200,
      right: 16,
      child: Obx(
        () => Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMetric(
                'Build',
                '${controller.averageBuildTime.value.toStringAsFixed(1)}ms',
                controller.averageBuildTime.value <=
                    AppConstants.maxBuildTimeMs,
              ),
              const SizedBox(height: 4),
              _buildMetric(
                'Paint',
                '${controller.lastPaintTime.value.toStringAsFixed(1)}ms',
                controller.lastPaintTime.value <= 16,
              ),
              const SizedBox(height: 4),
              _buildMetric(
                'FPS',
                controller.currentFps.value.toStringAsFixed(0),
                controller.currentFps.value >= 55,
              ),
              const SizedBox(height: 4),
              _buildMetric(
                'Jank',
                '${controller.jankFrames.value}',
                controller.jankFrames.value == 0,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value, bool isGood) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isGood ? Colors.green : Colors.red,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 40,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
