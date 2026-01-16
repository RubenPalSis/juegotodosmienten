import 'package:flutter/material.dart';

import '../services/app_localizations.dart';
import '../services/navigation_service.dart';
import 'day_clue_screen.dart';

class NightActionScreen extends StatefulWidget {
  static const routeName = '/night_action';

  const NightActionScreen({super.key});

  @override
  State<NightActionScreen> createState() => _NightActionScreenState();
}

class _NightActionScreenState extends State<NightActionScreen> {
  String? _selectedPlayerId;

  // TODO: Recibir el rol del jugador para mostrar la acción correcta y la lista de objetivos
  final bool _isImpostor = true; // Placeholder
  final List<Map<String, dynamic>> _targets = [
    {'uid': '2', 'alias': 'Carlos', 'color': '#4CAF50'},
    {'uid': '3', 'alias': 'Sofía', 'color': '#2196F3'},
    {'uid': '4', 'alias': 'David', 'color': '#F44336'},
    {'uid': '5', 'alias': 'Ana', 'color': '#9C27B0'},
  ];

  void _confirmAction() {
    if (_isImpostor && _selectedPlayerId == null) {
      // Opcional: Mostrar un snackbar si se requiere selección
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes seleccionar un objetivo.')), // TODO: Localizar
      );
      return;
    }
    // TODO: Enviar la acción a Firestore (ej. eliminar al jugador con _selectedPlayerId)
    NavigationService.pushReplacementNamed(DayClueScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('night_phase')),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.black.withOpacity(0.5),
      ),
      body: Container(
        color: Colors.black.withOpacity(0.3),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Text(
                  _isImpostor
                      ? localizations.translate('choose_your_target')
                      : localizations.translate('wait_for_dawn'),
                  style: theme.textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: _isImpostor
                    ? _buildImpostorActionGrid(context)
                    : _buildWaitingAction(context),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    textStyle: theme.textTheme.titleLarge,
                    backgroundColor: _isImpostor ? theme.colorScheme.error : null,
                  ),
                  onPressed: _confirmAction,
                  child: Text(_isImpostor
                      ? localizations.translate('confirm_elimination')
                      : localizations.translate('continue')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImpostorActionGrid(BuildContext context) {
    final theme = Theme.of(context);
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        childAspectRatio: 3 / 2.5,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
      ),
      itemCount: _targets.length,
      itemBuilder: (context, index) {
        final target = _targets[index];
        final isSelected = target['uid'] == _selectedPlayerId;

        return InkWell(
          onTap: () {
            setState(() {
              _selectedPlayerId = target['uid'];
            });
          },
          borderRadius: BorderRadius.circular(12.0),
          child: Card(
            elevation: isSelected ? 8.0 : 2.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
              side: BorderSide(
                color: isSelected ? theme.colorScheme.error : Colors.transparent,
                width: 3,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Color(int.parse(target['color'].substring(1, 7), radix: 16) + 0xFF000000),
                ),
                const SizedBox(height: 12),
                Text(
                  target['alias'],
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWaitingAction(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.nightlight_round, size: 100, color: theme.colorScheme.secondary),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              AppLocalizations.of(context)!.translate('actions_in_progress'),
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
