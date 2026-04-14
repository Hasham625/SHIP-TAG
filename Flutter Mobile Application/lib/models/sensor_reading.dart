class SensorReading {
  final double temperature;
  final double humidity;
  final double tiltAngle;
  final bool shockDetected;
  final bool tamperDetected;
  final int batteryLevel;
  final DateTime timestamp;

  SensorReading({
    required this.temperature,
    required this.humidity,
    required this.tiltAngle,
    required this.shockDetected,
    required this.tamperDetected,
    required this.batteryLevel,
    required this.timestamp,
  });

  factory SensorReading.fromJson(Map<String, dynamic> json) {
    return SensorReading(
      temperature: _parseDouble(json['temperature']) ?? 0.0,
      humidity: _parseDouble(json['humidity']) ?? 0.0,
      tiltAngle: _parseDouble(json['tiltAngle']) ?? 0.0,
      shockDetected: json['shockDetected'] ?? false,
      tamperDetected: json['tamperDetected'] ?? false,
      batteryLevel: _parseInt(json['batteryLevel']) ?? 0,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'].toString())
          : DateTime.now(),
    );
  }

  factory SensorReading.fromMap(Map<String, dynamic> map) {
    return SensorReading(
      temperature: _parseDouble(map['temperature']) ?? 0.0,
      humidity: _parseDouble(map['humidity']) ?? 0.0,
      tiltAngle: _parseDouble(map['tiltAngle']) ?? 0.0,
      shockDetected: (map['shockDetected'] as int?) == 1,
      tamperDetected: (map['tamperDetected'] as int?) == 1,
      batteryLevel: _parseInt(map['batteryLevel']) ?? 0,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'humidity': humidity,
      'tiltAngle': tiltAngle,
      'shockDetected': shockDetected,
      'tamperDetected': tamperDetected,
      'batteryLevel': batteryLevel,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'temperature': temperature,
      'humidity': humidity,
      'tiltAngle': tiltAngle,
      'shockDetected': shockDetected ? 1 : 0,
      'tamperDetected': tamperDetected ? 1 : 0,
      'batteryLevel': batteryLevel,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  SensorReading copyWith({
    double? temperature,
    double? humidity,
    double? tiltAngle,
    bool? shockDetected,
    bool? tamperDetected,
    int? batteryLevel,
    DateTime? timestamp,
  }) {
    return SensorReading(
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      tiltAngle: tiltAngle ?? this.tiltAngle,
      shockDetected: shockDetected ?? this.shockDetected,
      tamperDetected: tamperDetected ?? this.tamperDetected,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
