
import 'package:flutter/material.dart';

import '../services/app_localizations.dart';
import '../services/navigation_service.dart';
import 'vote_screen.dart';

class DayClueScreen extends StatelessWidget {
  static const routeName = '/day_clue';

  const DayClueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('clues_and_discussion')),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sección para el resultado de la noche
              Card(
                color: theme.colorScheme.surface.withOpacity(0.5),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Anoche no pasó nada... demasiado silencio.', // TODO: Localizar y hacer dinámico
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Sección para el chat/discusión
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'Aquí irá el chat de discusión', // TODO: Localizar e implementar
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Navegar a la pantalla de votación
                  NavigationService.pushReplacementNamed(VoteScreen.routeName);
                },
                child: const Text('Ir a Votar'), // TODO: Localizar
              ),
            ],
          ),
        ),
      ),
    );
  }
}
