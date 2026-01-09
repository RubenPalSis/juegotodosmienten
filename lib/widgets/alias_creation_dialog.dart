import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/user_service.dart';

class AliasCreationDialog extends StatefulWidget {
  const AliasCreationDialog({super.key});

  @override
  State<AliasCreationDialog> createState() => _AliasCreationDialogState();
}

class _AliasCreationDialogState extends State<AliasCreationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _aliasController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isLoading = false;

  Future<void> _submitAlias() async {
    // Unfocus the text field to hide the keyboard
    _focusNode.unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      final userService = Provider.of<UserService>(context, listen: false);
      // Sign in anonymously to get a uid
      final userCredential = await FirebaseAuth.instance.signInAnonymously();
      final uid = userCredential.user?.uid;

      if (uid != null) {
        await userService.createUser(_aliasController.text.trim(), uid);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear el usuario: $e')),
        );
      }
    } finally {
      // The loading state will be handled by the parent consumer
      // so no need to setState here.
    }
  }

  @override
  void dispose() {
    _aliasController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Allow unfocusing by tapping outside the text field
      onTap: () => _focusNode.unfocus(),
      child: Scaffold(
        // Using a Scaffold to provide a better structure
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '¡Bienvenido a Todos Mienten!',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Elige un alias para empezar a jugar',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _aliasController,
                    focusNode: _focusNode,
                    decoration: const InputDecoration(labelText: 'Alias'),
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submitAlias(),
                    validator: (value) {
                      if (value == null || value.trim().length < 3) {
                        return 'El alias debe tener al menos 3 caracteres.';
                      }
                      if (RegExp(r'[^a-zA-Z0-9_]').hasMatch(value)) {
                        return 'Solo se permiten letras, números y guiones bajos.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _submitAlias,
                          child: const Text('Guardar y Entrar'),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
