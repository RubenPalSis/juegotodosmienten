import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';

import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/user_service.dart';
import '../widgets/player_avatar.dart';
import 'home_screen.dart';

enum _LobbyView { players, chat, settings }

class LobbyScreen extends StatefulWidget {
  static const routeName = '/lobby';
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  String? _roomCode;
  _LobbyView _currentView = _LobbyView.players;

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
      return false;
    }
    return false;
  }

  void _shareInvitation() {
    if (_roomCode == null) return;
    final invitationLink = "https://todosmienten.app/join?room=$_roomCode";
    Share.share("¡Únete a mi partida en Todos Mienten!\n\nCódigo: $_roomCode\nO usa este enlace para unirte directamente: $invitationLink");
  }

  void _setReadyStatus(bool isReady) {
    final currentUser = Provider.of<UserService>(context, listen: false).currentUser;
    if (currentUser != null) {
      Provider.of<FirestoreService>(context, listen: false).setPlayerReadyStatus(
        roomCode: _roomCode!,
        playerAlias: currentUser.alias,
        isReady: isReady,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_roomCode == null) {
      return const Scaffold(body: Center(child: Text('Error: Código de sala no encontrado.')));
    }
    final theme = Theme.of(context);
    final backgroundImage = theme.brightness == Brightness.dark
        ? 'assets/img/Backgound_darkMode.png'
        : 'assets/img/Background_lightMode.png';
    final user = Provider.of<UserService>(context).currentUser;

    return Container(
      decoration: BoxDecoration(image: DecorationImage(image: AssetImage(backgroundImage), fit: BoxFit.cover)),
      child: WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.black.withOpacity(0.8),
            elevation: 0,
            title: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Código de la Sala', style: TextStyle(color: Colors.white70, fontSize: 12)),
                SelectableText(_roomCode ?? '', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
            centerTitle: true,
            actions: [
              if (user != null)
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Row(
                    children: [
                      Image.asset('assets/img/gold_coin.png', width: 20, height: 20),
                      const SizedBox(width: 4),
                      Text('${user.goldCoins}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 12),
                      Image.asset('assets/img/bronze_coin.png', width: 20, height: 20),
                      const SizedBox(width: 4),
                      Text('${user.bronzeCoins}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
            ],
          ),
          body: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Expanded(child: _buildMainContent()),
                      _buildReadyButton(),
                    ],
                  ),
                ),
                _buildNavigationRail(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    switch (_currentView) {
      case _LobbyView.players:
        return _buildPlayerGrid();
      case _LobbyView.chat:
        return _ChatView(roomCode: _roomCode!);
      case _LobbyView.settings:
        return _buildSettingsView();
    }
  }

  Widget _buildNavigationRail() {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final currentUser = Provider.of<UserService>(context, listen: false).currentUser;
    final theme = Theme.of(context);

    return StreamBuilder<DocumentSnapshot>(
      stream: firestoreService.getGameRoomStream(_roomCode!),
      builder: (context, snapshot) {
        bool isHost = false;
        if (snapshot.hasData && currentUser != null) {
          final roomData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          isHost = roomData['hostId'] == currentUser.uid;
        }

        return SafeArea(
          child: Container(
            color: Colors.black.withOpacity(0.8),
            child: NavigationRail(
              backgroundColor: Colors.transparent,
              selectedIndex: _currentView.index,
              onDestinationSelected: (index) {
                if (index >= _LobbyView.values.length) return;
                final newView = _LobbyView.values[index];
                if (newView == _LobbyView.settings && !isHost) return;
                setState(() => _currentView = newView);
              },
              labelType: NavigationRailLabelType.selected,
              leading: const SizedBox.shrink(), // Placeholder
              trailing: Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(icon: const Icon(Icons.share, color: Colors.white), onPressed: _shareInvitation, tooltip: 'Invitar'),
                    const SizedBox(height: 16),
                    IconButton(icon: Icon(Icons.exit_to_app, color: theme.colorScheme.error), onPressed: _onWillPop, tooltip: 'Salir'),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              destinations: [
                const NavigationRailDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: Text('Jugadores')),
                const NavigationRailDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: Text('Chat')),
                if (isHost) const NavigationRailDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: Text('Ajustes')),
              ],
              selectedIconTheme: const IconThemeData(color: Colors.white, size: 30),
              unselectedIconTheme: IconThemeData(color: Colors.white.withOpacity(0.6), size: 26),
              selectedLabelTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              unselectedLabelTextStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReadyButton() {
    final currentUser = Provider.of<UserService>(context, listen: false).currentUser;

    return StreamBuilder<QuerySnapshot>(
        stream: Provider.of<FirestoreService>(context).getPlayersStream(_roomCode!),
        builder: (context, snapshot) {
          if (!snapshot.hasData || currentUser == null) return const SizedBox.shrink();
          final players = snapshot.data!.docs;

          QueryDocumentSnapshot? me;
          try {
            me = players.firstWhere((p) => p.id == currentUser.alias);
          } catch (e) {
            me = null;
          }

          if (me == null) return const SizedBox.shrink();

          final amIReady = (me.data() as Map<String, dynamic>?)?['isReady'] ?? false;

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: amIReady ? Colors.grey.shade800 : Colors.green,
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              onPressed: amIReady ? null : () => _setReadyStatus(true),
              child: Text(amIReady ? 'Esperando a los demás jugadores...' : '¿Estás listo?'),
            ),
          );
        });
  }

  void _showColorPicker(BuildContext context, List<int> usedColors) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.grey.shade900.withOpacity(0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: _ColorPickerDialog(usedColors: usedColors, roomCode: _roomCode!),
      ),
    );
  }

  Widget _buildPlayerGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: Provider.of<FirestoreService>(context).getPlayersStream(_roomCode!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Esperando jugadores...', style: TextStyle(color: Colors.white, fontSize: 18)));
        }

        final players = snapshot.data!.docs;
        final usedColors = players.map((doc) {
          final data = doc.data() as Map<String, dynamic>?;
          return data?.containsKey('color') == true ? data!['color'] as int : null;
        }).where((v) => v != null).cast<int>().toList();

        return LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = (constraints.maxWidth / 150).floor().clamp(2, 5);
            return GridView.builder(
              padding: const EdgeInsets.all(16.0),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 0.9,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: players.length,
              itemBuilder: (context, index) {
                final player = players[index].data() as Map<String, dynamic>;
                final playerAlias = player['alias'] as String?;
                final currentUser = Provider.of<UserService>(context, listen: false).currentUser;

                return GestureDetector(
                  onTap: () async {
                    if (playerAlias == null) return;
                    if (playerAlias == currentUser?.alias) {
                      _showColorPicker(context, usedColors);
                    } else {
                      final user = await Provider.of<FirestoreService>(context, listen: false).getUserByAlias(playerAlias);
                      if (user != null && context.mounted) {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(user.alias),
                            content: Text('Experiencia Total: ${user.totalExp} XP'),
                            actions: [TextButton(child: const Text('Cerrar'), onPressed: () => Navigator.of(ctx).pop())],
                          ),
                        );
                      }
                    }
                  },
                  child: PlayerAvatar(playerData: player),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSettingsView() {
    return const Center(child: Text('Ajustes de la sala (Solo para el host)', style: TextStyle(color: Colors.white, fontSize: 20)));
  }
}

class _ColorPickerDialog extends StatefulWidget {
  final List<int> usedColors;
  final String roomCode;

  const _ColorPickerDialog({required this.usedColors, required this.roomCode});

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  static const _spainColorValue = -1; // Special value for Spain flag

  static const List<Color> _freePalette = [
    Colors.red, Colors.pink, Colors.purple, Colors.deepPurple,
    Colors.indigo, Colors.blue, Colors.lightBlue, Colors.cyan,
    Colors.teal, Colors.green, Colors.lightGreen, Colors.lime,
    Colors.yellow, Colors.amber,
  ];

  static final List<Color> _premiumColors = List.generate(100, (index) {
    final hue = (index * (360 / 100)) % 360;
    return HSLColor.fromAHSL(1.0, hue, 0.7, 0.6).toColor();
  });

  void _selectColor(int colorValue) {
    final currentUser = Provider.of<UserService>(context, listen: false).currentUser;
    if (currentUser == null) return;
    Provider.of<FirestoreService>(context, listen: false).updatePlayerColor(widget.roomCode, currentUser.alias, colorValue);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 400,
      height: 500,
      child: Column(
        children: [
          const SizedBox(height: 16),
          Text('Elige tu color', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white)),
          const SizedBox(height: 8),
          TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.lightBlueAccent,
            tabs: const [
              Tab(text: 'GRATIS'),
              Tab(text: 'PREMIUM'),
              Tab(text: 'ESPECIALES'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildColorGrid(palette: _freePalette, isPremium: false),
                _buildColorGrid(palette: _premiumColors, isPremium: true),
                _buildSpecialColorGrid(),
              ],
            ),
          ),
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar'))
        ],
      ),
    );
  }

  Widget _buildColorGrid({required List<Color> palette, required bool isPremium}) {
    final user = Provider.of<UserService>(context, listen: false).currentUser;
    final unlockedColors = user?.unlockedColors ?? [];

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.0,
      ),
      itemCount: palette.length,
      itemBuilder: (context, index) {
        final color = palette[index];
        final isUsed = widget.usedColors.contains(color.value);
        final isLocked = isPremium && !unlockedColors.contains(color.value);

        return GestureDetector(
          onTap: () {
            if (isUsed || isLocked) return;
            _selectColor(color.value);
          },
          child: Tooltip(
            message: isLocked ? 'Desbloquea este color en la tienda' : (isUsed ? 'En uso' : ''),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isLocked ? Colors.grey.shade800 : color,
                border: Border.all(color: Colors.white.withOpacity(0.7), width: 2),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (isUsed) const Icon(Icons.close, color: Colors.black54, size: 30),
                  if (isLocked) const Icon(Icons.lock, color: Colors.white70, size: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSpecialColorGrid() {
    final user = Provider.of<UserService>(context, listen: false).currentUser;
    final unlockedColors = user?.unlockedColors ?? [];
    final isLocked = !unlockedColors.contains(_spainColorValue);
    final isUsed = widget.usedColors.contains(_spainColorValue);

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Center(
        child: GestureDetector(
          onTap: () {
            if (isLocked || isUsed) return;
            _selectColor(_spainColorValue);
          },
          child: Tooltip(
            message: isLocked ? 'Desbloquea este color especial' : (isUsed ? 'En uso' : 'Bandera de España'),
            child: SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.7), width: 2),
                      gradient: isLocked
                          ? null
                          : const LinearGradient(
                        colors: [Color(0xFFc60b1e), Color(0xFFffc400), Color(0xFFc60b1e)],
                        stops: [0.0, 0.5, 1.0],
                      ),
                      color: isLocked ? Colors.grey.shade800 : null,
                    ),
                  ),
                  if (isUsed) const Icon(Icons.close, color: Colors.black54, size: 30),
                  if (isLocked) const Icon(Icons.lock, color: Colors.white70, size: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatView extends StatefulWidget {
  final String roomCode;
  const _ChatView({required this.roomCode});

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  final _chatController = TextEditingController();
  final _scrollController = ScrollController();

  void _sendMessage() {
    final text = _chatController.text.trim();
    final user = Provider.of<UserService>(context, listen: false).currentUser;
    if (text.isNotEmpty && user != null) {
      Provider.of<FirestoreService>(context, listen: false).sendMessage(roomCode: widget.roomCode, alias: user.alias, text: text);
      _chatController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: Provider.of<FirestoreService>(context).getChatStream(widget.roomCode),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('Aún no hay mensajes.', style: TextStyle(color: Colors.white.withOpacity(0.7))));
                }

                final messages = snapshot.data!.docs;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index].data() as Map<String, dynamic>;
                    final userAlias = Provider.of<UserService>(context, listen: false).currentUser?.alias ?? '';
                    final isMe = message['alias'] == userAlias;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: isMe ? theme.colorScheme.primary.withOpacity(0.8) : (isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300).withOpacity(0.8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(message['alias'] ?? 'Anónimo', style: TextStyle(fontWeight: FontWeight.bold, color: isMe ? Colors.white : (isDarkMode ? Colors.white70 : Colors.black87))),
                            const SizedBox(height: 4),
                            Text(message['text'] ?? '', style: TextStyle(color: isMe ? Colors.white : (isDarkMode ? Colors.white : Colors.black))),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Escribe un mensaje...',
                      hintStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.black.withOpacity(0.3),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: _sendMessage,
                  style: IconButton.styleFrom(backgroundColor: theme.colorScheme.primary, padding: const EdgeInsets.all(12)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}