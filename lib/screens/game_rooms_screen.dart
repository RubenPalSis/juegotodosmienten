import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/firestore_service.dart';
import '../services/user_service.dart';
import '../services/navigation_service.dart';
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

  @override
  void initState() {
    super.initState();
    // Run cleanup when the screen is first built
    Provider.of<FirestoreService>(context, listen: false).cleanupInactiveRooms();
  }

  Future<void> _joinRoom(String roomCode, {bool isPublic = false}) async {
    if (roomCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, introduce un código de sala.')),
      );
      return;
    }

    // If trying to join a private room from the list without a code
    if (!isPublic) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Necesitas un código para entrar en una sala privada.')),
        );
        return;
    }

    setState(() => _isLoading = true);

    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final user = Provider.of<UserService>(context, listen: false).currentUser;

    if (user == null) {
      setState(() => _isLoading = false);
      return; // Should not happen
    }

    try {
      final success = await firestoreService.joinGameRoom(
        roomCode: roomCode,
        playerData: {'uid': user.uid, 'alias': user.alias},
      );
      if (success && mounted) {
        NavigationService.push(LobbyScreen.routeName, arguments: {'roomCode': roomCode});
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
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
            _buildJoinWithCodeSection(isLoggedIn),
            const SizedBox(height: 24),
            const Text('Salas Disponibles', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: firestoreService.getAllRooms(), // Use the new method
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No hay salas disponibles.'));
                  }
                  return ListView(children: snapshot.data!.docs.map((doc) => _buildRoomTile(doc, isLoggedIn)).toList());
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isLoggedIn ? () => NavigationService.push(CreateRoomScreen.routeName) : null,
        label: const Text('Crear Sala'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildJoinWithCodeSection(bool isLoggedIn) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _roomCodeController,
          decoration: const InputDecoration(labelText: 'Código de la Sala', border: OutlineInputBorder()),
          enabled: isLoggedIn,
        ),
        const SizedBox(height: 8),
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ElevatedButton(
                onPressed: isLoggedIn ? () => _joinRoom(_roomCodeController.text.trim(), isPublic: true) : null, // Code entry is always a direct attempt
                child: const Text('Unirse con Código'),
              ),
      ],
    );
  }

  Widget _buildRoomTile(DocumentSnapshot roomSnapshot, bool isLoggedIn) {
    final room = roomSnapshot.data() as Map<String, dynamic>;
    final players = List<Map<String, dynamic>>.from(room['players'] ?? []);
    final isPublic = room['isPublic'] ?? false;
    final isFull = players.length >= room['maxPlayers'];

    IconData lockIcon = Icons.lock_open;
    if (!isPublic) lockIcon = Icons.lock;
    if (isFull) lockIcon = Icons.lock;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(lockIcon),
        title: Text("Sala de ${room['hostId']}"), // Placeholder for host alias
        subtitle: Text('Jugadores: ${players.length}/${room['maxPlayers']}'),
        trailing: ElevatedButton(
          onPressed: isLoggedIn && !isFull ? () => _joinRoom(room['roomCode'], isPublic: isPublic) : null,
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
