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
    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_userTable(
        ${User.colId} INTEGER PRIMARY KEY,
        ${User.colUid} TEXT NOT NULL,
        ${User.colAlias} TEXT NOT NULL,
        ${User.colTotalExp} INTEGER NOT NULL,
        ${User.colSelectedCharacter} TEXT,
        ${User.colGoldCoins} INTEGER NOT NULL,
        ${User.colBronzeCoins} INTEGER NOT NULL,
        ${User.colEmail} TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE $_userTable ADD COLUMN ${User.colGoldCoins} INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE $_userTable ADD COLUMN ${User.colBronzeCoins} INTEGER NOT NULL DEFAULT 0',
      );
    }
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE $_userTable ADD COLUMN ${User.colEmail} TEXT',
      );
    }
  }

  Future<void> deleteDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }

  Future<User?> getUser() async {
    final db = await database;
    final maps = await db.query(_userTable, limit: 1);

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<User> createUser(String alias, String uid, {String? email}) async {
    final db = await database;
    final user = User(
      id: 1,
      uid: uid,
      alias: alias,
      totalExp: 0,
      selectedCharacter: 'robot.glb',
      goldCoins: 100,
      bronzeCoins: 500,
      email: email,
    );
    await db.insert(
      _userTable,
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
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

  Future<void> updateUserCoins(int gold, int bronze) async {
    final db = await database;
    await db.update(
      _userTable,
      {User.colGoldCoins: gold, User.colBronzeCoins: bronze},
      where: '${User.colId} = ?',
      whereArgs: [1],
    );
  }
}
