
import 'dart:async';
import 'package:flutter/material.dart';

import '../services/app_localizations.dart';
import '../services/navigation_service.dart';
import 'day_clue_screen.dart';
// import 'game_over_screen.dart'; // Import for game over condition

class RoundResultScreen extends StatefulWidget {
  static const routeName = '/round_result';

  const RoundResultScreen({super.key});

  @override
  State<RoundResultScreen> createState() => _RoundResultScreenState();
}

class _RoundResultScreenState extends State<RoundResultScreen> {

  @override
  void initState() {
    super.initState();
    // After a delay, check game state and navigate to the next screen
    Timer(const Duration(seconds: 5), () {
      // TODO: Implement logic to check if the game is over.
      // If game over -> NavigationService.pushReplacementNamed(GameOverScreen.routeName);
      // Else -> start next round
      NavigationService.pushReplacementNamed(DayClueScreen.routeName);
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Get the eliminated player from the route arguments
    final eliminatedPlayer = ModalRoute.of(context)!.settings.arguments as String?;

    // TODO: Fetch the real role of the eliminated player
    const bool wasImpostor = false; // Placeholder

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('round_result')),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  localizations.translate('player_eliminated'),
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  eliminatedPlayer ?? 'Nadie', // TODO: Localize 'Nadie'
                  style: theme.textTheme.displayMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Card(
                  color: wasImpostor ? theme.colorScheme.secondary : theme.colorScheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      wasImpostor
                          ? '¡Era un Impostor!' // TODO: Localize
                          : 'No era un Impostor.', // TODO: Localize
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: wasImpostor ? theme.colorScheme.onSecondary : theme.textTheme.titleMedium?.color
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                const CircularProgressIndicator(), // Show progress to indicate auto-navigation
              ],
            ),
          ),
        ),
      ),
    );
  }
}
