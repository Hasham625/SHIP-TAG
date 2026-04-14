enum DeviceStatus { online, offline, alert }

class Device {
  final String deviceId;
  final int batteryLevel;
  final DeviceStatus status;
  final String? packageName;
  final String? location;

  Device({
    required this.deviceId,
    required this.batteryLevel,
    required this.status,
    this.packageName,
    this.location,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      deviceId: json['deviceId'] ?? '',
      batteryLevel: json['batteryLevel'] ?? 0,
      status: _parseDeviceStatus(json['status']),
      packageName: json['packageName'],
      location: json['location'],
    );
  }

  factory Device.fromMap(Map<String, dynamic> map) {
    return Device(
      deviceId: map['deviceId'] ?? '',
      batteryLevel: map['batteryLevel'] ?? 0,
      status: _parseDeviceStatus(map['status']),
      packageName: map['packageName'],
      location: map['location'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'batteryLevel': batteryLevel,
      'status': status.toString().split('.').last,
      'packageName': packageName,
      'location': location,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'deviceId': deviceId,
      'batteryLevel': batteryLevel,
      'status': status.toString().split('.').last,
      'packageName': packageName,
      'location': location,
    };
  }

  Device copyWith({
    String? deviceId,
    int? batteryLevel,
    DeviceStatus? status,
    String? packageName,
    String? location,
  }) {
    return Device(
      deviceId: deviceId ?? this.deviceId,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      status: status ?? this.status,
      packageName: packageName ?? this.packageName,
      location: location ?? this.location,
    );
  }

  static DeviceStatus _parseDeviceStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'online':
        return DeviceStatus.online;
      case 'offline':
        return DeviceStatus.offline;
      case 'alert':
        return DeviceStatus.alert;
      default:
        return DeviceStatus.offline;
    }
  }
}
