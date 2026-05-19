import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'models/user.dart';

class DatabaseHelper {
  // Singleton pattern: Đảm bảo chỉ có 1 instance DatabaseHelper
  // 1. Tạo một private static instance
  static final DatabaseHelper _instance = DatabaseHelper._int();

  // 2. Factory constructor để trả về instance duy nhất
  factory DatabaseHelper() => _instance;

  // 3. Private constructor, chỉ được gọi từ bên trong class này
  DatabaseHelper._int();

  static Database? _database;

  // Getter để lấy database, nếu chưa có thì khởi tạo
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Hàm khởi tạo database - ĐÃ ĐƯỢC ĐỊNH NGHĨA
  Future<Database> _initDatabase() async {
    // Xác định đường dẫn để lưu file database
    String path = join(await getDatabasesPath(), 'health_app.db');
    // Mở hoặc tạo database tại đường dẫn đó, với phiên bản (version)
    return await openDatabase(
      path,
      version: 1, // Version rất quan trọng cho việc nâng cấp sau này
      onCreate: _onCreate, // Hàm sẽ chạy lần đầu để tạo bảng
      onOpen: (db) async {
        // Kiểm tra xem đã có user nào chưa mỗi khi mở DB
        final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM users'),
        );
        if (count == 0) {
          await db.insert('users', {
            'email': 'test@example.com',
            'password_hash': 'hashed_password_here',
            'name': 'Người dùng 1',
            'date_of_birth': '1990-01-01',
            'gender': 'Male',
            'height': 170.0,
          });
        }
      },
    );
  }

  // Hàm tạo tất cả các bảng (chạy lần đầu tiên)
  Future<void> _onCreate(Database db, int version) async {
    // Tạo bảng Users
    await db.execute('''
      CREATE TABLE users(
        user_id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        name TEXT,
        date_of_birth TEXT,
        gender TEXT,
        height REAL
      )
    ''');

    // Tạo bảng Goals
    await db.execute('''
      CREATE TABLE goals(
        goal_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        goal_type TEXT NOT NULL,
        target_value REAL NOT NULL,
        start_date TEXT,
        end_date TEXT,
        FOREIGN KEY (user_id) REFERENCES users (user_id) ON DELETE CASCADE
      )
    ''');

    // Tạo bảng Activities
    await db.execute('''
      CREATE TABLE activities(
        activity_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        steps INTEGER DEFAULT 0,
        distance REAL DEFAULT 0,
        calories_burned INTEGER DEFAULT 0,
        source TEXT,
        FOREIGN KEY (user_id) REFERENCES users (user_id) ON DELETE CASCADE
      )
    ''');

    // Tạo bảng Sleeps
    await db.execute('''
      CREATE TABLE sleeps(
        sleep_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        duration INTEGER,
        quality_score INTEGER,
        FOREIGN KEY (user_id) REFERENCES users (user_id) ON DELETE CASCADE
      )
    ''');

    // Tạo bảng Foods
    await db.execute('''
      CREATE TABLE foods(
        food_id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        calories INTEGER NOT NULL,
        protein REAL NOT NULL,
        carbs REAL NOT NULL,
        fat REAL NOT NULL
      )
    ''');

    // Tạo bảng Nutrition_Logs
    await db.execute('''
      CREATE TABLE nutrition_logs(
        log_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        meal_type TEXT NOT NULL,
        food_id INTEGER NOT NULL,
        quantity REAL NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (user_id) ON DELETE CASCADE,
        FOREIGN KEY (food_id) REFERENCES foods (food_id) ON DELETE CASCADE
      )
    ''');

    // Tạo bảng Body_Measurements
    await db.execute('''
      CREATE TABLE body_measurements(
        measurement_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        weight REAL,
        body_fat_percentage REAL,
        blood_pressure TEXT,
        blood_glucose REAL,
        FOREIGN KEY (user_id) REFERENCES users (user_id) ON DELETE CASCADE
      )
    ''');

    // Tạo bảng Mood_Entries
    await db.execute('''
      CREATE TABLE mood_entries(
        mood_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        mood_score INTEGER NOT NULL,
        notes TEXT,
        FOREIGN KEY (user_id) REFERENCES users (user_id) ON DELETE CASCADE
      )
    ''');

    // Tạo bảng Reminders
    await db.execute('''
      CREATE TABLE reminders(
        reminder_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        time TEXT NOT NULL,
        is_enabled INTEGER DEFAULT 1,
        FOREIGN KEY (user_id) REFERENCES users (user_id) ON DELETE CASCADE
      )
    ''');

    // Thêm 1 user mặc định
    await db.insert('users', {
      'email': 'test@example.com',
      'password_hash': 'hashed_password_here',
      'name': 'Người dùng 1',
      'date_of_birth': '1990-01-01',
      'gender': 'Male',
      'height': 170.0,
    });
  }

  // Hàm đóng database khi không cần thiết
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
    }
  }

  // ================= CRUD cho Users =================

  // Thêm 1 User
  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Lấy tất cả Users
  Future<List<User>> getAllUsers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('users');
    return List.generate(maps.length, (i) {
      return User.fromMap(maps[i]);
    });
  }
}
