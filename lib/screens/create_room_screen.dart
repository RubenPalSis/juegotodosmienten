
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/firestore_service.dart';
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

  Future<void> _createRoom(BuildContext context) async {
    setState(() => _isLoading = true);

    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final arguments = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final userProfile = arguments['userProfile'] as Map<String, dynamic>;
    final uid = arguments['uid'] as String;

    try {
      final roomCode = await firestoreService.createRoom(
        hostId: uid,
        hostData: userProfile,
        maxPlayers: _maxPlayers,
      );
      if (mounted) {
        NavigationService.pushReplacementNamed(LobbyScreen.routeName, arguments: {'roomCode': roomCode});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear la sala: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Sala'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Configura tu sala',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            DropdownButtonFormField<int>(
              initialValue: _maxPlayers,
              decoration: const InputDecoration(
                labelText: 'Jugadores Máximos',
                border: OutlineInputBorder(),
              ),
              items: [6, 8, 10, 12].map((int value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text(value.toString()),
                );
              }).toList(),
              onChanged: (int? newValue) {
                if (newValue != null) {
                  setState(() {
                    _maxPlayers = newValue;
                  });
                }
              },
            ),
            const SizedBox(height: 30),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: () => _createRoom(context),
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                    child: const Text('Crear y Unirse a la Sala'),
                  ),
          ],
        ),
      ),
    );
  }
}
