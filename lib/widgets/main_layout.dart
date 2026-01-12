import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:provider/provider.dart';

import '../services/user_service.dart';
import '../services/character_service.dart';
import '../services/navigation_service.dart';
import '../screens/settings_screen.dart';
import '../screens/customize_avatar_screen.dart';
import '../screens/game_rooms_screen.dart'; // Correct import

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    PlayScreen(),
    AvatarShowcaseScreen(),
    StoreScreen(), // Placeholder
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserService>(
      builder: (context, userService, child) {
        final user = userService.currentUser;
        if (user == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('Alias: ${user.alias}'),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => NavigationService.push(SettingsScreen.routeName),
                tooltip: 'Ajustes',
              ),
            ],
          ),
          body: IndexedStack(
            index: _selectedIndex,
            children: _widgetOptions,
          ),
          bottomNavigationBar: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(icon: Icon(Icons.gamepad_outlined), label: 'Jugar'),
              BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Personaje'),
              BottomNavigationBarItem(icon: Icon(Icons.store_outlined), label: 'Tienda'),
            ],
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
          ),
        );
      },
    );
  }
}

// --- Play Screen --- //
class PlayScreen extends StatelessWidget {
  const PlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserService>(
      builder: (context, userService, child) {
        if (userService.currentUser == null) return const SizedBox.shrink();

        final level = userService.level;
        final expInCurrentLevel = userService.expInCurrentLevel;
        final expForNextLevel = userService.expForNextLevel;
        final progress = expInCurrentLevel / expForNextLevel;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Nivel $level', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                borderRadius: BorderRadius.circular(5),
              ),
              const SizedBox(height: 8),
              Text('${expInCurrentLevel.toInt()} / ${expForNextLevel.toInt()} EXP'),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () => NavigationService.push(GameRoomsScreen.routeName), // Correct navigation
                child: const Text('Buscar Partida'),
              )
            ],
          ),
        );
      },
    );
  }
}

// --- Character Tab ---
class AvatarShowcaseScreen extends StatefulWidget {
  const AvatarShowcaseScreen({super.key});

  @override
  State<AvatarShowcaseScreen> createState() => _AvatarShowcaseScreenState();
}

class _AvatarShowcaseScreenState extends State<AvatarShowcaseScreen> {
  int _browsingIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final characterService = Provider.of<CharacterService>(context, listen: false);
    final characters = characterService.characters;
    final browsingCharacter = characters[_browsingIndex];
    
    void nextCharacter() => setState(() => _browsingIndex = (_browsingIndex + 1) % characters.length);
    void previousCharacter() => setState(() => _browsingIndex = (_browsingIndex - 1 + characters.length) % characters.length);

    return Consumer<UserService>(
      builder: (context, userService, child) {
        final user = userService.currentUser;
        if (user == null) return const SizedBox.shrink();

        final selectedCharacterFile = user.selectedCharacter ?? 'robot.glb';
        final isCharacterSelected = browsingCharacter.assetFile == selectedCharacterFile;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ModelViewer(
                    key: ValueKey(browsingCharacter.assetFile),
                    src: 'assets/models/${browsingCharacter.assetFile}',
                    alt: browsingCharacter.name,
                    autoRotate: true,
                    cameraControls: true,
                    backgroundColor: theme.scaffoldBackgroundColor,
                    environmentImage: 'neutral',
                  ),
                  Positioned(left: 0, child: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 30), onPressed: previousCharacter)),
                  Positioned(right: 0, child: IconButton(icon: const Icon(Icons.arrow_forward_ios, size: 30), onPressed: nextCharacter)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(browsingCharacter.name, style: theme.textTheme.displaySmall, textAlign: TextAlign.center),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  if (!isCharacterSelected)
                    ElevatedButton(
                      onPressed: () => userService.updateCharacter(browsingCharacter.assetFile),
                      child: const Text('Seleccionar'),
                    ),
                  if (isCharacterSelected)
                    ElevatedButton(
                      onPressed: () => NavigationService.push(
                        CustomizeAvatarScreen.routeName,
                        arguments: {'characterFile': selectedCharacterFile},
                      ),
                      child: const Text('Personalizar'),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// --- Store Tab (Placeholder) ---
class StoreScreen extends StatelessWidget {
  const StoreScreen({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('Pantalla de Tienda'));
}
