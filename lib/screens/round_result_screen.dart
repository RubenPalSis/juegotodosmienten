import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import '../services/app_localizations.dart';
import '../services/navigation_service.dart';
import '../services/user_service.dart';
import 'day_clue_screen.dart';
// import 'game_over_screen.dart';

class RoundResultScreen extends StatefulWidget {
  static const routeName = '/round_result';

  const RoundResultScreen({super.key});

  @override
  State<RoundResultScreen> createState() => _RoundResultScreenState();
}

class _RoundResultScreenState extends State<RoundResultScreen> {
  bool _showRole = false;

  @override
  void initState() {
    super.initState();
    // Reveal the role after a short delay
    Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showRole = true);
    });

    // Navigate to the next screen after a longer delay
    Timer(const Duration(seconds: 7), () {
      if (mounted) {
        // TODO: Implement logic to check if the game is over.
        // If game over -> NavigationService.pushReplacementNamed(GameOverScreen.routeName);
        // Else -> start next round (night phase)
        NavigationService.pushReplacementNamed(DayClueScreen.routeName); // Placeholder for now
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // TODO: Recibir un objeto jugador completo con alias, rol y modelo de personaje
    final eliminatedPlayerAlias = ModalRoute.of(context)!.settings.arguments as String? ?? 'Nadie';
    const wasImpostor = false; // Placeholder
    final characterFile = context.read<UserService>().currentUser?.selectedCharacter ?? 'robot.glb'; // Placeholder

    final revealText = wasImpostor
        ? localizations.translate('was_an_impostor')
        : localizations.translate('was_not_an_impostor');

    final revealColor = wasImpostor ? theme.colorScheme.error : Colors.green.shade400;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$eliminatedPlayerAlias ha sido expulsado.', // TODO: Localizar
                style: theme.textTheme.headlineLarge?.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Grayscale model of the eliminated player
                    ColorFiltered(
                      colorFilter: const ColorFilter.matrix([
                        0.2126, 0.7152, 0.0722, 0,
                        0.2126, 0.7152, 0.0722, 0,
                        0.2126, 0.7152, 0.0722, 0,
                        0,      0,      0,      1,
                      ]),
                      child: ModelViewer(
                        src: 'assets/models/$characterFile',
                        alt: 'Personaje eliminado',
                        cameraControls: false,
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                    // Role reveal text that fades in
                    AnimatedOpacity(
                      opacity: _showRole ? 1.0 : 0.0,
                      duration: const Duration(seconds: 1),
                      child: Container(
                         padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                         color: Colors.black.withOpacity(0.6),
                         child: Text(
                          revealText,
                          style: theme.textTheme.displaySmall?.copyWith(
                            color: revealColor,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
              const SizedBox(height: 16),
              Text(
                'Iniciando la siguiente fase...',
                style: theme.textTheme.titleMedium?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
