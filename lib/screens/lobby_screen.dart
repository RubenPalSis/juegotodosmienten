import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';

import '../services/firestore_service.dart';
import '../services/user_service.dart';
import '../services/theme_service.dart';
import '../utils/ui_helpers.dart';
import '../widgets/player_avatar.dart';
import 'home_screen.dart';

class LobbyScreen extends StatefulWidget {
  static const routeName = '/lobby';

  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  String? _roomCode;
  final _chatController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_roomCode == null) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      _roomCode = args?['roomCode'];
    }
  }

  Future<void> _leaveRoomAndGoHome() async {
    final user = Provider.of<UserService>(context, listen: false).currentUser;
    if (_roomCode != null && user != null) {
      await Provider.of<FirestoreService>(context, listen: false).leaveGameRoom(roomCode: _roomCode!, playerAlias: user.alias);
    }
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(HomeScreen.routeName, (route) => false);
    }
  }

  Future<bool> _onWillPop() async {
    final wannaLeave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Salir de la sala?'),
        content: const Text('¿Estás seguro de que quieres abandonar la sala?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Quedarse')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Salir', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
    if (wannaLeave ?? false) {
      await _leaveRoomAndGoHome();
      return false; // Evita que el `WillPopScope` haga un pop automático
    }
    return false;
  }

  void _shareInvitation() {
    if (_roomCode == null) return;
    final invitationLink = "https://todosmienten.app/join?room=$_roomCode";
    Share.share("¡Únete a mi partida en Todos Mienten!\n\nCódigo: $_roomCode\nO usa este enlace para unirte directamente: $invitationLink");
  }

  @override
  Widget build(BuildContext context) {
    if (_roomCode == null) {
      return const Scaffold(body: Center(child: Text('Error: Código de sala no encontrado.')));
    }

    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final backgroundImage = isDarkMode ? 'assets/img/Backgound_darkMode.png' : 'assets/img/Background_lightMode.png';

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(children: [
          Image.asset(backgroundImage, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
          SafeArea(
            child: Column(children: [
              _buildHeader(theme),
              Expanded(child: _buildPlayerGrid()),
              _buildFooter(theme),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: const Icon(Icons.exit_to_app, color: Colors.white), onPressed: _onWillPop, tooltip: 'Salir de la sala'),
          Column(children: [
            const Text('Código de la Sala', style: TextStyle(color: Colors.white70, fontSize: 12)),
            SelectableText(_roomCode ?? '', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          ]),
          IconButton(icon: const Icon(Icons.share, color: Colors.white), onPressed: _shareInvitation, tooltip: 'Invitar a amigos'),
        ],
      ),
    );
  }

  Widget _buildPlayerGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: Provider.of<FirestoreService>(context).getPlayersStream(_roomCode!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final players = snapshot.data!.docs;
        return GridView.builder(
          padding: const EdgeInsets.all(16.0),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 200, childAspectRatio: 0.8, crossAxisSpacing: 16, mainAxisSpacing: 16, 
          ),
          itemCount: players.length,
          itemBuilder: (context, index) {
            final player = players[index].data() as Map<String, dynamic>;
            return PlayerAvatar(playerData: player);
          },
        );
      },
    );
  }

  Widget _buildFooter(ThemeData theme) {
    final isDarkMode = theme.brightness == Brightness.dark;
    final userAlias = Provider.of<UserService>(context, listen: false).currentUser?.alias ?? '';
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: isDarkMode ? Colors.black.withOpacity(0.3) : Colors.white.withOpacity(0.2),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _chatController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Escribe un mensaje...',
                hintStyle: const TextStyle(color: Colors.white70),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.black.withOpacity(0.2),
              ),
              onSubmitted: (text) => Provider.of<FirestoreService>(context, listen: false).sendMessage(roomCode: _roomCode!, alias: userAlias, text: text),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () => Provider.of<FirestoreService>(context, listen: false).sendMessage(roomCode: _roomCode!, alias: userAlias, text: _chatController.text),
            style: ElevatedButton.styleFrom(shape: const CircleBorder(), padding: const EdgeInsets.all(16)),
            child: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}
