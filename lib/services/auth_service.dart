// services/auth_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './email_service.dart';

class AuthService with ChangeNotifier {
  String? _userEmail;
  bool _isEmailVerified = false;

  // Claves para SharedPreferences
  static const String _emailKey = 'user_email';
  static const String _verifiedKey = 'is_email_verified';

  // Getter para el email actual
  String? get userEmail => _userEmail;
  bool get isEmailVerified => _isEmailVerified;

  AuthService() {
    loadLinkedEmail();
  }

  /// Envía código de verificación al email
  Future<bool> sendVerificationCode(String email) async {
    try {
      final success = await EmailService.sendVerificationCode(email);
      return success;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error en sendVerificationCode: $e');
      }
      return false;
    }
  }

  /// Verifica y vincula cuenta con email
  Future<bool> verifyAndLinkAccount(String email, String code) async {
    try {
      final isValid = EmailService.verifyCode(email, code);

      if (isValid) {
        await _linkEmailToUser(email);
        await EmailService.sendAccountLinkedEmail(email);
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error en verifyAndLinkAccount: $e');
      }
      return false;
    }
  }

  /// Método privado para vincular email y persistir los datos
  Future<void> _linkEmailToUser(String email) async {
    _isEmailVerified = true;
    _userEmail = email;
    await _saveLinkedEmail();
    notifyListeners();

    if (kDebugMode) {
      print('✅ Email vinculado y guardado: $email');
    }
  }

  /// Desvincula el email actual del dispositivo
  Future<void> unlinkEmail() async {
    _isEmailVerified = false;
    _userEmail = null;
    await _saveLinkedEmail(); // Guarda el estado nulo
    notifyListeners();
    if (kDebugMode) {
      print('💨 Email desvinculado.');
    }
  }

  /// Guardar email vinculado localmente
  Future<void> _saveLinkedEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_userEmail == null) {
        await prefs.remove(_emailKey);
      } else {
        await prefs.setString(_emailKey, _userEmail!);
      }
      await prefs.setBool(_verifiedKey, _isEmailVerified);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error guardando en SharedPreferences: $e');
      }
    }
  }

  /// Cargar email vinculado desde el almacenamiento local
  Future<void> loadLinkedEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _userEmail = prefs.getString(_emailKey);
      _isEmailVerified = prefs.getBool(_verifiedKey) ?? false;
      if (_userEmail != null) {
        if (kDebugMode) {
          print('📧 Email cargado desde SharedPreferences: $_userEmail');
        }
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error cargando desde SharedPreferences: $e');
      }
    }
  }

  /// Enviar email de ayuda
  Future<bool> sendHelpEmail({
    required String subject,
    required String message,
  }) async {
    try {
      // Usa el email verificado si existe, si no, un placeholder.
      final fromEmail = _userEmail ?? 'usuario.no.vinculado@email.com';

      return await EmailService.sendHelpEmail(
        fromEmail: fromEmail,
        subject: subject,
        body: message,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error enviando email de ayuda: $e');
      }
      return false;
    }
  }
}
