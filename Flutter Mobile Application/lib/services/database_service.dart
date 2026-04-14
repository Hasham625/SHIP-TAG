import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/sensor_reading.dart';
import '../models/device.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  late Database _database;
  bool _initialized = false;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<void> init() async {
    if (_initialized) return;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'shiptag.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
    );

    _initialized = true;
  }

  Future<void> _createTables(Database db, int version) async {
    // Create sensor_readings table
    await db.execute('''
      CREATE TABLE sensor_readings(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        deviceId TEXT NOT NULL,
        temperature REAL,
        humidity REAL,
        tiltAngle REAL,
        shockDetected INTEGER,
        tamperDetected INTEGER,
        batteryLevel INTEGER,
        timestamp TEXT NOT NULL,
        UNIQUE(deviceId, timestamp)
      )
    ''');

    // Create devices table
    await db.execute('''
      CREATE TABLE devices(
        deviceId TEXT PRIMARY KEY,
        batteryLevel INTEGER,
        status TEXT,
        packageName TEXT,
        location TEXT,
        lastUpdated TEXT
      )
    ''');

    // Create cache_metadata table for tracking last updates
    await db.execute('''
      CREATE TABLE cache_metadata(
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
  }

  // Sensor Reading Operations
  Future<void> insertSensorReading(SensorReading reading) async {
    await _database.insert(
      'sensor_readings',
      reading.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _updateLastCacheTime();
  }

  Future<void> insertSensorReadings(List<SensorReading> readings) async {
    for (final reading in readings) {
      await _database.insert(
        'sensor_readings',
        reading.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    _updateLastCacheTime();
  }

  Future<List<SensorReading>> getSensorReadings(String deviceId) async {
    final maps = await _database.query(
      'sensor_readings',
      where: 'deviceId = ?',
      whereArgs: [deviceId],
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) {
      return SensorReading.fromMap(maps[i]);
    });
  }

  Future<void> clearOldReadings({int days = 7}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    await _database.delete(
      'sensor_readings',
      where: 'timestamp < ?',
      whereArgs: [cutoffDate.toIso8601String()],
    );
  }

  // Device Operations
  Future<void> insertDevice(Device device) async {
    await _database.insert(
      'devices',
      device.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertDevices(List<Device> devices) async {
    for (final device in devices) {
      await _database.insert(
        'devices',
        device.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    _updateLastCacheTime();
  }

  Future<List<Device>> getAllDevices() async {
    final maps = await _database.query('devices');

    return List.generate(maps.length, (i) {
      return Device.fromMap(maps[i]);
    });
  }

  Future<Device?> getDevice(String deviceId) async {
    final maps = await _database.query(
      'devices',
      where: 'deviceId = ?',
      whereArgs: [deviceId],
    );

    if (maps.isEmpty) return null;
    return Device.fromMap(maps.first);
  }

  // Cache Metadata Operations
  Future<void> _updateLastCacheTime() async {
    await _database.insert(
      'cache_metadata',
      {
        'key': 'last_update',
        'value': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<DateTime?> getLastCacheUpdate() async {
    final maps = await _database.query(
      'cache_metadata',
      where: 'key = ?',
      whereArgs: ['last_update'],
    );

    if (maps.isEmpty) return null;

    try {
      final timestamp = maps.first['value'] as String?;
      if (timestamp == null) return null;
      return DateTime.parse(timestamp);
    } catch (e) {
      return null;
    }
  }

  // Cleanup
  Future<void> close() async {
    await _database.close();
  }
}
