import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:provider/provider.dart';

import '../services/app_localizations.dart';
import '../services/navigation_service.dart';
import '../services/user_service.dart';
import 'night_action_screen.dart';

class RoleScreen extends StatelessWidget {
  static const routeName = '/role';

  const RoleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // TODO: Recibir el rol y descripción como argumento de la ruta
    const String playerRole = 'Impostor'; // Placeholder
    const String roleDescription = 'Tu objetivo es eliminar a los demás jugadores sin ser descubierto.'; // Placeholder

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('your_secret_role')),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Consumer<UserService>(
          builder: (context, userService, child) {
            final user = userService.currentUser;
            if (user == null) {
              return const Center(child: CircularProgressIndicator());
            }
            final characterFile = user.selectedCharacter ?? 'robot.glb';

            return Row(
              children: [
                // Character Model Viewer
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ModelViewer(
                      src: 'assets/models/$characterFile',
                      alt: 'Tu personaje',
                      autoRotate: true,
                      cameraControls: false,
                      backgroundColor: theme.scaffoldBackgroundColor,
                    ),
                  ),
                ),

                const VerticalDivider(width: 1, thickness: 1),

                // Role Information
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Card(
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              children: [
                                Text(
                                  localizations.translate('your_role_is'),
                                  style: theme.textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  playerRole, // TODO: Usar el rol real del jugador
                                  style: theme.textTheme.displayMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  roleDescription, // TODO: Usar la descripción real del rol
                                  style: theme.textTheme.bodyLarge,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            textStyle: theme.textTheme.titleLarge,
                          ),
                          onPressed: () {
                            // Navegar a la pantalla de acción nocturna
                            NavigationService.pushReplacementNamed(NightActionScreen.routeName);
                          },
                          child: const Text('Entendido'), // TODO: Localizar este texto
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
