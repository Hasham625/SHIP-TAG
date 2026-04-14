import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import '../../providers/shipment_provider.dart';
import '../../providers/device_provider.dart';
import '../../providers/alert_provider.dart';
import '../../models/sensor_reading.dart';
import '../../models/shipment.dart';
import '../../models/alert.dart';

// Constants
const activeAlertThreshold = Duration(hours: 2);
// Pakistan Map Bounds (Lahore, Islamabad, Peshawar)
const double lahoreLatitude = 31.5204;
const double lahoreLongitude = 74.3587;
const double islamabadLatitude = 33.6844;
const double islamabadLongitude = 73.0479;
const double peshawarLatitude = 34.0083;
const double peshawarLongitude = 71.5189;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late GoogleMapController _mapController;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<ShipmentProvider>().loadShipments();
      context.read<DeviceProvider>().loadDevices();
      context.read<AlertProvider>().loadAlerts();
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  /// Centers map on current device location using live data from Provider
  void _centerMapOnCurrentLocation() {
    final shipments = context.read<ShipmentProvider>().shipments;
    if (shipments.isNotEmpty) {
      final currentLoc = shipments.first.currentLocation;
      _mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(currentLoc.latitude, currentLoc.longitude),
            zoom: 13,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ShipmentProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ship Tag Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blue,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Device Location and Route Heading with Last Updated Label
            Consumer<DeviceProvider>(
              builder: (context, deviceProvider, _) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Device Location and Route',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (deviceProvider.lastCacheUpdate != null)
                      Text(
                        'Updated: ${DateFormat('HH:mm:ss').format(deviceProvider.lastCacheUpdate!)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),

            // Map with Polyline Route
            _buildMapWithRoute(),
            const SizedBox(height: 24),

            // Live Metrics
            Center(
              child: Text(
                'Live Metrics',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildMetricsGrid(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMapWithRoute() {
    const initialPosition = LatLng(islamabadLatitude, islamabadLongitude);

    return Consumer<ShipmentProvider>(
      builder: (context, shipmentProvider, _) {
        final shipments = shipmentProvider.shipments;
        final polylines = _buildRoutePolylines(shipments);

        return Stack(
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 300,
                  child: GoogleMap(
                    initialCameraPosition: const CameraPosition(
                      target: initialPosition,
                      zoom: 12,
                    ),
                    onMapCreated: (controller) {
                      _mapController = controller;
                    },
                    markers: _buildMarkers(shipments),
                    circles: _buildCircles(shipments),
                    polylines: polylines.toSet(),
                    zoomControlsEnabled: true,
                    gestureRecognizers: {
                      Factory<OneSequenceGestureRecognizer>(
                        () => EagerGestureRecognizer(),
                      ),
                    },
                  ),
                ),
              ),
            ),
            // FAB
            Positioned(
              bottom: 100,
              right: 12,
              child: FloatingActionButton(
                mini: true,
                backgroundColor: Colors.blue,
                onPressed: _centerMapOnCurrentLocation,
                child: const Icon(Icons.my_location, color: Colors.white, size: 20),
              ),
            ),
          ],
        );
      },
    );
  }

  Set<Marker> _buildMarkers(List<Shipment> shipments) {
    final markers = <Marker>{};

    if (shipments.isNotEmpty) {
      final firstShipment = shipments.first;

      // Red marker for destination (Peshawar)
      markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: const LatLng(peshawarLatitude, peshawarLongitude),
          infoWindow: InfoWindow(
            title: 'Destination: ${firstShipment.destination}',
            snippet: 'Peshawar',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(0), // Red
        ),
      );

      // Green marker for origin (Lahore)
      markers.add(
        Marker(
          markerId: const MarkerId('origin'),
          position: const LatLng(lahoreLatitude, lahoreLongitude),
          infoWindow: InfoWindow(
            title: 'Origin: ${firstShipment.origin}',
            snippet: 'Lahore',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(120), // Green
        ),
      );
    } else {
      // Fallback marker if no shipments
      markers.add(
        const Marker(
          markerId: MarkerId('default'),
          position: LatLng(islamabadLatitude, islamabadLongitude),
          infoWindow: InfoWindow(
            title: 'Default Location',
            snippet: 'Islamabad, Pakistan',
          ),
        ),
      );
    }

    return markers;
  }

  /// Creates a blue circle overlay for live location (mimics Google Maps blue dot)
  Set<Circle> _buildCircles(List<Shipment> shipments) {
    final circles = <Circle>{};

    if (shipments.isNotEmpty) {
      final currentLoc = shipments.first.currentLocation;
      final currentLatLng = LatLng(currentLoc.latitude, currentLoc.longitude);

      // Blue circle with white border for live location
      circles.add(
        Circle(
          circleId: const CircleId('live_location_circle'),
          center: currentLatLng,
          radius: 80, // Radius in meters
          fillColor: Colors.blue.withValues(alpha: 0.3),
          strokeColor: Colors.white,
          strokeWidth: 2,
        ),
      );

      // Inner blue dot
      circles.add(
        Circle(
          circleId: const CircleId('live_location_dot'),
          center: currentLatLng,
          radius: 15,
          fillColor: Colors.blue,
          strokeColor: Colors.white,
          strokeWidth: 2,
        ),
      );
    }

    return circles;
  }

  Set<Polyline> _buildRoutePolylines(List<Shipment> shipments) {
    final polylines = <Polyline>{};

    if (shipments.isEmpty) {
      return polylines;
    }

    final shipment = shipments.first;
    final currentLoc = shipment.currentLocation;
    final currentLatLng = LatLng(currentLoc.latitude, currentLoc.longitude);

    const originLocation = LatLng(lahoreLatitude, lahoreLongitude);
    const destinationLocation = LatLng(peshawarLatitude, peshawarLongitude);

    // Route from origin to current location (completed - blue)
    polylines.add(
      Polyline(
        polylineId: const PolylineId('route_to_current'),
        points: [originLocation, currentLatLng],
        color: Colors.blue,
        width: 4,
      ),
    );

    // Route from current to destination (remaining - green)
    polylines.add(
      Polyline(
        polylineId: const PolylineId('route_to_destination'),
        points: [currentLatLng, destinationLocation],
        color: Colors.green,
        width: 4,
      ),
    );

    return polylines;
  }

  Widget _buildMetricsGrid() {
    return Consumer2<DeviceProvider, AlertProvider>(
      builder: (context, deviceProvider, alertProvider, _) {
        if (deviceProvider.isLoading) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final reading = deviceProvider.sensorReadings.isNotEmpty
            ? deviceProvider.sensorReadings.last
            : null;

        final humidity = reading?.humidity ?? 0.0;
        final battery = deviceProvider.selectedDevice?.batteryLevel ?? 0;
        final temperature = reading?.temperature ?? 0.0;
        final shockDetected = reading?.shockDetected ?? false;
        final deviceId = deviceProvider.selectedDevice?.deviceId;
        final alerts = alertProvider.alerts;

        return GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 1.0,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [
            _buildMetricCard(
              title: 'Temperature',
              value: '${temperature.toStringAsFixed(1)}°C',
              color: Colors.orange,
              icon: Icons.thermostat,
              readings: deviceProvider.sensorReadings,
              readingType: 'temperature',
              alerts: alerts,
              deviceId: deviceId,
              alertType: AlertType.temperature,
            ),
            _buildMetricCard(
              title: 'Humidity',
              value: '${humidity.toStringAsFixed(0)}%',
              color: Colors.blue,
              icon: Icons.water_drop,
              readings: deviceProvider.sensorReadings,
              readingType: 'humidity',
              alerts: alerts,
              deviceId: deviceId,
            ),
            _buildMetricCard(
              title: 'Battery',
              value: '$battery%',
              color: battery > 50
                  ? Colors.green
                  : battery > 20
                      ? Colors.orange
                      : Colors.red,
              icon: Icons.battery_full,
              readings: deviceProvider.sensorReadings,
              readingType: 'battery',
              staticValue: battery.toDouble(),
              alerts: alerts,
              deviceId: deviceId,
              alertType: AlertType.battery,
            ),
            _buildMetricCard(
              title: 'Shock/Impact',
              value: shockDetected ? 'Yes' : 'No',
              color: shockDetected ? Colors.red : Colors.teal,
              icon: Icons.flash_on,
              readings: deviceProvider.sensorReadings,
              readingType: 'shock',
              alerts: alerts,
              deviceId: deviceId,
              alertType: AlertType.shock,
              isShockCard: true,
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
    required List<SensorReading> readings,
    required String readingType,
    double? staticValue,
    required List<Alert> alerts,
    String? deviceId,
    AlertType? alertType,
    bool isShockCard = false,
  }) {
    bool hasActiveAlert = false;
    if (alertType != null && deviceId != null) {
      final now = DateTime.now();
      hasActiveAlert = alerts.any((alert) =>
          alert.type == alertType &&
          alert.deviceId == deviceId &&
          !alert.isRead &&
          now.difference(alert.timestamp) <= activeAlertThreshold);
    }

    final textColor = hasActiveAlert ? Colors.red : Colors.black;
    final borderColor = hasActiveAlert ? Colors.red : Colors.grey[300]!;

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) {
            if (isShockCard) {
              return _buildShockDetailDialog(
                readings: readings,
                alerts: alerts,
                deviceId: deviceId,
                alertType: alertType,
              );
            } else {
              return _buildMetricDetailDialog(
                title: title,
                color: color,
                icon: icon,
                readings: readings,
                readingType: readingType,
                staticValue: staticValue,
                alerts: alerts,
                deviceId: deviceId,
                alertType: alertType,
              );
            }
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: hasActiveAlert ? 2 : 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    _extractNumericValue(value),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    overflow: TextOverflow.fade,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  _extractUnit(value),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap for details',
              style: TextStyle(fontSize: 10, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShockDetailDialog({
    required List<SensorReading> readings,
    required List<Alert> alerts,
    String? deviceId,
    AlertType? alertType,
  }) {
    final shockReadings = readings.where((r) => r.shockDetected).toList();

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                border: Border(
                  bottom: BorderSide(color: Colors.red, width: 2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.flash_on, color: Colors.red, size: 28),
                      const SizedBox(width: 12),
                      const Text(
                        'Shock/Impact History',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildShockDataTable(
                  readings: shockReadings,
                  alerts: alerts,
                  deviceId: deviceId,
                  alertType: alertType,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShockDataTable({
    required List<SensorReading> readings,
    required List<Alert> alerts,
    String? deviceId,
    AlertType? alertType,
  }) {
    if (readings.isEmpty) {
      return const Center(child: Text('No shock events detected'));
    }

    final tableData = readings
        .map((reading) {
          final timestamp = DateFormat('HH:mm:ss').format(reading.timestamp);
          final tilt = reading.tiltAngle.toStringAsFixed(1);
          final tamper = reading.tamperDetected ? 'Yes' : 'No';

          bool hasRecentAlert = false;
          if (alertType != null && deviceId != null) {
            final now = DateTime.now();
            hasRecentAlert = alerts.any((alert) =>
                alert.type == alertType &&
                alert.deviceId == deviceId &&
                !alert.isRead &&
                now.difference(alert.timestamp) <= activeAlertThreshold &&
                alert.timestamp.difference(reading.timestamp).inMinutes.abs() <= 5);
          }

          return [timestamp, tilt, tamper, hasRecentAlert];
        })
        .toList()
        .reversed
        .toList();

    return DataTable2(
      columnSpacing: 10,
      fixedColumnsColor: Colors.grey.withValues(alpha: 0.1),
      columns: const [
        DataColumn2(label: Text('Time'), size: ColumnSize.S),
        DataColumn2(label: Text('Tilt Angle'), size: ColumnSize.M),
        DataColumn2(label: Text('Intensity'), size: ColumnSize.M),
      ],
      rows: tableData
          .map(
            (row) => DataRow2(
              cells: [
                DataCell(Text(
                  row[0] as String,
                  style: TextStyle(
                    fontSize: 11,
                    color: row[3] as bool ? Colors.red : Colors.black,
                  ),
                  maxLines: 1,
                  softWrap: false,
                )),
                DataCell(
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${row[1]}°',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: row[3] as bool ? Colors.red : Colors.black,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      row[2] as String,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: row[3] as bool ? Colors.red : Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
          .toList(),
    );
  }

  Widget _buildMetricDetailDialog({
    required String title,
    required Color color,
    required IconData icon,
    required List<SensorReading> readings,
    required String readingType,
    double? staticValue,
    required List<Alert> alerts,
    String? deviceId,
    AlertType? alertType,
  }) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                border: Border(
                  bottom: BorderSide(color: color, width: 2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: color, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 220,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: _buildMetricHistoryChart(
                  readings: readings,
                  readingType: readingType,
                  color: color,
                  staticValue: staticValue,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildMetricsDataTable(
                  readings: readings,
                  readingType: readingType,
                  color: color,
                  staticValue: staticValue,
                  alerts: alerts,
                  deviceId: deviceId,
                  alertType: alertType,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricHistoryChart({
    required List<SensorReading> readings,
    required String readingType,
    required Color color,
    double? staticValue,
  }) {
    if (readings.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    final spots = readings.asMap().entries.map((entry) {
      final value = readingType == 'humidity'
          ? entry.value.humidity
          : readingType == 'temperature'
              ? entry.value.temperature
              : readingType == 'tilt'
                  ? entry.value.tiltAngle
                  : readingType == 'battery'
                      ? entry.value.batteryLevel.toDouble()
                      : 0.0;
      return FlSpot(entry.key.toDouble(), value);
    }).toList();

    if (spots.isEmpty) {
      return const Center(child: Text('No data'));
    }

    double minY, maxY;
    if (readingType == 'battery' || readingType == 'humidity') {
      minY = 0;
      maxY = 100;
    } else if (readingType == 'temperature') {
      minY = 15;
      maxY = 35;
    } else {
      minY = 0;
      maxY = 10;
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 35.0,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < readings.length) {
                  final time = readings[index].timestamp;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      '${time.hour}:${time.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 9),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40.0,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    '${value.toInt()}',
                    style: const TextStyle(fontSize: 9),
                  ),
                );
              },
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        minX: 0,
        maxX: (readings.length - 1).toDouble(),
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: color.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsDataTable({
    required List<SensorReading> readings,
    required String readingType,
    required Color color,
    double? staticValue,
    required List<Alert> alerts,
    String? deviceId,
    AlertType? alertType,
  }) {
    final tableData = readings
        .asMap()
        .entries
        .map((entry) {
          final reading = entry.value;
          final timestamp = DateFormat('HH:mm:ss').format(reading.timestamp);

          String value;
          String status;

          bool hasRecentAlert = false;
          if (alertType != null && deviceId != null) {
            final now = DateTime.now();
            hasRecentAlert = alerts.any((alert) =>
                alert.type == alertType &&
                alert.deviceId == deviceId &&
                !alert.isRead &&
                now.difference(alert.timestamp) <= activeAlertThreshold &&
                alert.timestamp.difference(reading.timestamp).inMinutes.abs() <= 5);
          }

          if (readingType == 'humidity') {
            final humidity = reading.humidity;
            value = '${humidity.toStringAsFixed(1)}%';
            if (humidity >= 40 && humidity <= 70) {
              status = hasRecentAlert ? 'Alert' : 'Normal';
            } else if (humidity > 70) {
              status = hasRecentAlert ? 'Alert' : 'High';
            } else {
              status = hasRecentAlert ? 'Alert' : 'Low';
            }
          } else if (readingType == 'temperature') {
            final temp = reading.temperature;
            value = '${temp.toStringAsFixed(1)}°C';
            if (temp >= 20 && temp <= 25) {
              status = hasRecentAlert ? 'Alert' : 'Normal';
            } else if (temp > 25) {
              status = hasRecentAlert ? 'Alert' : 'High';
            } else {
              status = hasRecentAlert ? 'Alert' : 'Low';
            }
          } else if (readingType == 'battery') {
            final battery = reading.batteryLevel;
            value = '$battery%';
            if (battery > 50) {
              status = hasRecentAlert ? 'Alert' : 'Good';
            } else if (battery > 20) {
              status = hasRecentAlert ? 'Alert' : 'Low';
            } else {
              status = hasRecentAlert ? 'Alert' : 'Critical';
            }
          } else {
            final tilt = reading.tiltAngle;
            value = '${tilt.toStringAsFixed(1)}°';
            status = hasRecentAlert
                ? 'Alert'
                : (tilt < 5 ? 'Stable' : 'Tilted');
          }

          return [timestamp, value, status, hasRecentAlert];
        })
        .toList()
        .reversed
        .toList();

    return DataTable2(
      columnSpacing: 10,
      fixedColumnsColor: Colors.grey.withValues(alpha: 0.1),
      columns: const [
        DataColumn2(label: Text('Time'), size: ColumnSize.S),
        DataColumn2(label: Text('Value'), size: ColumnSize.M),
        DataColumn2(label: Text('Status'), size: ColumnSize.M),
      ],
      rows: tableData
          .map(
            (row) => DataRow2(
              cells: [
                DataCell(Text(
                  row[0] as String,
                  style: TextStyle(
                    fontSize: 11,
                    color: row[3] as bool ? Colors.red : Colors.black,
                  ),
                  softWrap: false,
                  overflow: TextOverflow.fade,
                  maxLines: 1,
                )),
                DataCell(
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      row[1] as String,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: row[3] as bool ? Colors.red : Colors.black,
                      ),
                      softWrap: false,
                      maxLines: 1,
                    ),
                  ),
                ),
                DataCell(
                  Chip(
                    label: Text(row[2] as String),
                    backgroundColor: (row[3] as bool ? Colors.red : color)
                        .withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      color: row[3] as bool ? Colors.red : color,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    side: BorderSide(
                      color: row[3] as bool ? Colors.red : color,
                    ),
                  ),
                ),
              ],
            ),
          )
          .toList(),
    );
  }

  String _extractNumericValue(String value) {
    final regex = RegExp(r'[\d.]+');
    final match = regex.firstMatch(value);
    return match?.group(0) ?? value;
  }

  String _extractUnit(String value) {
    if (value.contains('°C')) return '°C';
    if (value.contains('%')) return '%';
    if (value.endsWith('°')) return '°';
    return '';
  }
}
