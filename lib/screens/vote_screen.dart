
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
  String? _selectedPlayer;

  // TODO: Cargar la lista real de jugadores vivos
  final List<String> _players = ['Jugador 1', 'Jugador 2', 'Jugador 3', 'Jugador 4'];

  void _vote() {
    if (_selectedPlayer != null) {
      // TODO: Enviar el voto a Firestore
      NavigationService.pushReplacementNamed(RoundResultScreen.routeName, arguments: _selectedPlayer);
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
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                localizations.translate('who_is_the_impostor'),
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  itemCount: _players.length,
                  itemBuilder: (context, index) {
                    final player = _players[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: RadioListTile<String>(
                        title: Text(player),
                        value: player,
                        groupValue: _selectedPlayer,
                        onChanged: (value) {
                          setState(() {
                            _selectedPlayer = value;
                          });
                        },
                        activeColor: theme.colorScheme.primary,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _selectedPlayer != null ? _vote : null,
                child: const Text('Votar'), // TODO: Localizar
              ),
            ],
          ),
        ),
      ),
    );
  }
}
