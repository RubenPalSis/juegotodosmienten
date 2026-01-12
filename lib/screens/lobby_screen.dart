import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/firestore_service.dart';
import '../services/user_service.dart';

class LobbyScreen extends StatefulWidget {
  static const routeName = '/lobby';

  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  String? _roomCode;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_roomCode == null) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      _roomCode = args?['roomCode'];
    }
  }

  Future<void> _leaveRoom() async {
    final user = Provider.of<UserService>(context, listen: false).currentUser;
    if (_roomCode != null && user != null) {
      await Provider.of<FirestoreService>(context, listen: false).leaveGameRoom(roomCode: _roomCode!, userId: user.uid);
    }
  }

  @override
  void dispose() {
    _leaveRoom();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);

    if (_roomCode == null) {
      return const Scaffold(body: Center(child: Text('Error: Código de sala no encontrado.')));
    }

    return WillPopScope(
      onWillPop: () async {
        await _leaveRoom();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Sala de Espera'),
        ),
        body: StreamBuilder<DocumentSnapshot>(
          stream: firestoreService.getGameRoomStream(_roomCode!),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final roomData = snapshot.data!.data() as Map<String, dynamic>?;
            if (roomData == null) {
              // The room may have been deleted by the host
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if(mounted) Navigator.of(context).pop();
              });
              return const Center(child: Text('La sala ha sido cerrada.'));
            }

            final players = List<Map<String, dynamic>>.from(roomData['players'] ?? []);

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildRoomCodeDisplay(),
                  const SizedBox(height: 24),
                  Text(
                    'Jugadores (${players.length}/${roomData['maxPlayers']})',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Divider(),
                  _buildPlayerList(players),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRoomCodeDisplay() {
    return Column(
      children: [
        const Text('Código de la Sala:', style: TextStyle(fontSize: 18)),
        SelectableText(
          _roomCode!,
          style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildPlayerList(List<Map<String, dynamic>> players) {
    return Expanded(
      child: ListView.builder(
        itemCount: players.length,
        itemBuilder: (context, index) {
          final player = players[index];
          return Card(
            child: ListTile(
              leading: CircleAvatar(backgroundColor: Color(int.parse(player['color'].substring(1, 7), radix: 16) + 0xFF000000)),
              title: Text(player['alias'] ?? 'Jugador Desconocido'),
            ),
          );
        },
      ),
    );
  }
}
