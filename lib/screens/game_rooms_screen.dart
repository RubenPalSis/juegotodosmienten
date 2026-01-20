import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/firestore_service.dart';
import '../services/user_service.dart';
import '../services/theme_service.dart';
import '../services/navigation_service.dart';
import '../utils/ui_helpers.dart';
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
    // Limpia salas inactivas al entrar en la pantalla
    Provider.of<FirestoreService>(context, listen: false).cleanupInactiveRooms();
  }

  // Corregido para ser más robusto y evitar errores.
  Future<void> _joinRoom(String roomCode) async {
    if (roomCode.isEmpty) {
      if (mounted) showCustomSnackBar(context, 'Por favor, introduce un código de sala.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final user = Provider.of<UserService>(context, listen: false).currentUser;

    if (user == null) {
      if (mounted) {
        showCustomSnackBar(context, 'Error: Usuario no encontrado.', isError: true);
        setState(() => _isLoading = false);
      }
      return;
    }

    try {
      await firestoreService.joinGameRoom(
        roomCode: roomCode,
        playerAlias: user.alias,
        playerData: {
          'alias': user.alias,
          'isReady': false,
          'selectedCharacter': user.selectedCharacter,
        },
      );

      if (mounted) {
        NavigationService.pushReplacementNamed(
          LobbyScreen.routeName,
          arguments: {'roomCode': roomCode},
        );
      }
    } catch (e) {
      if (mounted) {
        showCustomSnackBar(context, e.toString().replaceFirst('Exception: ', ''), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final backgroundImage = isDarkMode
        ? 'assets/img/Backgound_darkMode.png'
        : 'assets/img/Background_lightMode.png';

    return Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        body: Stack(children: [
          Image.asset(
            backgroundImage,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          SafeArea(
            child: Row(
              children: [
                // Game Rooms Grid
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildRoomsGrid(),
                  ),
                ),
                const VerticalDivider(thickness: 1, width: 1, color: Colors.white24),
                // Actions Sidebar
                Expanded(
                  flex: 2,
                  child: _buildSidebar(theme),
                ),
              ],
            ),
          ),
          Positioned(
            top: 20,
            left: 20,
            child: FloatingActionButton(
                onPressed: () => Navigator.of(context).pop(),
                backgroundColor: isDarkMode ? Colors.black : Colors.white,
                child: Icon(Icons.arrow_back, color: isDarkMode ? Colors.red : Colors.lightBlue)),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ]));
  }

  Widget _buildRoomsGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: Provider.of<FirestoreService>(context).getAllRooms(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final rooms = snapshot.data?.docs ?? [];

        if (rooms.isEmpty) {
          return const Center(
              child: Text('No hay salas públicas disponibles.\n¡Crea una para empezar!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.white)));
        }

        return GridView.builder(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 300,
              childAspectRatio: 1.5,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index].data() as Map<String, dynamic>?;
              final roomCode = rooms[index].id;
              return _buildRoomCard(room, roomCode);
            });
      },
    );
  }

  Widget _buildSidebar(ThemeData theme) {
    final isDarkMode = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Unirse por Código', style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _roomCodeController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Código de la Sala',
              labelStyle: const TextStyle(color: Colors.white70),
              enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white54), borderRadius: BorderRadius.circular(8)),
              focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.lightBlueAccent), borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.login),
            style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: isDarkMode ? Colors.blue.shade800 : Colors.lightBlueAccent),
            onPressed: () => _joinRoom(_roomCodeController.text.trim()),
            label: const Text('Unirse a Sala Privada'),
          ),
          const Divider(height: 48, color: Colors.white24),
          Text('¿No encuentras sala?', style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.add_home_work_outlined),
            label: const Text('Crear Sala Pública'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 20),
              backgroundColor: isDarkMode ? Colors.teal.shade800 : Colors.teal,
              textStyle: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            onPressed: () => NavigationService.pushReplacementNamed(CreateRoomScreen.routeName),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomCard(Map<String, dynamic>? room, String roomCode) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? Colors.black.withOpacity(0.4) : Colors.white.withOpacity(0.3);

    if (room == null) return const SizedBox.shrink();

    final playerCount = room['playerCount'] ?? 0;
    final maxPlayers = room['maxPlayers'] ?? 0;
    final isFull = playerCount >= maxPlayers;
    final hostAlias = room['hostAlias'] ?? 'Anfitrión Desconocido';

    return Card(
      color: cardColor,
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.white.withOpacity(0.2))),
      child: InkWell(
        onTap: isFull ? null : () => _joinRoom(roomCode),
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
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Text(
                    '$playerCount/$maxPlayers Jugadores',
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: isFull ? null : () => _joinRoom(roomCode),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkMode ? Colors.blue.shade700 : Colors.blue.shade400,
                    ),
                    child: const Text('Unirse'),
                  ),
                ],
              ),
            ),
            if (isFull)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
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
