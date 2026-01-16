import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/user_service.dart';
import '../services/firestore_service.dart';
import '../services/language_service.dart';
import '../services/navigation_service.dart';
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
    final langService = Provider.of<LanguageService>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final userCredential = await FirebaseAuth.instance.signInAnonymously();
      final uid = userCredential.user?.uid;

      if (uid == null) throw Exception('Authentication failed');

      final isTaken = await firestoreService.isAliasTaken(alias);
      if (isTaken) {
        messenger.showSnackBar(const SnackBar(content: Text('Este alias ya está en uso.'))); // Localized
        setState(() => _isLoading = false);
        return;
      }

      await firestoreService.createUserProfile(alias: alias, uid: uid, language: langService.appLocale.languageCode);
      
      final userService = Provider.of<UserService>(context, listen: false);
      await userService.createUser(alias, uid);

      if (widget.roomCodeToJoin != null) {
        NavigationService.pushReplacementNamed(LobbyScreen.routeName, arguments: {'roomCode': widget.roomCodeToJoin});
      } else {
        NavigationService.pushReplacementNamed(HomeScreen.routeName);
      }

    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error al crear el usuario: $e')));
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
      body: Row(
        children: [
          // Character Model Viewer
          Expanded(
            flex: 2,
            child: Container(
              color: theme.colorScheme.surface.withOpacity(0.5),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ModelViewer(
                  src: 'assets/models/robot.glb',
                  alt: 'Personaje inicial',
                  autoRotate: true,
                  cameraControls: false,
                  disableZoom: true,
                  backgroundColor: Colors.transparent,
                ),
              ),
            ),
          ),

          // Alias Form
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '¡Bienvenido a Todos Mienten!',
                      style: theme.textTheme.headlineLarge,
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
                        prefixIcon: Icon(Icons.person),
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
        ],
      ),
    );
  }
}
