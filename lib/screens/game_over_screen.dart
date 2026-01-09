
import 'package:flutter/material.dart';

import '../services/app_localizations.dart';
import '../services/navigation_service.dart';
import 'home_screen.dart';

class GameOverScreen extends StatelessWidget {
  static const routeName = '/game_over';

  const GameOverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // TODO: Recibir el equipo ganador como argumento de la ruta
    const String winningTeam = 'Inocentes'; // Placeholder

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('game_over')),
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
                Icon(
                  Icons.emoji_events_outlined,
                  size: 80,
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(height: 24),
                Text(
                  localizations.translate('game_has_ended'),
                  style: theme.textTheme.displaySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  localizations.translate('winners').replaceAll('[TEAM]', winningTeam), // TODO: Mejorar reemplazo
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                ElevatedButton(
                  onPressed: () {
                    // Navegar a la pantalla de inicio, eliminando todas las pantallas anteriores
                    NavigationService.navigatorKey.currentState?.pushNamedAndRemoveUntil(
                      HomeScreen.routeName, 
                      (route) => false,
                    );
                  },
                  child: Text(localizations.translate('back_to_home')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
