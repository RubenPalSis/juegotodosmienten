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
  bool _isJoining = false;

  @override
  void initState() {
    super.initState();
    Provider.of<FirestoreService>(context, listen: false).cleanupInactiveRooms();
  }

  Future<void> _joinRoom(String roomCode) async {
    if (roomCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, introduce un código de sala.')),
      );
      return;
    }

    setState(() => _isJoining = true);

    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final user = Provider.of<UserService>(context, listen: false).currentUser;
    final messenger = ScaffoldMessenger.of(context);

    if (user == null) {
      setState(() => _isJoining = false);
      return;
    }

    try {
      await firestoreService.joinGameRoom(
        roomCode: roomCode,
        playerData: {
          'uid': user.uid,
          'alias': user.alias,
          'isReady': false,
        },
      );

      if (!mounted) return;

      NavigationService.pushReplacementNamed(
        LobbyScreen.routeName,
        arguments: {'roomCode': roomCode},
      );

    } on FirebaseException catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(e.message ?? 'Ha ocurrido un error de conexión.')),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isJoining = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);
    final isLoggedIn = Provider.of<UserService>(context, listen: false).currentUser != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Buscar Partida')),
      body: Row(
        children: [
          // Game Rooms Grid
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: StreamBuilder<QuerySnapshot>(
                stream: firestoreService.getAllRooms(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                  final publicRooms = snapshot.data?.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>?;
                    return data?['isPublic'] == true;
                  }).toList() ?? [];

                  if (publicRooms.isEmpty) {
                    return const Center(
                      child: Text('No hay salas públicas disponibles.\n¡Crea una para empezar!', textAlign: TextAlign.center, style: TextStyle(fontSize: 18))
                    );
                  }

                  return GridView.builder(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 300,
                        childAspectRatio: 1.4,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: publicRooms.length,
                      itemBuilder: (context, index) {
                        final doc = publicRooms[index];
                        return _buildRoomCard(doc, isLoggedIn);
                      });
                },
              ),
            ),
          ),

          const VerticalDivider(thickness: 1, width: 1),

          // Actions Sidebar
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Join with code
                  Text('Unirse con Código', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _roomCodeController,
                    decoration: const InputDecoration(labelText: 'Código de la Sala', border: OutlineInputBorder()),
                    enabled: isLoggedIn,
                  ),
                  const SizedBox(height: 16),
                  _isJoining
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton.icon(
                          icon: const Icon(Icons.login),
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                          onPressed: isLoggedIn ? () => _joinRoom(_roomCodeController.text.trim()) : null,
                          label: const Text('Unirse a Sala Privada'),
                        ),

                  const Divider(height: 48),

                  // Create room
                  Text('¿No encuentras sala?', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add_home_work_outlined),
                    label: const Text('Crear Sala Pública'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      textStyle: Theme.of(context).textTheme.titleLarge,
                    ),
                    onPressed: isLoggedIn ? () => NavigationService.pushReplacementNamed(CreateRoomScreen.routeName) : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomCard(DocumentSnapshot roomSnapshot, bool isLoggedIn) {
    final theme = Theme.of(context);
    final room = roomSnapshot.data() as Map<String, dynamic>?;
    if (room == null) return const SizedBox.shrink();

    final players = List<Map<String, dynamic>>.from(room['players'] ?? []);
    final maxPlayers = room['maxPlayers'] ?? 0;
    final isFull = players.length >= maxPlayers;
    final hostAlias = room['hostAlias'] ?? 'Anfitrión Desconocido';

    return Card(
      elevation: 4.0,
      child: InkWell(
        onTap: isLoggedIn && !isFull ? () => _joinRoom(roomSnapshot.id) : null,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Sala de $hostAlias",
                    style: theme.textTheme.titleLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Text(
                    '${players.length}/$maxPlayers Jugadores',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: isLoggedIn && !isFull ? () => _joinRoom(roomSnapshot.id) : null,
                    child: const Text('Unirse'),
                  ),
                ],
              ),
            ),
            if (isFull)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: const Center(child: Text('LLENO', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))),
              ),
          ],
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
