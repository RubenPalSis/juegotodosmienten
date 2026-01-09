
import 'package:flutter/material.dart';

import '../services/app_localizations.dart';
import '../services/navigation_service.dart';
import 'night_action_screen.dart';

class RoleScreen extends StatelessWidget {
  static const routeName = '/role';

  const RoleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // TODO: Recibir el rol como argumento de la ruta
    const String playerRole = 'Impostor'; // Placeholder

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('your_secret_role')),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        Text(
                          localizations.translate('your_role_is'),
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          playerRole, // TODO: Usar el rol real del jugador
                          style: theme.textTheme.displayMedium?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        // TODO: Añadir una breve descripción del rol
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
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
      ),
    );
  }
}
