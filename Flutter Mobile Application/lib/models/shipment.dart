import 'device.dart';

class Location {
  final double latitude;
  final double longitude;

  Location({required this.latitude, required this.longitude});

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      latitude: _parseDouble(json['latitude']) ?? 0.0,
      longitude: _parseDouble(json['longitude']) ?? 0.0,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

class Shipment {
  final String shipmentId;
  final String trackingNumber;
  final String origin;
  final String destination;
  final Location currentLocation;
  final Device? assignedDevice;

  Shipment({
    required this.shipmentId,
    required this.trackingNumber,
    required this.origin,
    required this.destination,
    required this.currentLocation,
    this.assignedDevice,
  });

  factory Shipment.fromJson(Map<String, dynamic> json) {
    return Shipment(
      shipmentId: json['shipmentId'] ?? '',
      trackingNumber: json['trackingNumber'] ?? '',
      origin: json['origin'] ?? '',
      destination: json['destination'] ?? '',
      currentLocation: Location.fromJson(json['currentLocation'] ?? {}),
      assignedDevice: json['assignedDevice'] != null
          ? Device.fromJson(json['assignedDevice'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'shipmentId': shipmentId,
      'trackingNumber': trackingNumber,
      'origin': origin,
      'destination': destination,
      'currentLocation': currentLocation.toJson(),
      'assignedDevice': assignedDevice?.toJson(),
    };
  }

  Shipment copyWith({
    String? shipmentId,
    String? trackingNumber,
    String? origin,
    String? destination,
    Location? currentLocation,
    Device? assignedDevice,
  }) {
    return Shipment(
      shipmentId: shipmentId ?? this.shipmentId,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      currentLocation: currentLocation ?? this.currentLocation,
      assignedDevice: assignedDevice ?? this.assignedDevice,
    );
  }
}
