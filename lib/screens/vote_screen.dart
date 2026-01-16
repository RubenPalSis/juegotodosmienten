import 'package:flutter/material.dart';

import '../services/app_localizations.dart';
import '../services/navigation_service.dart';
import 'round_result_screen.dart';

class VoteScreen extends StatefulWidget {
  static const routeName = '/vote';

  const VoteScreen({super.key});

  @override
  State<VoteScreen> createState() => _VoteScreenState();
}

class _VoteScreenState extends State<VoteScreen> {
  String? _selectedPlayerId;

  // TODO: Cargar la lista real de jugadores vivos desde los argumentos de la ruta o un servicio
  final List<Map<String, dynamic>> _players = [
    {'uid': '1', 'alias': 'Evelyn', 'color': '#FFC107'},
    {'uid': '2', 'alias': 'Carlos', 'color': '#4CAF50'},
    {'uid': '3', 'alias': 'Sofía', 'color': '#2196F3'},
    {'uid': '4', 'alias': 'David', 'color': '#F44336'},
    {'uid': '5', 'alias': 'Ana', 'color': '#9C27B0'},
    {'uid': '6', 'alias': 'Mateo', 'color': '#E91E63'},
  ];

  void _vote() {
    if (_selectedPlayerId != null) {
      // TODO: Enviar el voto a Firestore usando _selectedPlayerId
      final selectedAlias = _players.firstWhere((p) => p['uid'] == _selectedPlayerId)['alias'];
      NavigationService.pushReplacementNamed(RoundResultScreen.routeName, arguments: selectedAlias);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('Votación')), // TODO: Localizar
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Text(
                localizations.translate('who_is_the_impostor'),
                style: theme.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 200, // Ancho máximo de cada tarjeta de jugador
                  childAspectRatio: 3 / 2.5,  // Relación de aspecto para dar más altura
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                ),
                itemCount: _players.length,
                itemBuilder: (context, index) {
                  final player = _players[index];
                  final isSelected = player['uid'] == _selectedPlayerId;

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedPlayerId = player['uid'];
                      });
                    },
                    borderRadius: BorderRadius.circular(12.0),
                    child: Card(
                      elevation: isSelected ? 8.0 : 2.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        side: BorderSide(
                          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Color(int.parse(player['color'].substring(1, 7), radix: 16) + 0xFF000000),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            player['alias'],
                            style: theme.textTheme.titleMedium,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  textStyle: theme.textTheme.titleLarge,
                ),
                onPressed: _selectedPlayerId != null ? _vote : null,
                child: const Text('Votar'), // TODO: Localizar
              ),
            ),
          ],
        ),
      ),
    );
  }
}
