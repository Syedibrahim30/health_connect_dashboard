class StepsData {
  final DateTime timestamp;
  final int count;
  final String? recordId;

  StepsData({required this.timestamp, required this.count, this.recordId});

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'count': count,
    'recordId': recordId,
  };

  factory StepsData.fromJson(Map<String, dynamic> json) => StepsData(
    timestamp: DateTime.parse(json['timestamp']),
    count: json['count'],
    recordId: json['recordId'],
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StepsData &&
          runtimeType == other.runtimeType &&
          timestamp == other.timestamp &&
          recordId == other.recordId;

  @override
  int get hashCode => timestamp.hashCode ^ recordId.hashCode;
}

class HeartRateData {
  final DateTime timestamp;
  final int bpm;
  final String? recordId;

  HeartRateData({required this.timestamp, required this.bpm, this.recordId});

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'bpm': bpm,
    'recordId': recordId,
  };

  factory HeartRateData.fromJson(Map<String, dynamic> json) => HeartRateData(
    timestamp: DateTime.parse(json['timestamp']),
    bpm: json['bpm'],
    recordId: json['recordId'],
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HeartRateData &&
          runtimeType == other.runtimeType &&
          timestamp == other.timestamp &&
          recordId == other.recordId;

  @override
  int get hashCode => timestamp.hashCode ^ recordId.hashCode;
}

class HealthDataUpdate {
  final List<StepsData>? steps;
  final List<HeartRateData>? heartRate;
  final DateTime timestamp;

  HealthDataUpdate({this.steps, this.heartRate, required this.timestamp});
}

class HealthPermissionStatus {
  final bool stepsGranted;
  final bool heartRateGranted;

  HealthPermissionStatus({
    required this.stepsGranted,
    required this.heartRateGranted,
  });

  bool get allGranted => stepsGranted && heartRateGranted;
  bool get anyDenied => !stepsGranted || !heartRateGranted;
}
