import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';

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

  void _showRoomClosedDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sala Cerrada'),
          content: const Text('La sala ha sido cerrada por el anfitrión o por inactividad.'),
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
        if (snapshot.connectionState == ConnectionState.active && !snapshot.hasData) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _showRoomClosedDialog());
          return const Scaffold(body: Center(child: Text('La sala ha sido cerrada.')));
        }

        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final roomData = snapshot.data!.data() as Map<String, dynamic>?;
        if (roomData == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _showRoomClosedDialog());
          return const Scaffold(body: Center(child: Text('La sala ha sido cerrada.')));
        }

        final isHost = roomData['hostId'] == currentUser?.uid;
        final players = List<Map<String, dynamic>>.from(roomData['players'] ?? []);
        final allReady = players.isNotEmpty && players.every((p) => p['isReady'] == true);
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
                _buildHeader(),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildPlayersTab(roomData, currentUser?.uid ?? ''),
                      _buildChatTab(currentUser?.uid ?? ''),
                      if (isHost) _buildSettingsTab(roomData),
                    ],
                  ),
                ),
                if (isHost) 
                  _buildStartGameButton(allReady)
                else if (me.isNotEmpty) 
                  _buildReadyButton(me['isReady'] ?? false, currentUser),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text('Código de la Sala:', style: TextStyle(fontSize: 18)),
          SelectableText(_roomCode!, style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
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
            onTap: isCurrentUser ? () => _showColorPicker(context, players, currentUserId) : null,
            leading: CircleAvatar(backgroundColor: Color(int.parse(player['color'].substring(1, 7), radix: 16) + 0xFF000000)),
            title: Text(player['alias'] ?? 'Jugador Desconocido'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (player['isReady'] == true) const Icon(Icons.check_circle, color: Colors.green),
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
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start, // Corrected alignment
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

  Widget _buildReadyButton(bool isReady, dynamic currentUser) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: (isReady || currentUser == null) ? null : () => _firestoreService.togglePlayerReadyState(_roomCode!, currentUser.uid),
        style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: isReady ? Colors.grey : null),
        child: Text(isReady ? 'Esperando...' : '¿Preparado?'),
      ),
    );
  }

  Widget _buildStartGameButton(bool allReady) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: allReady ? () => _firestoreService.startGame(_roomCode!) : null,
        style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: allReady ? Colors.green : Colors.grey),
        child: const Text('¡Empezar Partida!'),
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
}
