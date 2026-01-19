// widgets/email_test_widget.dart
import 'package:flutter/material.dart';
import '../services/email_service.dart';

class EmailTestWidget extends StatefulWidget {
  const EmailTestWidget({super.key});

  @override
  State<EmailTestWidget> createState() => _EmailTestWidgetState();
}

class _EmailTestWidgetState extends State<EmailTestWidget> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  bool _isSending = false;
  bool _codeSent = false;
  String _statusMessage = '';

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendTestEmail() async {
    if (_emailController.text.isEmpty) {
      _showMessage('Por favor ingresa un email válido', isError: true);
      return;
    }

    setState(() {
      _isSending = true;
      _statusMessage = 'Enviando código...';
    });

    final success = await EmailService.sendVerificationCode(_emailController.text);

    setState(() {
      _isSending = false;
      _codeSent = success;
      _statusMessage = success
          ? '✅ Código enviado! Revisa tu email'
          : '❌ Error enviando código';
    });
  }

  Future<void> _verifyCode() async {
    if (_codeController.text.isEmpty) {
      _showMessage('Ingresa el código recibido', isError: true);
      return;
    }

    final isValid = EmailService.verifyCode(_emailController.text, _codeController.text);

    _showMessage(
      isValid ? '✅ Código válido! Cuenta vinculada' : '❌ Código inválido',
      isError: !isValid,
    );

    if (isValid) {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.of(context).pop();
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prueba de Email SMTP'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Email Input
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email de destino',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),

            const SizedBox(height: 20),

            // Send Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSending ? null : _sendTestEmail,
                icon: _isSending
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Icon(Icons.send),
                label: Text(_codeSent ? 'Reenviar código' : 'Enviar código'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Status Message
            if (_statusMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _statusMessage.contains('✅')
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _statusMessage.contains('✅')
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _statusMessage.contains('✅')
                          ? Icons.check_circle
                          : Icons.error,
                      color: _statusMessage.contains('✅')
                          ? Colors.green
                          : Colors.red,
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_statusMessage)),
                  ],
                ),
              ),

            const SizedBox(height: 30),

            // Code Input (only if code sent)
            if (_codeSent) ...[
              TextField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Código de verificación',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                maxLength: 6,
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _verifyCode,
                  icon: const Icon(Icons.verified),
                  label: const Text('Verificar código'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
            ],

            const Spacer(),

            // Server Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📡 Configuración SMTP:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Servidor: smtp.gmail.com:587'),
                  Text('SSL/TLS: STARTTLS'),
                  Text('Autenticación: true'),
                  const SizedBox(height: 8),
                  Text(
                    '⚠️ Nota: Esta es una implementación directa SMTP desde Flutter',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}