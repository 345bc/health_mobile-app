import 'package:sqflite/sqflite.dart';
import 'package:frontend/data/database_helper.dart';
import 'package:frontend/data/models/user.dart';

class UserController {
  final DatabaseHelper dbHelper = DatabaseHelper();

  // CREATE - Thêm user mới
  Future<int> insertUser(User user) async {
    final db = await dbHelper.database;
    // `conflictAlgorithm`: Xử lý nếu trùng dữ liệu (ở đây là bỏ qua)
    return await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  // READ - Lấy tất cả user (ít dùng, chủ yếu để demo)
  Future<List<User>> getAllUsers() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('users');
    // Chuyển đổi từ List<Map> sang List<User>
    return List.generate(maps.length, (i) {
      return User.fromMap(maps[i]);
    });
  }

  // READ - Lấy user bằng email
  Future<User?> getUserByEmail(String email) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ?', // Điều kiện WHERE
      whereArgs: [email], // Giá trị cho điều kiện (ngăn chặn SQL Injection)
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first); // Trả về user đầu tiên tìm thấy
    }
    return null; // Không tìm thấy
  }

  // UPDATE - Cập nhật thông tin user
  Future<int> updateUser(User user) async {
    final db = await dbHelper.database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'user_id = ?',
      whereArgs: [user.userId],
    );
  }

  // DELETE - Xóa user
  Future<int> deleteUser(int userId) async {
    final db = await dbHelper.database;
    return await db.delete('users', where: 'user_id = ?', whereArgs: [userId]);
  }
}
