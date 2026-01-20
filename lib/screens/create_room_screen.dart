import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/firestore_service.dart';
import '../services/user_service.dart';
import '../services/navigation_service.dart';
import '../services/theme_service.dart';
import '../utils/ui_helpers.dart';
import 'lobby_screen.dart';

class CreateRoomScreen extends StatefulWidget {
  static const routeName = '/create-room';

  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  bool _isLoading = false;
  int _maxPlayers = 8;
  bool _isPublic = true;

  Future<void> _createAndJoinRoom() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final user = Provider.of<UserService>(context, listen: false).currentUser;

    if (user == null) {
      if (mounted) {
        showCustomSnackBar(context, 'Error: Usuario no encontrado para crear la sala.', isError: true);
      }
      setState(() => _isLoading = false);
      return;
    }

    try {
      final roomCode = await firestoreService.createRoom(
        hostAlias: user.alias,
        hostData: {
          'alias': user.alias,
          'isReady': true, // El host siempre está listo
          'selectedCharacter': user.selectedCharacter, 
        },
        maxPlayers: _maxPlayers,
        isPublic: _isPublic,
      );
      
      if (mounted) {
        NavigationService.pushReplacementNamed(LobbyScreen.routeName, arguments: {'roomCode': roomCode});
      }
    } catch (e) {
      if (mounted) {
        showCustomSnackBar(context, 'Error al crear la sala: $e', isError: true);
        setState(() => _isLoading = false);
      }
    }
  }

 @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final fabBackgroundColor = isDarkMode ? Colors.black : Colors.white;
    final fabIconColor = isDarkMode ? Colors.red : Colors.lightBlue;

    final backgroundImage = isDarkMode
        ? 'assets/img/Backgound_darkMode.png'
        : 'assets/img/Background_lightMode.png';

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).pop(),
        backgroundColor: fabBackgroundColor,
        child: Icon(Icons.arrow_back, color: fabIconColor),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      body: Stack(
        children: [
          Image.asset(
            backgroundImage,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: _buildForm(theme),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildForm(ThemeData theme) {
    final isDarkMode = theme.brightness == Brightness.dark;
    final cardColor = isDarkMode ? Colors.black.withOpacity(0.4) : Colors.white.withOpacity(0.3);

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Configura tu partida',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white, 
              fontWeight: FontWeight.bold
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildDropdown(theme),
          const SizedBox(height: 24),
          _buildSwitch(theme),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _isLoading ? null : _createAndJoinRoom,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 20),
              backgroundColor: isDarkMode ? Colors.blue.shade800 : Colors.lightBlueAccent,
              textStyle: theme.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            child: const Text('Crear y Entrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(ThemeData theme) {
    final isDarkMode = theme.brightness == Brightness.dark;
    return DropdownButtonFormField<int>(
      value: _maxPlayers,
      dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
      style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
      decoration: InputDecoration(
        labelText: 'Número Máximo de Jugadores',
        labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54),
        prefixIcon: Icon(Icons.group, color: isDarkMode ? Colors.white70 : Colors.black54),
        enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: isDarkMode ? Colors.white54 : Colors.black54)),
        focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: isDarkMode ? Colors.lightBlueAccent : Colors.blue.shade700)),
      ),
      items: [6, 8, 10, 12].map((int value) {
        return DropdownMenuItem<int>(
          value: value,
          child: Text('$value jugadores'),
        );
      }).toList(),
      onChanged: (newValue) {
        if (newValue != null) {
          setState(() => _maxPlayers = newValue);
        }
      },
    );
  }

  Widget _buildSwitch(ThemeData theme) {
     final isDarkMode = theme.brightness == Brightness.dark;
     return SwitchListTile(
        title: const Text('Sala Pública', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: const Text('Si está activado, tu sala será visible para todos.', style: TextStyle(color: Colors.white70)),
        value: _isPublic,
        onChanged: (newValue) {
          setState(() => _isPublic = newValue);
        },
        activeColor: Colors.lightBlueAccent,
      );
  }
}
