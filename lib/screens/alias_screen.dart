import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:juegotodosmienten/services/user_service.dart';
import 'package:juegotodosmienten/services/firestore_service.dart';
import 'package:juegotodosmienten/utils/ui_helpers.dart';
import 'home_screen.dart';
import 'lobby_screen.dart';

class AliasScreen extends StatefulWidget {
  static const routeName = '/alias';
  final String? roomCodeToJoin;

  const AliasScreen({super.key, this.roomCodeToJoin});

  @override
  State<AliasScreen> createState() => _AliasScreenState();
}

class _AliasScreenState extends State<AliasScreen> {
  final _formKey = GlobalKey<FormState>();
  final _aliasController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitAlias() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    final alias = _aliasController.text.trim();
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    try {
      final isTaken = await firestoreService.getUserByAlias(alias) != null;
      if (isTaken) {
        if (mounted) {
          showCustomSnackBar(context, 'Este alias ya está en uso.', isError: true);
        }
        return;
      }

      final userService = Provider.of<UserService>(context, listen: false);
      await userService.createUser(alias);

      if (mounted) {
        // Navegar a la pantalla correcta después de crear el usuario.
        if (widget.roomCodeToJoin != null) {
          Navigator.of(context).pushReplacementNamed(LobbyScreen.routeName, arguments: {'roomCode': widget.roomCodeToJoin});
        } else {
          Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
        }
      }
    } catch (e) {
      if (mounted) {
        showCustomSnackBar(context, 'Error al crear el usuario: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '¡Bienvenido a Todos Mienten!',
                    style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Elige tu alias para empezar a jugar.',
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  TextFormField(
                    controller: _aliasController,
                    decoration: const InputDecoration(
                      labelText: 'Alias',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall,
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
                  const SizedBox(height: 32),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            textStyle: theme.textTheme.titleLarge,
                          ),
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
