
import 'package:flutter/material.dart';

import '../services/app_localizations.dart';
import '../services/navigation_service.dart';
import 'day_clue_screen.dart';

class NightActionScreen extends StatelessWidget {
  static const routeName = '/night_action';

  const NightActionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // TODO: Recibir el rol del jugador para mostrar la acción correcta
    const bool isImpostor = true; // Placeholder

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fase de Noche'), // TODO: Localizar
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                localizations.translate('perform_secret_action'),
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Contenido dinámico según el rol
              Expanded(
                child: isImpostor
                    ? _buildImpostorAction(context)
                    : _buildWaitingAction(context),
              ),

              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  // TODO: Enviar la acción a Firestore
                  NavigationService.pushReplacementNamed(DayClueScreen.routeName);
                },
                child: const Text('Confirmar'), // TODO: Localizar
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget para la acción del Impostor
  Widget _buildImpostorAction(BuildContext context) {
    // TODO: Cargar la lista real de jugadores
    final List<String> players = ['Jugador 1', 'Jugador 2', 'Jugador 3'];

    return ListView.builder(
      itemCount: players.length,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            title: Text(players[index]),
            onTap: () {
              // TODO: Implementar la selección del jugador
            },
          ),
        );
      },
    );
  }

  // Widget para jugadores que no tienen acción principal
  Widget _buildWaitingAction(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shield_moon_outlined, size: 64),
          const SizedBox(height: 16),
          Text(
            'Los demás están realizando sus acciones...', // TODO: Localizar
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
