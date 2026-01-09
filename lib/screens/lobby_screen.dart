
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/firestore_service.dart';
import '../services/user_service.dart';

// Helper function to convert hex color string to Color object
Color hexToColor(String code) {
  return Color(int.parse(code.substring(1, 7), radix: 16) + 0xFF000000);
}

class LobbyScreen extends StatefulWidget {
  static const routeName = '/lobby';

  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  String? _roomCode;
  late final FirestoreService _firestoreService;
  late final UserService _userService;

  @override
  void initState() {
    super.initState();
    _firestoreService = Provider.of<FirestoreService>(context, listen: false);
    _userService = Provider.of<UserService>(context, listen: false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _roomCode = args['roomCode'];
    }
  }

  @override
  void dispose() {
    _leaveRoom();
    super.dispose();
  }

  Future<void> _leaveRoom() async {
    final userId = _userService.currentUser?.uid;
    if (_roomCode != null && userId != null) {
      await _firestoreService.leaveGameRoom(
        roomCode: _roomCode!,
        userId: userId,
      );
    }
  }

  void _showColorPicker(BuildContext context, List<Map<String, dynamic>> players, String currentUserId) {
    final usedColors = players.map((p) => p['color']).toSet();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Elige tu color'),
          content: Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: _firestoreService.availableColors.map((colorHex) {
              final color = hexToColor(colorHex);
              final isUsed = usedColors.contains(colorHex);
              return GestureDetector(
                onTap: () async {
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);

                  if (!isUsed) {
                    try {
                      await _firestoreService.changePlayerColor(_roomCode!, currentUserId, colorHex);
                      navigator.pop(); // Close the dialog on success
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(content: Text(e.toString())),
                      );
                    }
                  } else {
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Este color ya está en uso.')),
                    );
                  }
                },
                child: CircleAvatar(
                  backgroundColor: color,
                  child: isUsed ? const Icon(Icons.block, color: Colors.white70) : null,
                ),
              );
            }).toList(),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cerrar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_roomCode == null) {
      return const Scaffold(body: Center(child: Text('Error: No se encontró el código de la sala.')));
    }

    final currentUserId = _userService.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Sala de Espera')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestoreService.getGameRoomStream(_roomCode!),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar la sala. Por favor, intenta de nuevo.'));
          }
          if (snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }

          final roomData = snapshot.data!.data() as Map<String, dynamic>?;
          if (roomData == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('La sala ha sido cerrada por el anfitrión.')),
                );
              }
            });
            return const Center(child: CircularProgressIndicator());
          }

          final players = List<Map<String, dynamic>>.from(roomData['players'] ?? []);

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text('Código de la Sala:', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                SelectableText(_roomCode!, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                Text('Jugadores (${players.length}/${roomData['maxPlayers']})', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: players.length,
                    itemBuilder: (context, index) {
                      final player = players[index];
                      final playerUid = player['uid'] as String?;

                      if (playerUid == null) {
                        return const Card(
                          color: Colors.grey,
                          child: ListTile(title: Text('Jugador con datos corruptos')),
                        );
                      }

                      final color = hexToColor(player['color'] ?? '#FFFFFF');
                      final isHost = roomData['hostId'] == playerUid;
                      final isCurrentUser = playerUid == currentUserId;

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          onTap: isCurrentUser && currentUserId != null
                              ? () => _showColorPicker(context, players, currentUserId)
                              : null,
                          tileColor: color,
                          title: Text(
                            player['alias'] ?? 'Jugador Desconocido',
                            style: TextStyle(fontWeight: FontWeight.bold, color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white),
                          ),
                          trailing: isHost ? const Icon(Icons.star, color: Colors.amber) : null,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                if (roomData['hostId'] == currentUserId)
                  ElevatedButton(
                    onPressed: () { /* TODO: Implement start game logic */ },
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                    child: const Text('¡Empezar Partida!'),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
