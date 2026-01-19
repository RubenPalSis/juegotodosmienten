import 'dart:math';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:flutter/foundation.dart';

class EmailService {
  // ADVERTENCIA: Almacenar credenciales en el código es extremadamente inseguro.
  // Se utiliza según solicitud explícita. Se recomienda encarecidamente una contraseña de aplicación.
  static final _smtpServer = gmail('palaciocode@gmail.com', 'koop ohnw wjyh ftfr');

  // Almacenamiento en memoria para los códigos. En una app real, esto debería tener expiración.
  static final Map<String, String> _verificationCodes = {};

  /// Envía un código de verificación al email especificado.
  static Future<bool> sendVerificationCode(String email) async {
    final code = (100000 + Random().nextInt(900000)).toString();
    _verificationCodes[email] = code;

    final message = Message()
      ..from = const Address('palaciocode@gmail.com', 'Todos Mienten App')
      ..recipients.add(email)
      ..subject = 'Tu Código de Verificación para Todos Mienten'
      ..html = '''
        <div style="font-family: Arial, sans-serif; text-align: center; padding: 20px; border-radius: 12px; background-color: #f9f9f9;">
          <h1 style="color: #333;">Verificación de Cuenta</h1>
          <p>Usa el siguiente código para verificar tu correo electrónico en la app "Todos Mienten":</p>
          <div style="font-size: 28px; font-weight: bold; letter-spacing: 5px; background-color: #e0e0e0; padding: 15px; border-radius: 8px; display: inline-block;">
            $code
          </div>
          <p style="font-size: 12px; color: #888; margin-top: 20px;">Si no solicitaste este código, puedes ignorar este mensaje.</p>
        </div>
      ''';

    try {
      final sendReport = await send(message, _smtpServer);
      if (kDebugMode) {
        print('Email de verificación enviado: ${sendReport.toString()}');
      }
      return true;
    } on MailerException catch (e) {
      if (kDebugMode) {
        print('Error de Mailer al enviar email: $e');
        for (var p in e.problems) {
          print('Problema: ${p.code}: ${p.msg}');
        }
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error inesperado al enviar email: $e');
      }
      return false;
    }
  }

  /// Verifica si el código proporcionado es correcto para el email.
  static bool verifyCode(String email, String code) {
    if (_verificationCodes.containsKey(email) && _verificationCodes[email] == code) {
      _verificationCodes.remove(email); // El código se elimina después de usarse
      return true;
    }
    return false;
  }

  /// Envía un email de confirmación cuando la cuenta ha sido vinculada.
  static Future<void> sendAccountLinkedEmail(String email) async {
    final message = Message()
      ..from = const Address('palaciocode@gmail.com', 'Todos Mienten App')
      ..recipients.add(email)
      ..subject = '¡Tu cuenta ha sido vinculada!'
      ..html = '''
        <div style="font-family: Arial, sans-serif; padding: 20px;">
          <h1 style="color: #333;">Cuenta Vinculada Exitosamente</h1>
          <p>Hola,</p>
          <p>Tu correo electrónico ha sido vinculado correctamente a tu cuenta en <b>Todos Mienten</b>.</p>
          <p>Ahora puedes usar este correo para recuperar tu progreso en el futuro.</p>
          <p>¡Gracias por jugar!</p>
        </div>
      ''';
    try {
      await send(message, _smtpServer);
      if (kDebugMode) {
        print('Email de confirmación de vinculación enviado.');
      }
    } catch (e) {
       if (kDebugMode) {
        print('Error enviando email de confirmación: $e');
      }
    }
  }

    /// Envía un email de solicitud de ayuda al correo de soporte.
    static Future<bool> sendHelpEmail({
        required String fromEmail,
        required String subject,
        required String body,
    }) async {
        final message = Message()
            ..from = const Address('palaciocode@gmail.com', 'Todos Mienten - Ayuda')
            ..recipients.add('palaciocode@gmail.com') // Se envía a tu propio correo
            ..subject = 'Solicitud de Ayuda: $subject'
            ..html = '''
                <h1>Solicitud de Ayuda - Todos Mienten</h1>
                <p><b>De:</b> $fromEmail</p>
                <hr>
                <p><b>Mensaje:</b></p>
                <p>$body</p>
            ''';

        try {
            await send(message, _smtpServer);
            if (kDebugMode) {
              print('Email de ayuda enviado.');
            }
            return true;
        } catch (e) {
            if (kDebugMode) {
              print('Error enviando email de ayuda: $e');
            }
            return false;
        }
    }
}
