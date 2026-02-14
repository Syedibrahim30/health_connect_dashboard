import 'package:flutter/material.dart';

class AppConstants {
  // Performance Targets
  static const int targetFPS = 60;
  static const int maxBuildTimeMs = 8;
  static const int latencyTargetSeconds = 10;

  // Anti-Plagiarism SALT
  static const String packageName = 'com.example.health_connect_dashboard';
  static const String firstCommitHash =
      '187a25564aaf870e8ec68a66ca028ddf73746b1b';
  static const String salt =
      '2d662365ceb906957be219431571b09f56055b0f96bd43aeeb8fedf63202aa6a';

  // Chart Settings
  static const int stepsChartWindowMinutes = 60;
  static const int heartRateChartWindowMinutes = 60;
  static const int maxChartPoints = 10000;

  // Polling Settings
  static const Duration pollingInterval = Duration(seconds: 5);
  static const Duration dataUpdateDebounce = Duration(milliseconds: 500);

  // UI Constants
  static const EdgeInsets defaultPadding = EdgeInsets.all(16.0);
  static const double chartHeight = 300.0;
  static const double cardElevation = 4.0;
  static const double borderRadius = 12.0;

  // Colors
  static const Color primaryColor = Color(0xFF2196F3);
  static const Color accentColor = Color(0xFF4CAF50);
  static const Color errorColor = Color(0xFFF44336);
  static const Color stepsColor = Color(0xFF4CAF50);
  static const Color heartRateColor = Color(0xFFF44336);
  static const Color gridColor = Color(0xFFE0E0E0);
  static const Color tooltipBackground = Color(0xFF424242);

  // Text Styles
  static const TextStyle titleStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle subtitleStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle valueStyle = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle labelStyle = TextStyle(
    fontSize: 12,
    color: Colors.grey,
  );
}

class StorageKeys {
  static const String changesToken = 'changes_token';
  static const String lastSyncTime = 'last_sync_time';
  static const String stepsData = 'steps_data';
  static const String heartRateData = 'heart_rate_data';
  static const String salt = 'app_salt';
}

class Routes {
  static const String dashboard = '/dashboard';
  static const String permissions = '/permissions';
  static const String debug = '/debug';
}
