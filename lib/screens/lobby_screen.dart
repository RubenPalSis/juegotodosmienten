import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';

import '../services/firestore_service.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';

class LobbyScreen extends StatefulWidget {
  static const routeName = '/lobby';

  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  String? _roomCode;
  final _chatController = TextEditingController();
  late final UserService _userService;
  late final FirestoreService _firestoreService;

  @override
  void initState() {
    super.initState();
    _userService = Provider.of<UserService>(context, listen: false);
    _firestoreService = Provider.of<FirestoreService>(context, listen: false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_roomCode == null) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      _roomCode = args?['roomCode'];
    }
  }

  Future<void> _leaveRoom() async {
    final user = _userService.currentUser;
    if (_roomCode != null && user != null) {
      await _firestoreService.leaveGameRoom(roomCode: _roomCode!, userId: user.uid);
    }
  }

  void _shareInvitation() {
    if (_roomCode == null) return;
    final invitationLink = "https://todosmienten.app/join?room=$_roomCode";
    final message = "¡Únete a mi partida en Todos Mienten!\n\nCódigo: $_roomCode\nO usa este enlace para unirte directamente: $invitationLink";
    Share.share(message);
  }

  Future<void> _sendMessage() async {
    if (_chatController.text.trim().isEmpty) return;

    final user = _userService.currentUser;
    final roomSnapshot = await _firestoreService.getGameRoomStream(_roomCode!).first;
    final roomData = roomSnapshot.data() as Map<String, dynamic>?;
    final players = roomData?['players'] as List<dynamic>? ?? [];
    final currentPlayer = players.firstWhere((p) => p['uid'] == user?.uid, orElse: () => null);

    if (user != null && currentPlayer != null) {
      await _firestoreService.sendMessage(
        roomCode: _roomCode!,
        text: _chatController.text.trim(),
        alias: user.alias,
        uid: user.uid,
        color: currentPlayer['color'],
      );
      _chatController.clear();
    }
  }

  void _showInfoDialog(String title, String content) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: const Text('Aceptar'),
              onPressed: () {
                if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _leaveRoom();
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _userService.currentUser;

    if (_roomCode == null) {
      return const Scaffold(body: Center(child: Text('Error: Código de sala no encontrado.')));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: _firestoreService.getGameRoomStream(_roomCode!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active && (!snapshot.hasData || snapshot.data?.data() == null)) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _showInfoDialog('Sala Cerrada', 'La sala ha sido cerrada por el anfitrión o por inactividad.'));
          return const Scaffold(body: Center(child: Text('La sala ha sido cerrada.')));
        }

        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final roomData = snapshot.data!.data() as Map<String, dynamic>;
        final players = List<Map<String, dynamic>>.from(roomData['players'] ?? []);
        final bannedUIDs = List<String>.from(roomData['bannedUIDs'] ?? []);

        if (bannedUIDs.contains(currentUser?.uid)) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _showInfoDialog('Has sido baneado', 'No puedes volver a entrar a esta sala.'));
          return const Scaffold(body: Center(child: Text('Has sido baneado.')));
        }
        
        if (players.every((p) => p['uid'] != currentUser?.uid)) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _showInfoDialog('Has sido expulsado', 'El anfitrión te ha expulsado de la sala.'));
            return const Scaffold(body: Center(child: Text('Has sido expulsado.')));
        }

        final isHost = roomData['hostId'] == currentUser?.uid;
        final allReady = players.isNotEmpty && players.length > 1 && players.every((p) => p['isReady'] == true);
        final me = players.firstWhere((p) => p['uid'] == currentUser?.uid, orElse: () => {});

        return DefaultTabController(
          length: isHost ? 3 : 2,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Sala de Espera'),
              bottom: TabBar(
                tabs: [
                  const Tab(icon: Icon(Icons.people), text: 'Jugadores'),
                  const Tab(icon: Icon(Icons.chat), text: 'Chat'),
                  if (isHost) const Tab(icon: Icon(Icons.settings), text: 'Ajustes'),
                ],
              ),
            ),
            body: Column(
              children: [
                _buildHeader(roomData),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildPlayersTab(roomData, currentUser?.uid ?? ''),
                      _buildChatTab(currentUser?.uid ?? ''),
                      if (isHost) _buildSettingsTab(roomData),
                    ],
                  ),
                ),
                _buildBottomButton(isHost, allReady, me, currentUser),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(Map<String, dynamic> roomData) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text('Jugadores: ${roomData['players'].length}/${roomData['maxPlayers']}', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          SelectableText(_roomCode!, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _shareInvitation,
            icon: const Icon(Icons.share),
            label: const Text('Invitar a Amigos'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayersTab(Map<String, dynamic> roomData, String currentUserId) {
    final players = List<Map<String, dynamic>>.from(roomData['players'] ?? []);
    return ListView.builder(
      itemCount: players.length,
      itemBuilder: (context, index) {
        final player = players[index];
        final isCurrentUser = player['uid'] == currentUserId;
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            onTap: isCurrentUser ? () => _showColorPicker(context, players, currentUserId) : () => _showPlayerProfile(context, player['uid']),
            leading: CircleAvatar(backgroundColor: Color(int.parse(player['color'].substring(1, 7), radix: 16) + 0xFF000000)),
            title: Text(player['alias'] ?? 'Jugador Desconocido'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (player['isReady'] == true) const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                if (roomData['hostId'] == player['uid']) const Icon(Icons.star, color: Colors.amber),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildChatTab(String currentUserId) {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestoreService.getChatStream(_roomCode!),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final messages = snapshot.data!.docs;
              return ListView.builder(
                reverse: true,
                itemCount: messages.length,
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                itemBuilder: (context, index) {
                  final message = messages[index].data() as Map<String, dynamic>;
                  if (message['isEvent'] == true) {
                    return _buildEventMessage(message);
                  }
                  final bool isMe = message['uid'] == currentUserId;
                  return _buildChatMessage(message, isMe);
                },
              );
            },
          ),
        ),
        _buildChatInput(),
      ],
    );
  }

  Widget _buildEventMessage(Map<String, dynamic> message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          '${message['alias']} ${message['text']}',
          style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildChatMessage(Map<String, dynamic> message, bool isMe) {
    final color = Color(int.parse(message['color'].substring(1, 7), radix: 16) + 0xFF000000);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
            decoration: BoxDecoration(
              color: isMe ? Theme.of(context).colorScheme.primary.withOpacity(0.2) : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyMedium,
                children: [
                  TextSpan(
                    text: '${message['alias']}: ', 
                    style: TextStyle(fontWeight: FontWeight.bold, color: color),
                  ),
                  TextSpan(text: message['text']),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _chatController,
              decoration: const InputDecoration(hintText: 'Escribe un mensaje...', border: OutlineInputBorder()),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send), 
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab(Map<String, dynamic> roomData) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        SwitchListTile.adaptive(
          title: const Text('Sala Pública'),
          value: roomData['isPublic'] ?? true,
          onChanged: (value) => _firestoreService.updateRoomSettings(_roomCode!, isPublic: value),
        ),
        DropdownButtonFormField<int>(
          value: roomData['maxPlayers'],
          decoration: const InputDecoration(labelText: 'Jugadores Máximos'),
          items: [6, 8, 10, 12].map((value) => DropdownMenuItem(value: value, child: Text('$value jugadores'))).toList(),
          onChanged: (value) {
            if (value != null) {
              _firestoreService.updateRoomSettings(_roomCode!, maxPlayers: value);
            }
          },
        ),
      ],
    );
  }

  Widget _buildBottomButton(bool isHost, bool allReady, Map<String, dynamic> me, User? currentUser) {
    if (isHost) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: allReady ? () => _firestoreService.startGame(_roomCode!) : null,
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: allReady ? Colors.green : Colors.grey),
          child: const Text('¡Empezar Partida!'),
        ),
      );
    }

    bool isReady = me['isReady'] ?? false;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: (currentUser == null) ? null : () => _firestoreService.togglePlayerReadyState(_roomCode!, currentUser.uid),
        style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: isReady ? Colors.grey : null),
        child: Text(isReady ? 'Esperando...' : '¿Preparado?'),
      ),
    );
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
              final color = Color(int.parse(colorHex.substring(1, 7), radix: 16) + 0xFF000000);
              final isUsed = usedColors.contains(colorHex);
              return GestureDetector(
                onTap: () async {
                  if (isUsed) return;
                  try {
                    await _firestoreService.changePlayerColor(_roomCode!, currentUserId, colorHex);
                    Navigator.of(context).pop();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                },
                child: CircleAvatar(
                  backgroundColor: color,
                  child: isUsed ? const Icon(Icons.close, color: Colors.red) : null,
                ),
              );
            }).toList(),
          ),
          actions: [TextButton(child: const Text('Cerrar'), onPressed: () => Navigator.of(context).pop())],
        );
      },
    );
  }

  void _showPlayerProfile(BuildContext context, String playerUid) async {
    final profile = await _firestoreService.getUserProfile(playerUid);
    if (profile == null || !mounted) return;

    final profileData = profile.data() as Map<String, dynamic>;
    final currentUser = _userService.currentUser;
    final roomData = (await _firestoreService.getGameRoomStream(_roomCode!).first).data() as Map<String, dynamic>?;
    final isHost = roomData?['hostId'] == currentUser?.uid;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Perfil de ${profileData['alias']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nivel: ${((profileData['totalExp'] ?? 0) / 150).floor() + 1}'),
              Text('Experiencia: ${profileData['totalExp'] ?? 0}'),
            ],
          ),
          actions: [
            if (isHost && currentUser?.uid != playerUid)
              TextButton(
                onPressed: () {
                  _firestoreService.kickPlayer(_roomCode!, playerUid, currentUser!.alias, profileData['alias']);
                  Navigator.of(context).pop();
                },
                child: const Text('Expulsar', style: TextStyle(color: Colors.orange)),
              ),
            if (isHost && currentUser?.uid != playerUid)
              TextButton(
                onPressed: () {
                  _firestoreService.banPlayer(_roomCode!, playerUid, currentUser!.alias, profileData['alias']);
                  Navigator.of(context).pop();
                },
                child: const Text('Banear', style: TextStyle(color: Colors.red)),
              ),
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar')),
          ],
        );
      },
    );
  }
}
