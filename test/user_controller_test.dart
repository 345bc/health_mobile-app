import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite/sqflite.dart';
import 'package:frontend/data/controller/user_controller.dart';
import 'package:frontend/data/database_helper.dart';
import 'package:frontend/data/models/user.dart';

import 'package:frontend/data/models/end_user.dart';

class MockDatabaseHelper extends Mock implements DatabaseHelper {}
class MockDatabase extends Mock implements Database {}

void main() {
  late UserController userController;
  late MockDatabaseHelper mockDbHelper;
  late MockDatabase mockDatabase;

  setUpAll(() {
    registerFallbackValue(ConflictAlgorithm.ignore);
  });

  setUp(() {
    mockDbHelper = MockDatabaseHelper();
    mockDatabase = MockDatabase();
    userController = UserController(dbHelper: mockDbHelper);

    when(() => mockDbHelper.database).thenAnswer((_) async => mockDatabase);
  });

  final testUser = User(
    userId: 1,
    email: 'test@example.com',
    passwordHash: 'hashed_pw',
    user_name: 'Test User',
    endUser: EndUser(
      id: 1,
      name: 'Test User',
      gender: 'Nam',
      height: 175,
      weight: 70,
    ),
  );

  test('insertUser nên gọi db.insert thành công', () async {
    when(() => mockDatabase.insert('users', any(), conflictAlgorithm: any(named: 'conflictAlgorithm')))
        .thenAnswer((_) async => 1);

    final result = await userController.insertUser(testUser);
    expect(result, 1);

    verify(() => mockDatabase.insert(
          'users',
          testUser.toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        )).called(1);
  });

  test('getAllUsers nên trả về danh sách User từ db.query', () async {
    when(() => mockDatabase.query('users')).thenAnswer((_) async => [
          testUser.toMap(),
        ]);

    final result = await userController.getAllUsers();
    expect(result.length, 1);
    expect(result.first.email, 'test@example.com');
    expect(result.first.user_name, 'Test User');

    verify(() => mockDatabase.query('users')).called(1);
  });

  test('getUserByEmail nên trả về User khi tìm thấy', () async {
    when(() => mockDatabase.query(
          'users',
          where: any(named: 'where'),
          whereArgs: any(named: 'whereArgs'),
        )).thenAnswer((_) async => [testUser.toMap()]);

    final result = await userController.getUserByEmail('test@example.com');
    expect(result, isNotNull);
    expect(result!.email, 'test@example.com');

    verify(() => mockDatabase.query(
          'users',
          where: 'email = ?',
          whereArgs: ['test@example.com'],
        )).called(1);
  });

  test('getUserByEmail nên trả về null khi không tìm thấy', () async {
    when(() => mockDatabase.query(
          'users',
          where: any(named: 'where'),
          whereArgs: any(named: 'whereArgs'),
        )).thenAnswer((_) async => []);

    final result = await userController.getUserByEmail('notfound@example.com');
    expect(result, isNull);
  });

  test('updateUser nên gọi db.update thành công', () async {
    when(() => mockDatabase.update(
          'users',
          any(),
          where: any(named: 'where'),
          whereArgs: any(named: 'whereArgs'),
        )).thenAnswer((_) async => 1);

    final result = await userController.updateUser(testUser);
    expect(result, 1);

    verify(() => mockDatabase.update(
          'users',
          testUser.toMap(),
          where: 'user_id = ?',
          whereArgs: [1],
        )).called(1);
  });

  test('deleteUser nên gọi db.delete thành công', () async {
    when(() => mockDatabase.delete(
          'users',
          where: any(named: 'where'),
          whereArgs: any(named: 'whereArgs'),
        )).thenAnswer((_) async => 1);

    final result = await userController.deleteUser(1);
    expect(result, 1);

    verify(() => mockDatabase.delete(
          'users',
          where: 'user_id = ?',
          whereArgs: [1],
        )).called(1);
  });
}
