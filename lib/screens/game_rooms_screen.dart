
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/firestore_service.dart';
import '../services/navigation_service.dart';
import '../services/user_service.dart';
import 'create_room_screen.dart';
import 'lobby_screen.dart';

class GameRoomsScreen extends StatefulWidget {
  static const routeName = '/game-rooms';

  const GameRoomsScreen({super.key});

  @override
  State<GameRoomsScreen> createState() => _GameRoomsScreenState();
}

class _GameRoomsScreenState extends State<GameRoomsScreen> {
  final _roomCodeController = TextEditingController();
  bool _isLoading = false;

  Future<void> _joinRoomWithCode(BuildContext context, String roomCode) async {
    if (roomCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, introduce un código de sala.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final userService = Provider.of<UserService>(context, listen: false);
    final user = userService.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión para unirte a una sala.')),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      final playerData = {
        'uid': user.uid,
        'alias': user.alias,
      };
      final success = await firestoreService.joinGameRoom(roomCode: roomCode, playerData: playerData);

      if (success && mounted) {
        NavigationService.push(LobbyScreen.routeName, arguments: {'roomCode': roomCode});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
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
    final firestoreService = Provider.of<FirestoreService>(context);
    final user = Provider.of<UserService>(context, listen: false).currentUser;
    final bool isLoggedIn = user != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Salas de Juego')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildJoinWithCodeSection(context, isLoggedIn),
            const SizedBox(height: 24),
            const Text('Salas Públicas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: firestoreService.getPublicRooms(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No hay salas públicas disponibles.'));
                  }
                  return ListView(children: snapshot.data!.docs.map((doc) => _buildRoomTile(context, doc, isLoggedIn)).toList());
                },
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isLoggedIn
                  ? () {
                      NavigationService.push(
                        CreateRoomScreen.routeName,
                        arguments: {
                          'uid': user.uid,
                          'userProfile': {'uid': user.uid, 'alias': user.alias}
                        },
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              child: const Text('Crear Sala Nueva'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJoinWithCodeSection(BuildContext context, bool isLoggedIn) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _roomCodeController,
          decoration: const InputDecoration(labelText: 'Código de la Sala', border: OutlineInputBorder()),
          keyboardType: TextInputType.number,
          enabled: isLoggedIn,
        ),
        const SizedBox(height: 8),
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ElevatedButton(
                onPressed: isLoggedIn ? () => _joinRoomWithCode(context, _roomCodeController.text.trim()) : null,
                child: const Text('Unirse con Código'),
              ),
      ],
    );
  }

  Widget _buildRoomTile(BuildContext context, DocumentSnapshot roomSnapshot, bool isLoggedIn) {
    final room = roomSnapshot.data() as Map<String, dynamic>;
    final players = List<Map<String, dynamic>>.from(room['players'] ?? []);
    final hostId = room['hostId'];

    String hostAlias = 'Anfitrión'; // Default name
    if (hostId != null) {
      final hostPlayer = players.firstWhere(
        (p) => p['uid'] == hostId,
        orElse: () => <String, dynamic>{}, // Return empty map if not found
      );
      if (hostPlayer.isNotEmpty) {
        hostAlias = hostPlayer['alias'] ?? hostAlias;
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text("Sala de $hostAlias"),
        subtitle: Text('Jugadores: ${players.length}/${room['maxPlayers']}'),
        trailing: ElevatedButton(
          onPressed: isLoggedIn ? () => _joinRoomWithCode(context, room['roomCode']) : null,
          child: const Text('Unirse'),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _roomCodeController.dispose();
    super.dispose();
  }
}
