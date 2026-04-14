enum AlertType { shock, temperature, tamper, battery }

enum AlertSeverity { high, medium, low }

class Alert {
  final String alertId;
  final AlertType type;
  final AlertSeverity severity;
  final String message;
  final DateTime timestamp;
  final String? deviceId;
  final bool isRead;

  Alert({
    required this.alertId,
    required this.type,
    required this.severity,
    required this.message,
    required this.timestamp,
    this.deviceId,
    this.isRead = false,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      alertId: json['alertId'] ?? '',
      type: _parseAlertType(json['type']),
      severity: _parseAlertSeverity(json['severity']),
      message: json['message'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      deviceId: json['deviceId'],
      isRead: json['isRead'] ?? false,
    );
  }

  factory Alert.fromMap(Map<String, dynamic> map) {
    return Alert(
      alertId: map['alertId'] ?? '',
      type: _parseAlertType(map['type']),
      severity: _parseAlertSeverity(map['severity']),
      message: map['message'] ?? '',
      timestamp: DateTime.parse(map['timestamp'] as String),
      deviceId: map['deviceId'],
      isRead: (map['isRead'] as int?) == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'alertId': alertId,
      'type': type.toString().split('.').last,
      'severity': severity.toString().split('.').last,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'deviceId': deviceId,
      'isRead': isRead,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'alertId': alertId,
      'type': type.toString().split('.').last,
      'severity': severity.toString().split('.').last,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'deviceId': deviceId,
      'isRead': isRead ? 1 : 0,
    };
  }

  Alert copyWith({
    String? alertId,
    AlertType? type,
    AlertSeverity? severity,
    String? message,
    DateTime? timestamp,
    String? deviceId,
    bool? isRead,
  }) {
    return Alert(
      alertId: alertId ?? this.alertId,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      deviceId: deviceId ?? this.deviceId,
      isRead: isRead ?? this.isRead,
    );
  }

  static AlertType _parseAlertType(String? type) {
    switch (type?.toLowerCase()) {
      case 'shock':
        return AlertType.shock;
      case 'temperature':
        return AlertType.temperature;
      case 'tamper':
        return AlertType.tamper;
      case 'battery':
        return AlertType.battery;
      default:
        return AlertType.temperature;
    }
  }

  static AlertSeverity _parseAlertSeverity(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'high':
        return AlertSeverity.high;
      case 'medium':
        return AlertSeverity.medium;
      case 'low':
        return AlertSeverity.low;
      default:
        return AlertSeverity.medium;
    }
  }
}
