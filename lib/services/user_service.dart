import 'package:flutter/material.dart';

import '../models/user_model.dart' as user_model;
import 'database_service.dart';

class UserService with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  user_model.User? _currentUser;
  int _level = 1;
  bool _isLoading = true;

  // Constants
  static const double expPerLevel = 150.0;

  // Getters
  user_model.User? get currentUser => _currentUser;
  int get level => _level;
  bool get hasUser => _currentUser != null;
  bool get isLoading => _isLoading;

  double get expForNextLevel => expPerLevel;
  double get expInCurrentLevel {
    if (_currentUser == null) return 0;
    return _currentUser!.totalExp % expPerLevel;
  }

  UserService() {
    loadUser();
  }

  Future<void> loadUser() async {
    _isLoading = true;
    notifyListeners();

    _currentUser = await _dbService.getUser();
    if (_currentUser != null) {
      _calculateLevel();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> createUser(String alias, String uid) async {
    _currentUser = await _dbService.createUser(alias, uid);
    _calculateLevel();
    notifyListeners();
  }

  Future<void> addExp(int amount) async {
    if (_currentUser == null) return;

    final newExp = _currentUser!.totalExp + amount;
    await _dbService.updateUserExp(newExp);

    // Update local state directly
    _currentUser = user_model.User(
      id: _currentUser!.id,
      uid: _currentUser!.uid,
      alias: _currentUser!.alias,
      totalExp: newExp,
      selectedCharacter: _currentUser!.selectedCharacter,
      goldCoins: _currentUser!.goldCoins,
      bronzeCoins: _currentUser!.bronzeCoins,
    );
    _calculateLevel();
    notifyListeners();
  }

  Future<void> updateCharacter(String characterFile) async {
    if (_currentUser == null) return;

    await _dbService.updateSelectedCharacter(characterFile);

    _currentUser = user_model.User(
      id: _currentUser!.id,
      uid: _currentUser!.uid,
      alias: _currentUser!.alias,
      totalExp: _currentUser!.totalExp,
      selectedCharacter: characterFile,
      goldCoins: _currentUser!.goldCoins,
      bronzeCoins: _currentUser!.bronzeCoins,
    );
    notifyListeners();
  }

  Future<bool> exchangeBronzeForGold(int bronzeAmount, int goldAmount) async {
    if (_currentUser == null || _currentUser!.bronzeCoins < bronzeAmount) {
      return false;
    }

    final newBronzeCoins = _currentUser!.bronzeCoins - bronzeAmount;
    final newGoldCoins = _currentUser!.goldCoins + goldAmount;

    await _dbService.updateUserCoins(newGoldCoins, newBronzeCoins);

    _currentUser = user_model.User(
      id: _currentUser!.id,
      uid: _currentUser!.uid,
      alias: _currentUser!.alias,
      totalExp: _currentUser!.totalExp,
      selectedCharacter: _currentUser!.selectedCharacter,
      goldCoins: newGoldCoins,
      bronzeCoins: newBronzeCoins,
    );
    notifyListeners();
    return true;
  }

  void _calculateLevel() {
    if (_currentUser == null) return;
    _level = (_currentUser!.totalExp / expPerLevel).floor() + 1;
  }
}
