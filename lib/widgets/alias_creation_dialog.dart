import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/user_service.dart';
import '../services/firestore_service.dart';
import '../services/language_service.dart';
import '../services/profanity_filter_service.dart'; // Import the new service

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
    _focusNode.unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    final alias = _aliasController.text.trim();
    final profanityFilter = Provider.of<ProfanityFilterService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final langService = Provider.of<LanguageService>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);

    // Step 1: Check for profanity first
    if (profanityFilter.isProfane(alias)) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Este nombre no está permitido. Por favor, elige otro.')),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Step 2: Sign in anonymously to get a user ID.
      final userCredential = await FirebaseAuth.instance.signInAnonymously();
      final uid = userCredential.user?.uid;

      if (uid == null) {
        throw Exception('No se pudo obtener un ID de usuario.');
      }

      // Step 3: Now that we are authenticated, check if the alias is taken.
      final isTaken = await firestoreService.isAliasTaken(alias);
      if (isTaken) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Este alias ya está en uso. Por favor, elige otro.')),
        );
        setState(() => _isLoading = false);
        return;
      }

      // Step 4: If the alias is free and clean, create the profiles.
      await firestoreService.createUserProfile(
        alias: alias,
        uid: uid,
        language: langService.appLocale.languageCode,
      );

      final userService = Provider.of<UserService>(context, listen: false);
      await userService.createUser(alias, uid);

    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error al crear el usuario: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
      onTap: () => _focusNode.unfocus(),
      child: Scaffold(
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
