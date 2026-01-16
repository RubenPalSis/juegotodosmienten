import 'package:flutter/material.dart';

import '../services/app_localizations.dart';
import '../services/navigation_service.dart';
import 'vote_screen.dart';

class DayClueScreen extends StatelessWidget {
  static const routeName = '/day_clue';

  const DayClueScreen({super.key});

  // TODO: Cargar la lista real de jugadores vivos
  final List<Map<String, dynamic>> _players = const [
    {'alias': 'Evelyn', 'color': '#FFC107'},
    {'alias': 'Carlos', 'color': '#4CAF50'},
    {'alias': 'Sofía', 'color': '#2196F3'},
    {'alias': 'David', 'color': '#F44336'},
    {'alias': 'Ana', 'color': '#9C27B0'},
  ];

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
        child: Row(
          children: [
            // Chat / Discussion Area
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Center(
                    // TODO: Implementar el chat real aquí
                    child: Text(
                      'Chat de discusión del día', 
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                ),
              ),
            ),

            const VerticalDivider(width: 1, thickness: 1),

            // Info Sidebar
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Night Result
                    Card(
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

                    // Players Alive
                    Text('Jugadores Vivos:', style: theme.textTheme.titleLarge), // TODO: Localizar
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _players.length,
                        itemBuilder: (context, index) {
                          final player = _players[index];
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Color(int.parse(player['color']!.substring(1, 7), radix: 16) + 0xFF000000),
                              ),
                              title: Text(player['alias']!),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Vote Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        textStyle: theme.textTheme.titleLarge,
                      ),
                      onPressed: () {
                        NavigationService.pushReplacementNamed(VoteScreen.routeName);
                      },
                      child: const Text('Ir a Votar'), // TODO: Localizar
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
