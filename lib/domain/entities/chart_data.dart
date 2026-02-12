import 'dart:math' as math;

class ChartDataPoint {
  final DateTime timestamp;
  final double value;

  ChartDataPoint({required this.timestamp, required this.value});

  @override
  String toString() => 'ChartDataPoint(time: $timestamp, value: $value)';
}

class ChartData {
  final List<ChartDataPoint> points;
  final double minValue;
  final double maxValue;
  final DateTime startTime;
  final DateTime endTime;

  ChartData({
    required this.points,
    required this.minValue,
    required this.maxValue,
    required this.startTime,
    required this.endTime,
  });

  /// Create empty chart data
  factory ChartData.empty() {
    final now = DateTime.now();
    return ChartData(
      points: [],
      minValue: 0,
      maxValue: 100,
      startTime: now.subtract(const Duration(hours: 1)),
      endTime: now,
    );
  }

  /// Decimate data points using Largest Triangle Three Buckets (LTTB) algorithm
  /// This ensures smooth rendering while maintaining visual fidelity
  static List<ChartDataPoint> decimatePoints(
    List<ChartDataPoint> points,
    int maxPoints,
  ) {
    if (points.length <= maxPoints) return points;

    final decimated = <ChartDataPoint>[];
    final bucketSize = (points.length - 2) / (maxPoints - 2);

    // Always include first point
    decimated.add(points.first);

    int a = 0;
    for (int i = 0; i < maxPoints - 2; i++) {
      // Calculate bucket range
      final avgRangeStart = ((i + 1) * bucketSize).floor() + 1;
      final avgRangeEnd = ((i + 2) * bucketSize).floor() + 1;
      final avgRangeEndClamped = math.min(avgRangeEnd, points.length);

      // Calculate average point in next bucket
      double avgX = 0;
      double avgY = 0;
      int avgRangeLength = avgRangeEndClamped - avgRangeStart;

      for (int j = avgRangeStart; j < avgRangeEndClamped; j++) {
        avgX += points[j].timestamp.millisecondsSinceEpoch.toDouble();
        avgY += points[j].value;
      }
      avgX /= avgRangeLength;
      avgY /= avgRangeLength;

      // Find point with largest triangle area
      final rangeOffs = ((i + 0) * bucketSize).floor() + 1;
      final rangeTo = ((i + 1) * bucketSize).floor() + 1;

      final pointAX = points[a].timestamp.millisecondsSinceEpoch.toDouble();
      final pointAY = points[a].value;

      double maxArea = -1;
      int maxAreaPoint = rangeOffs;

      for (int j = rangeOffs; j < rangeTo; j++) {
        final pointX = points[j].timestamp.millisecondsSinceEpoch.toDouble();
        final pointY = points[j].value;

        final area =
            ((pointAX - avgX) * (pointY - pointAY) -
                    (pointAX - pointX) * (avgY - pointAY))
                .abs() *
            0.5;

        if (area > maxArea) {
          maxArea = area;
          maxAreaPoint = j;
        }
      }

      decimated.add(points[maxAreaPoint]);
      a = maxAreaPoint;
    }

    // Always include last point
    decimated.add(points.last);

    return decimated;
  }

  /// Resample data points to fixed intervals
  static List<ChartDataPoint> resamplePoints(
    List<ChartDataPoint> points,
    Duration interval,
  ) {
    if (points.isEmpty) return [];

    final resampled = <ChartDataPoint>[];
    final startTime = points.first.timestamp;
    final endTime = points.last.timestamp;

    DateTime currentTime = startTime;
    int pointIndex = 0;

    while (currentTime.isBefore(endTime) || currentTime == endTime) {
      // Find points in current interval
      final intervalEnd = currentTime.add(interval);
      final intervalPoints = <double>[];

      while (pointIndex < points.length &&
          points[pointIndex].timestamp.isBefore(intervalEnd)) {
        intervalPoints.add(points[pointIndex].value);
        pointIndex++;
      }

      if (intervalPoints.isNotEmpty) {
        // Use average value for interval
        final avgValue =
            intervalPoints.reduce((a, b) => a + b) / intervalPoints.length;
        resampled.add(ChartDataPoint(timestamp: currentTime, value: avgValue));
      }

      currentTime = intervalEnd;
    }

    return resampled;
  }
}

class PerformanceMetrics {
  final double averageBuildTime;
  final double lastPaintTime;
  final double fps;
  final int jankFrames;

  PerformanceMetrics({
    required this.averageBuildTime,
    required this.lastPaintTime,
    required this.fps,
    required this.jankFrames,
  });

  bool get meetsTargets {
    return averageBuildTime <= 8.0 && jankFrames == 0 && fps >= 55;
  }
}
