import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'models/user.dart';
import 'models/activity.dart';
import 'models/sleep_log.dart';
import 'models/meal.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._int();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._int();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'health_app.db');
    return await openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Helper to add a column safely only if it does not already exist
  Future<void> _addColumnIfNotExists(Database db, String table, String column, String type) async {
    try {
      final List<Map<String, dynamic>> columns = await db.rawQuery("PRAGMA table_info($table)");
      final bool exists = columns.any((c) => c['name'] == column);
      if (!exists) {
        await db.execute('ALTER TABLE $table ADD COLUMN $column $type');
      }
    } catch (e) {
      print("Lỗi khi thêm cột $column vào bảng $table: $e");
    }
  }

  // ===== SCHEMA VERSION 1 → 2 → 3 → 4 MIGRATION =====
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Thêm cột mới vào users
      await _addColumnIfNotExists(db, 'users', 'weight', 'REAL');
      await _addColumnIfNotExists(db, 'users', 'blood_type', 'TEXT');
      // Thêm cột heart_rate vào body_measurements
      await _addColumnIfNotExists(db, 'body_measurements', 'heart_rate', 'INTEGER');
    }
    if (oldVersion < 3) {
      await _addColumnIfNotExists(db, 'users', 'avatar', 'TEXT');
    }
    if (oldVersion < 4) {
      await _addColumnIfNotExists(db, 'goals', 'status', 'TEXT');
    }
  }

  // ===== SCHEMA TẠO MỚI (version 3) =====
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users(
        user_id    INTEGER PRIMARY KEY AUTOINCREMENT,
        email      TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        name       TEXT,
        date_of_birth TEXT,
        gender     TEXT,
        height     REAL,
        weight     REAL,
        blood_type TEXT,
        avatar     TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE goals(
        goal_id      INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id      INTEGER NOT NULL,
        goal_type    TEXT NOT NULL,
        target_value REAL NOT NULL,
        start_date   TEXT,
        end_date     TEXT,
        status       TEXT,
        FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE activities(
        activity_id     INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id         INTEGER NOT NULL,
        date            TEXT NOT NULL,
        steps           INTEGER DEFAULT 0,
        distance        REAL    DEFAULT 0,
        calories_burned INTEGER DEFAULT 0,
        source          TEXT,
        FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE sleeps(
        sleep_id      INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id       INTEGER NOT NULL,
        date          TEXT NOT NULL,
        start_time    TEXT NOT NULL,
        end_time      TEXT NOT NULL,
        duration      INTEGER,
        quality_score INTEGER,
        FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE foods(
        food_id  INTEGER PRIMARY KEY AUTOINCREMENT,
        name     TEXT NOT NULL,
        calories INTEGER NOT NULL,
        protein  REAL NOT NULL,
        carbs    REAL NOT NULL,
        fat      REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE nutrition_logs(
        log_id    INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id   INTEGER NOT NULL,
        date      TEXT NOT NULL,
        meal_type TEXT NOT NULL,
        food_id   INTEGER NOT NULL,
        quantity  REAL NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
        FOREIGN KEY (food_id) REFERENCES foods(food_id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE body_measurements(
        measurement_id   INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id          INTEGER NOT NULL,
        date             TEXT NOT NULL,
        weight           REAL,
        body_fat_percentage REAL,
        blood_pressure   TEXT,
        blood_glucose    REAL,
        heart_rate       INTEGER,
        FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE mood_entries(
        mood_id    INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id    INTEGER NOT NULL,
        date       TEXT NOT NULL,
        mood_score INTEGER NOT NULL,
        notes      TEXT,
        FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE reminders(
        reminder_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id     INTEGER NOT NULL,
        type        TEXT NOT NULL,
        time        TEXT NOT NULL,
        is_enabled  INTEGER DEFAULT 1,
        FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> close() async {
    if (_database != null) await _database!.close();
  }

  // ===================================================
  // USERS
  // ===================================================

  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert('users', user.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<User?> getUserByEmail(String email) async {
    final db = await database;
    final maps = await db.query('users', where: 'email = ?', whereArgs: [email]);
    if (maps.isNotEmpty) return User.fromMap(maps.first);
    return null;
  }

  Future<User?> getUserById(int userId) async {
    final db = await database;
    final maps = await db.query('users', where: 'user_id = ?', whereArgs: [userId]);
    if (maps.isNotEmpty) return User.fromMap(maps.first);
    return null;
  }

  Future<int> updateUser(User user) async {
    final db = await database;
    return await db.update('users', user.toMap(),
        where: 'user_id = ?', whereArgs: [user.userId]);
  }

  Future<List<User>> getAllUsers() async {
    final db = await database;
    final maps = await db.query('users');
    return maps.map((m) => User.fromMap(m)).toList();
  }

  // ===================================================
  // ACTIVITIES
  // ===================================================

  Future<int> insertActivity(Activity activity) async {
    final db = await database;
    return await db.insert('activities', activity.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Lấy activity của ngày hôm nay
  Future<Activity?> getTodayActivity(int userId) async {
    final db = await database;
    final today = _today();
    final maps = await db.query('activities',
        where: 'user_id = ? AND date = ?',
        whereArgs: [userId, today],
        orderBy: 'activity_id DESC',
        limit: 1);
    if (maps.isNotEmpty) return Activity.fromMap(maps.first);
    return null;
  }

  /// Lấy 7 ngày gần nhất
  Future<List<Activity>> getRecentActivities(int userId, {int days = 7}) async {
    final db = await database;
    final maps = await db.query('activities',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'date DESC',
        limit: days);
    return maps.map((m) => Activity.fromMap(m)).toList();
  }

  Future<int> upsertTodayActivity(Activity activity) async {
    final existing = await getTodayActivity(activity.userId);
    if (existing != null) {
      final db = await database;
      return await db.update(
        'activities',
        activity.toMap(),
        where: 'activity_id = ?',
        whereArgs: [existing.activityId],
      );
    }
    return await insertActivity(activity);
  }

  // ===================================================
  // SLEEP
  // ===================================================

  Future<int> insertSleep(SleepLog sleep) async {
    final db = await database;
    return await db.insert('sleeps', sleep.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<SleepLog?> getLastSleep(int userId) async {
    final db = await database;
    final maps = await db.query('sleeps',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'date DESC, sleep_id DESC',
        limit: 1);
    if (maps.isNotEmpty) return SleepLog.fromMap(maps.first);
    return null;
  }

  Future<List<SleepLog>> getRecentSleeps(int userId, {int days = 7}) async {
    final db = await database;
    final maps = await db.query('sleeps',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'date DESC',
        limit: days);
    return maps.map((m) => SleepLog.fromMap(m)).toList();
  }

  // ===================================================
  // BODY MEASUREMENTS
  // ===================================================

  Future<int> insertBodyMeasurement(Map<String, dynamic> measurement) async {
    final db = await database;
    return await db.insert('body_measurements', measurement,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getLatestBodyMeasurement(int userId) async {
    final db = await database;
    final result = await db.query('body_measurements',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'date DESC, measurement_id DESC',
        limit: 1);
    if (result.isNotEmpty) return result.first;
    return null;
  }

  Future<List<Map<String, dynamic>>> getBodyMeasurements(int userId) async {
    final db = await database;
    return await db.query(
      'body_measurements',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date ASC',
    );
  }

  Future<int> deleteBodyMeasurement(int measurementId) async {
    final db = await database;
    return await db.delete(
      'body_measurements',
      where: 'measurement_id = ?',
      whereArgs: [measurementId],
    );
  }

  Future<int?> getLatestHeartRate(int userId) async {
    final meas = await getLatestBodyMeasurement(userId);
    if (meas != null && meas['heart_rate'] != null) {
      return meas['heart_rate'] as int;
    }
    return null;
  }

  // ===================================================
  // NUTRITION
  // ===================================================

  Future<int> insertMealLog(
      int userId, String mealType, String foodName, int calories,
      {double protein = 0, double carbs = 0, double fat = 0}) async {
    final db = await database;
    final foodId = await db.insert('foods', {
      'name': foodName,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    });
    return await db.insert('nutrition_logs', {
      'user_id': userId,
      'date': _today(),
      'meal_type': mealType,
      'food_id': foodId,
      'quantity': 1.0,
    });
  }

  Future<List<Meal>> getMealsForDate(int userId, String date) async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT nl.log_id, nl.user_id, nl.date, nl.meal_type,
             f.name AS food_name, f.calories, f.protein, f.carbs, f.fat
      FROM nutrition_logs nl
      JOIN foods f ON nl.food_id = f.food_id
      WHERE nl.user_id = ? AND nl.date = ?
      ORDER BY nl.log_id ASC
    ''', [userId, date]);
    return maps.map((m) => Meal.fromMap(m)).toList();
  }

  Future<int> getMealCountToday(int userId) async {
    final db = await database;
    final count = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM nutrition_logs WHERE user_id = ? AND date = ?',
        [userId, _today()]));
    return count ?? 0;
  }

  Future<int> deleteMeal(int logId) async {
    final db = await database;
    return await db.delete('nutrition_logs',
        where: 'log_id = ?', whereArgs: [logId]);
  }

  // ===================================================
  // MOOD
  // ===================================================

  Future<int> insertMoodEntry(Map<String, dynamic> moodEntry) async {
    final db = await database;
    return await db.insert('mood_entries', moodEntry,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getLatestMoodEntry(int userId) async {
    final db = await database;
    final result = await db.query('mood_entries',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'date DESC, mood_id DESC',
        limit: 1);
    if (result.isNotEmpty) return result.first;
    return null;
  }

  // ===================================================
  // GOALS
  // ===================================================

  Future<int> insertGoal(Map<String, dynamic> goal) async {
    final db = await database;
    return await db.insert('goals', goal,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getActiveGoal(int userId) async {
    final db = await database;
    final result = await db.query('goals',
        where: 'user_id = ? AND status = ?',
        whereArgs: [userId, 'ACTIVE'],
        orderBy: 'goal_id DESC',
        limit: 1);
    if (result.isNotEmpty) return result.first;
    return null;
  }

  Future<List<Map<String, dynamic>>> getGoalsByUser(int userId) async {
    final db = await database;
    return await db.query('goals',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'goal_id DESC');
  }

  Future<int> deleteGoal(int goalId) async {
    final db = await database;
    return await db.delete('goals',
        where: 'goal_id = ?',
        whereArgs: [goalId]);
  }

  // ===================================================
  // HELPERS
  // ===================================================

  String _today() => DateTime.now().toIso8601String().split('T')[0];
}
