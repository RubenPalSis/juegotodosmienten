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

    // TODO: Recibir datos reales como argumento (equipo ganador, jugadores)
    const String winningTeam = 'Inocentes'; // Placeholder
    final List<String> winningPlayers = ['Evelyn', 'Carlos', 'Sofía', 'David']; // Placeholder
    final Color winningTeamColor = Colors.green.shade600; // Placeholder

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            // Winning Team Announcement
            Expanded(
              flex: 2,
              child: Container(
                color: theme.colorScheme.surface.withOpacity(0.5),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.emoji_events_outlined,
                      size: 150,
                      color: winningTeamColor,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      localizations.translate('victory').toUpperCase(),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      localizations.translate('winners').replaceAll('[TEAM]', winningTeam).toUpperCase(),
                      style: theme.textTheme.displayMedium?.copyWith(
                        color: winningTeamColor,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const VerticalDivider(width: 1, thickness: 1),

            // Winning Players List & Actions
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${localizations.translate('winning_players')}:',
                      style: theme.textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: ListView.builder(
                        itemCount: winningPlayers.length,
                        itemBuilder: (context, index) {
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Center(
                                child: Text(
                                  winningPlayers[index],
                                  style: theme.textTheme.titleLarge,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                       style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        textStyle: theme.textTheme.titleLarge,
                      ),
                      onPressed: () {
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
          ],
        ),
      ),
    );
  }
}
