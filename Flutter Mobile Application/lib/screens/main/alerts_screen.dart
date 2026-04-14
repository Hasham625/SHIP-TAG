import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/alert_provider.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<AlertProvider>().loadAlerts();
      // Auto-mark all alerts as read when navigating to Alerts screen
      context.read<AlertProvider>().markAllAlertsAsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Alerts',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blue,
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer<AlertProvider>(
        builder: (context, alertProvider, _) {
          if (alertProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (alertProvider.error != null) {
            return Center(
              child: Text(
                'Error: ${alertProvider.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (alertProvider.alerts.isEmpty) {
            return const Center(
              child: Text('No alerts'),
            );
          }

          return Column(
            children: [
              // Unread badge
              if (alertProvider.unreadCount > 0)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  color: Colors.orange[100],
                  child: Center(
                    child: Text(
                      '${alertProvider.unreadCount} unread alert${alertProvider.unreadCount > 1 ? 's' : ''}',
                      style: TextStyle(
                        color: Colors.orange[900],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: alertProvider.alerts.length,
                  itemBuilder: (context, index) {
                    final alert = alertProvider.alerts[index];
                    return _buildAlertTile(context, alert, alertProvider);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAlertTile(
    BuildContext context,
    alert,
    AlertProvider alertProvider,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          onExpansionChanged: (expanded) {
            if (expanded && !alert.isRead) {
              alertProvider.markAlertAsRead(alert.alertId);
            }
          },
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getSeverityColor(alert.severity).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getAlertIcon(alert.type),
                  color: _getSeverityColor(alert.severity),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _getAlertTypeLabel(alert.type),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _getSeverityColor(alert.severity),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (!alert.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getSeverityLabel(alert.severity),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _formatTime(alert.timestamp),
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text(
                        'Device ID: ',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        alert.deviceId ?? 'Unknown',
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text(
                        'Time: ',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        DateFormat('MMM dd, yyyy - HH:mm:ss')
                            .format(alert.timestamp),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Message: ',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Expanded(
                        child: Text(alert.message),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getAlertTypeLabel(alertType) {
    switch (alertType.toString()) {
      case 'AlertType.shock':
        return 'Impact/Shock';
      case 'AlertType.temperature':
        return 'Temperature Alert';
      case 'AlertType.tamper':
        return 'Tamper Detected';
      case 'AlertType.battery':
        return 'Battery Low';
      default:
        return 'Alert';
    }
  }

  IconData _getAlertIcon(alertType) {
    switch (alertType.toString()) {
      case 'AlertType.shock':
        return Icons.warning;
      case 'AlertType.temperature':
        return Icons.thermostat;
      case 'AlertType.tamper':
        return Icons.security;
      case 'AlertType.battery':
        return Icons.battery_alert;
      default:
        return Icons.notifications;
    }
  }

  String _getSeverityLabel(severity) {
    switch (severity.toString()) {
      case 'AlertSeverity.high':
        return 'High Severity';
      case 'AlertSeverity.medium':
        return 'Medium Severity';
      case 'AlertSeverity.low':
        return 'Low Severity';
      default:
        return 'Unknown';
    }
  }

  Color _getSeverityColor(severity) {
    switch (severity.toString()) {
      case 'AlertSeverity.high':
        return Colors.red;
      case 'AlertSeverity.medium':
        return Colors.orange;
      case 'AlertSeverity.low':
        return Colors.yellow[700] ?? Colors.yellow;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
