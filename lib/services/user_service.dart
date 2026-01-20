import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './firestore_service.dart';
import '../models/user_model.dart';

class UserService with ChangeNotifier {
  static const String _aliasKey = 'user_alias';

  final FirestoreService _firestoreService = FirestoreService();
  User? _currentUser;
  bool _isLoading = true;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get hasUser => _currentUser != null;

  int get level => _calculateLevel(currentUser?.totalExp ?? 0);

  UserService() {
    loadUser();
  }

  Future<void> loadUser() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    String? alias = prefs.getString(_aliasKey);

    if (alias != null) {
      _currentUser = await _firestoreService.getUserByAlias(alias);
    } else {
      _currentUser = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> createUser(String alias) async {
    _isLoading = true;
    notifyListeners();

    await _firestoreService.createUser(alias);
    _currentUser = await _firestoreService.getUserByAlias(alias);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_aliasKey, alias);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateUserEmail(String email) async {
    if (_currentUser != null) {
      await _firestoreService.updateUserEmail(_currentUser!.alias, email);
      // Actualizar el estado local
      _currentUser = await _firestoreService.getUserByAlias(_currentUser!.alias);
      notifyListeners();
    }
  }

  Future<void> updateUserCoins({int? gold, int? bronze}) async {
    if (_currentUser != null) {
      await _firestoreService.updateUserCoins(_currentUser!.alias, gold: gold, bronze: bronze);
      _currentUser = await _firestoreService.getUserByAlias(_currentUser!.alias);
      notifyListeners();
    }
  }

  /// Intercambia monedas de bronce por monedas de oro.
  Future<bool> exchangeBronzeForGold(int bronzeAmount, int goldAmount) async {
    if (_currentUser == null || _currentUser!.bronzeCoins < bronzeAmount) {
      return false; // No tiene suficientes monedas
    }

    // Realiza el intercambio de forma atómica en la base de datos
    await _firestoreService.updateUserCoins(
      _currentUser!.alias,
      bronze: -bronzeAmount, // Resta bronce
      gold: goldAmount,       // Suma oro
    );

    // Refresca los datos del usuario para que la UI se actualice
    await loadUser();
    return true;
  }

  int _calculateLevel(int totalExp) {
    if (totalExp < 100) return 1;
    if (totalExp < 300) return 2;
    if (totalExp < 600) return 3;
    // ... y así sucesivamente
    return 4;
  }
}
