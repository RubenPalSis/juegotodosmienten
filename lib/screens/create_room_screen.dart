import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/firestore_service.dart';
import '../services/user_service.dart';
import '../services/navigation_service.dart';
import 'lobby_screen.dart';

class CreateRoomScreen extends StatefulWidget {
  static const routeName = '/create-room';

  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  bool _isLoading = false;
  int _maxPlayers = 8;
  bool _isPublic = true;

  Future<void> _createAndJoinRoom() async {
    setState(() => _isLoading = true);

    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final user = Provider.of<UserService>(context, listen: false).currentUser;

    if (user == null) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Usuario no encontrado')),
      );
      return;
    }

    try {
      final roomCode = await firestoreService.createRoom(
        hostId: user.uid,
        hostData: {'uid': user.uid, 'alias': user.alias, 'isReady': true},
        maxPlayers: _maxPlayers,
        isPublic: _isPublic,
      );
      NavigationService.pushReplacementNamed(LobbyScreen.routeName, arguments: {'roomCode': roomCode});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear la sala: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Sala de Juego'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Configura tu partida',
                  style: theme.textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                _buildDropdown(),
                const SizedBox(height: 24),
                _buildSwitch(),
                const SizedBox(height: 48),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _createAndJoinRoom,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          textStyle: theme.textTheme.titleLarge,
                        ),
                        child: const Text('Crear y Entrar'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<int>(
      value: _maxPlayers,
      decoration: const InputDecoration(
        labelText: 'Número Máximo de Jugadores',
        border: OutlineInputBorder(),
      ),
      items: [6, 8, 10, 12].map((int value) {
        return DropdownMenuItem<int>(
          value: value,
          child: Text('$value jugadores'),
        );
      }).toList(),
      onChanged: (newValue) {
        if (newValue != null) {
          setState(() => _maxPlayers = newValue);
        }
      },
    );
  }

  Widget _buildSwitch() {
     return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
        ),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: SwitchListTile.adaptive(
          title: const Text('Sala Pública'),
          subtitle: const Text('Si está activado, tu sala será visible para todos.'),
          value: _isPublic,
          onChanged: (newValue) {
            setState(() => _isPublic = newValue);
          },
        ),
      ),
    );
  }
}
