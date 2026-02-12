import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_constants.dart';
import '../../controllers/health_controller.dart';

class PermissionsScreen extends StatelessWidget {
  const PermissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HealthController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Permissions')),
      body: Padding(
        padding: AppConstants.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Health Connect Permissions',
              style: AppConstants.titleStyle,
            ),
            const SizedBox(height: 8),
            const Text(
              'Grant permissions to read your health data',
              style: AppConstants.subtitleStyle,
            ),
            const SizedBox(height: 32),

            Obx(
              () => _buildPermissionTile(
                icon: Icons.directions_walk,
                title: 'Steps',
                description: 'Read your step count data',
                isGranted: controller.permissionStatus.value.stepsGranted,
              ),
            ),

            const SizedBox(height: 16),

            Obx(
              () => _buildPermissionTile(
                icon: Icons.favorite,
                title: 'Heart Rate',
                description: 'Read your heart rate data',
                isGranted: controller.permissionStatus.value.heartRateGranted,
              ),
            ),

            const Spacer(),

            Obx(() {
              if (controller.errorMessage.value != null) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppConstants.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                      AppConstants.borderRadius,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: AppConstants.errorColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          controller.errorMessage.value!,
                          style: TextStyle(color: AppConstants.errorColor),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            }),

            Obx(
              () => ElevatedButton(
                onPressed: controller.isLoading.value
                    ? null
                    : () => controller.requestPermissions(),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: controller.isLoading.value
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        controller.permissionStatus.value.allGranted
                            ? 'Refresh Permissions'
                            : 'Grant Permissions',
                      ),
              ),
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

  Widget _buildPermissionTile({
    required IconData icon,
    required String title,
    required String description,
    required bool isGranted,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(
          color: isGranted ? AppConstants.accentColor : Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 32,
            color: isGranted ? AppConstants.accentColor : Colors.grey,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Icon(
            isGranted ? Icons.check_circle : Icons.cancel,
            color: isGranted ? AppConstants.accentColor : Colors.grey,
            size: 28,
          ),
        ],
      ),
    );
  }
}
