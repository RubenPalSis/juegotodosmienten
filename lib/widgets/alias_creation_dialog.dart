import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/user_service.dart';
import '../services/firestore_service.dart';
import '../services/profanity_filter_service.dart';
import '../utils/ui_helpers.dart';

class AliasCreationDialog extends StatefulWidget {
  const AliasCreationDialog({super.key});

  @override
  State<AliasCreationDialog> createState() => _AliasCreationDialogState();
}

class _AliasCreationDialogState extends State<AliasCreationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _aliasController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitAlias() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    final alias = _aliasController.text.trim();
    final profanityFilter = Provider.of<ProfanityFilterService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final userService = Provider.of<UserService>(context, listen: false);

    try {
      // 1. Comprobar si el nombre no es permitido
      if (profanityFilter.isProfane(alias)) {
        if (mounted) showCustomSnackBar(context, 'Este nombre no está permitido. Por favor, elige otro.', isError: true);
        return;
      }

      // 2. Comprobar si el alias ya existe
      final isTaken = await firestoreService.getUserByAlias(alias) != null;
      if (isTaken) {
        if (mounted) showCustomSnackBar(context, 'Este alias ya está en uso. Por favor, elige otro.', isError: true);
        return;
      }

      // 3. Si todo es correcto, crear el usuario.
      await userService.createUser(alias);

      // 4. Cerrar el diálogo si el usuario se creó correctamente.
      if (mounted) {
        Navigator.of(context).pop();
      }

    } catch (e) {
      if (mounted) showCustomSnackBar(context, 'Error al crear el usuario: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _aliasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('¡Bienvenido a Todos Mienten!', textAlign: TextAlign.center),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            const Text('Elige un alias para empezar a jugar', textAlign: TextAlign.center),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _aliasController,
                decoration: const InputDecoration(labelText: 'Alias', border: OutlineInputBorder()),
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _isLoading ? null : _submitAlias(),
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
            ),
          ],
        ),
      ),
      actions: <Widget>[
        _isLoading
            ? const Center(child: Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ))
            : TextButton(
                onPressed: _submitAlias,
                child: const Text('Guardar y Entrar'),
              ),
      ],
    );
  }
}
