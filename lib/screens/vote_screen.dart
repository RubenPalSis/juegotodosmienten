import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/app_localizations.dart';
import '../services/firestore_service.dart';
import '../services/navigation_service.dart';
import 'round_result_screen.dart';

class VoteScreen extends StatefulWidget {
  static const routeName = '/vote';
  final String roomCode;

  const VoteScreen({super.key, required this.roomCode});

  @override
  State<VoteScreen> createState() => _VoteScreenState();
}

class _VoteScreenState extends State<VoteScreen> {
  String? _selectedPlayerId;

  void _vote(List<Map<String, dynamic>> players) {
    if (_selectedPlayerId != null) {
      final selectedAlias =
          players.firstWhere((p) => p['uid'] == _selectedPlayerId)['alias'];
      NavigationService.pushReplacementNamed(RoundResultScreen.routeName,
          arguments: selectedAlias);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final firestoreService = Provider.of<FirestoreService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('Votación')), // TODO: Localizar
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: firestoreService.getPlayersStream(widget.roomCode),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData) {
              return const Center(child: Text('No se encontraron jugadores.'));
            }

            final players = snapshot.data!.docs
                .map((doc) => {
                      'uid': doc.id,
                      ...doc.data() as Map<String, dynamic>,
                    })
                .toList();

            return Column(
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
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 200,
                      childAspectRatio: 3 / 2.5,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                    ),
                    itemCount: players.length,
                    itemBuilder: (context, index) {
                      final player = players[index];
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
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: Color(int.parse(
                                        (player['color'] ?? '#FFC107')
                                            .substring(1, 7),
                                        radix: 16) +
                                    0xFF000000),
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
                    onPressed: _selectedPlayerId != null ? () => _vote(players) : null,
                    child: const Text('Votar'), // TODO: Localizar
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
