import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/user_model.dart';

class DatabaseService {
  static const String _dbName = 'todos_mienten.db';
  static const String _userTable = 'user';
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_userTable(
        ${User.colId} INTEGER PRIMARY KEY,
        ${User.colUid} TEXT NOT NULL,
        ${User.colAlias} TEXT NOT NULL,
        ${User.colTotalExp} INTEGER NOT NULL,
        ${User.colSelectedCharacter} TEXT
      )
    ''');
  }

  Future<User?> getUser() async {
    final db = await database;
    final maps = await db.query(_userTable, limit: 1);

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<User> createUser(String alias, String uid) async {
    final db = await database;
    final user = User(id: 1, uid: uid, alias: alias, totalExp: 0, selectedCharacter: 'robot.glb');
    await db.insert(_userTable, user.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return user;
  }

  Future<void> updateUserExp(int newExp) async {
    final db = await database;
    await db.update(
      _userTable,
      {User.colTotalExp: newExp},
      where: '${User.colId} = ?',
      whereArgs: [1],
    );
  }

  Future<void> updateSelectedCharacter(String characterFile) async {
    final db = await database;
    await db.update(
      _userTable,
      {User.colSelectedCharacter: characterFile},
      where: '${User.colId} = ?',
      whereArgs: [1],
    );
  }
}
