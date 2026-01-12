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
      // This should ideally not happen if the UI is built correctly
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Usuario no encontrado')),
      );
      return;
    }

    try {
      final roomCode = await firestoreService.createRoom(
        hostId: user.uid,
        hostData: {'uid': user.uid, 'alias': user.alias},
        maxPlayers: _maxPlayers,
        isPublic: _isPublic,
      );
      // Navigate to the lobby for the newly created room
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Sala de Juego'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            // Max Players Selector
            _buildDropdown(),
            const SizedBox(height: 24),
            // Public/Private Switch
            _buildSwitch(),
            const Spacer(),
            // Create Button
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _createAndJoinRoom,
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                    child: const Text('Crear y Entrar'),
                  ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<int>(
      initialValue: _maxPlayers,
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
    return SwitchListTile.adaptive(
      title: const Text('Sala Pública'),
      subtitle: const Text('Si está activado, otros podrán ver y unirse a tu sala.'),
      value: _isPublic,
      onChanged: (newValue) {
        setState(() => _isPublic = newValue);
      },
      contentPadding: const EdgeInsets.all(0),
    );
  }
}
