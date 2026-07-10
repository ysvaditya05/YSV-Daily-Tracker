import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/tracker.dart';
import '../models/time_session.dart';
import '../models/time_tracker_goal.dart';

class DuplicateTrackerNameException implements Exception {}

class TrackerDatabase {
  TrackerDatabase._();

  static final TrackerDatabase instance = TrackerDatabase._();

  static const _databaseName = 'ysv_daily.db';
  static const _trackersTable = 'trackers';
  static const _timeSessionsTable = 'time_sessions';
  static const _temporaryTimeSessionsTable = 'time_sessions_new';
  static const _timeTrackerGoalsTable = 'time_tracker_goals';

  sqflite.Database? _database;
  Future<sqflite.Database>? _databaseFuture;

  Future<sqflite.Database> get database {
    final database = _database;
    if (database != null) {
      return Future.value(database);
    }

    return _databaseFuture ??= _openDatabase();
  }

  Future<sqflite.Database> _openDatabase() async {
    _configureDatabaseFactory();

    final documentsPath = await sqflite.getDatabasesPath();
    final path = join(documentsPath, _databaseName);
    final openedDatabase = await sqflite.openDatabase(
      path,
      version: 4,
      onCreate: _create,
      onUpgrade: _upgrade,
    );
    _database = openedDatabase;
    return openedDatabase;
  }

  void _configureDatabaseFactory() {
    if (Platform.isLinux || Platform.isWindows) {
      sqfliteFfiInit();
      sqflite.databaseFactory = databaseFactoryFfi;
    }
  }

  Future<void> _create(sqflite.Database database, int version) async {
    await database.execute('''
      CREATE TABLE $_trackersTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    await _createTimeSessionsTable(database);
    await _createTimeTrackerGoalsTable(database);
  }

  Future<void> _upgrade(
    sqflite.Database database,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await _createTimeSessionsTable(database);
    }

    if (oldVersion < 3) {
      await _createTimeTrackerGoalsTable(database);
    }

    if (oldVersion >= 2 && oldVersion < 4) {
      await _createTimeSessionsTable(database, _temporaryTimeSessionsTable);
      await database.execute('''
        INSERT INTO $_temporaryTimeSessionsTable (
          id,
          tracker_id,
          session_date,
          duration_seconds,
          is_manual,
          started_at,
          ended_at
        )
        SELECT
          id,
          tracker_id,
          substr(started_at, 1, 10),
          CASE
            WHEN ended_at IS NULL THEN 0
            ELSE CAST(strftime('%s', ended_at) AS INTEGER) - CAST(strftime('%s', started_at) AS INTEGER)
          END,
          0,
          started_at,
          ended_at
        FROM $_timeSessionsTable
      ''');
      await database.execute('DROP TABLE $_timeSessionsTable');
      await database.execute(
        'ALTER TABLE $_temporaryTimeSessionsTable RENAME TO $_timeSessionsTable',
      );
    }
  }

  Future<void> _createTimeSessionsTable(
    sqflite.Database database, [
    String tableName = _timeSessionsTable,
  ]) async {
    await database.execute('''
      CREATE TABLE $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tracker_id INTEGER NOT NULL,
        session_date TEXT NOT NULL,
        duration_seconds INTEGER NOT NULL,
        is_manual INTEGER NOT NULL,
        started_at TEXT,
        ended_at TEXT
      )
    ''');
  }

  Future<void> _createTimeTrackerGoalsTable(sqflite.Database database) async {
    await database.execute('''
      CREATE TABLE $_timeTrackerGoalsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tracker_id INTEGER NOT NULL,
        daily_goal_seconds INTEGER NOT NULL,
        effective_date TEXT NOT NULL
      )
    ''');
  }

  Future<Tracker> createTracker({
    required String name,
    required String type,
  }) async {
    final database = await this.database;
    final existingTrackers = await database.query(
      _trackersTable,
      columns: ['id'],
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );

    if (existingTrackers.isNotEmpty) {
      throw DuplicateTrackerNameException();
    }

    final tracker = Tracker(name: name, type: type, createdAt: DateTime.now());
    final id = await database.insert(_trackersTable, tracker.toMap());

    return Tracker(
      id: id,
      name: tracker.name,
      type: tracker.type,
      createdAt: tracker.createdAt,
    );
  }

  Future<List<Tracker>> getTrackers() async {
    final maps = await (await database).query(
      _trackersTable,
      orderBy: 'name COLLATE NOCASE ASC',
    );

    return maps.map(Tracker.fromMap).toList();
  }

  Future<void> deleteTracker(int id) async {
    final database = await this.database;
    await database.transaction((transaction) async {
      await transaction.delete(
        _timeSessionsTable,
        where: 'tracker_id = ?',
        whereArgs: [id],
      );
      await transaction.delete(
        _timeTrackerGoalsTable,
        where: 'tracker_id = ?',
        whereArgs: [id],
      );
      await transaction.delete(
        _trackersTable,
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  Future<TimeSession?> getRunningTimeSession(int trackerId) async {
    final maps = await (await database).query(
      _timeSessionsTable,
      where: 'tracker_id = ? AND is_manual = 0 AND ended_at IS NULL',
      whereArgs: [trackerId],
      orderBy: 'started_at DESC',
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return TimeSession.fromMap(maps.first);
  }

  Future<TimeSession> startTimeSession(int trackerId) async {
    final startedAt = DateTime.now();
    final id = await (await database).insert(_timeSessionsTable, {
      'tracker_id': trackerId,
      'session_date': _formatDate(startedAt),
      'duration_seconds': 0,
      'is_manual': 0,
      'started_at': startedAt.toIso8601String(),
      'ended_at': null,
    });

    return TimeSession(
      id: id,
      trackerId: trackerId,
      date: DateTime(startedAt.year, startedAt.month, startedAt.day),
      duration: Duration.zero,
      isManual: false,
      startedAt: startedAt,
    );
  }

  Future<void> stopTimeSession(int sessionId) async {
    final database = await this.database;
    final sessions = await database.query(
      _timeSessionsTable,
      columns: ['started_at'],
      where: 'id = ?',
      whereArgs: [sessionId],
      limit: 1,
    );
    if (sessions.isEmpty) {
      return;
    }

    final startedAt = DateTime.parse(sessions.first['started_at'] as String);
    final endedAt = DateTime.now();
    await database.update(
      _timeSessionsTable,
      {
        'ended_at': endedAt.toIso8601String(),
        'duration_seconds': endedAt.difference(startedAt).inSeconds,
      },
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<void> createManualTimeSession({
    required int trackerId,
    required Duration duration,
  }) async {
    await (await database).insert(_timeSessionsTable, {
      'tracker_id': trackerId,
      'session_date': _formatDate(DateTime.now()),
      'duration_seconds': duration.inSeconds,
      'is_manual': 1,
      'started_at': null,
      'ended_at': null,
    });
  }

  Future<void> deleteTimeSession(int sessionId) async {
    await (await database).delete(
      _timeSessionsTable,
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<List<TimeSession>> getTodayCompletedTimeSessions(int trackerId) async {
    final maps = await (await database).query(
      _timeSessionsTable,
      where:
          'tracker_id = ? AND session_date = ? AND (is_manual = 1 OR ended_at IS NOT NULL)',
      whereArgs: [trackerId, _formatDate(DateTime.now())],
      orderBy: 'id DESC',
    );

    return maps.map(TimeSession.fromMap).toList();
  }

  Future<Map<DateTime, Duration>> getTimeSessionDurationsByDate({
    required int trackerId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final maps = await (await database).rawQuery(
      '''
        SELECT session_date, SUM(duration_seconds) AS total_seconds
        FROM $_timeSessionsTable
        WHERE tracker_id = ? AND session_date >= ? AND session_date <= ?
        GROUP BY session_date
      ''',
      [trackerId, _formatDate(startDate), _formatDate(endDate)],
    );

    return {
      for (final map in maps)
        DateTime.parse(map['session_date'] as String): Duration(
          seconds: map['total_seconds'] as int,
        ),
    };
  }

  Future<void> createTimeTrackerGoal({
    required int trackerId,
    required Duration dailyGoal,
    required DateTime effectiveDate,
  }) async {
    await (await database).insert(_timeTrackerGoalsTable, {
      'tracker_id': trackerId,
      'daily_goal_seconds': dailyGoal.inSeconds,
      'effective_date': _formatDate(effectiveDate),
    });
  }

  Future<TimeTrackerGoal?> getTimeTrackerGoalForDate(
    int trackerId,
    DateTime date,
  ) async {
    final maps = await (await database).query(
      _timeTrackerGoalsTable,
      where: 'tracker_id = ? AND effective_date <= ?',
      whereArgs: [trackerId, _formatDate(date)],
      orderBy: 'effective_date DESC, id DESC',
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return TimeTrackerGoal.fromMap(maps.first);
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
