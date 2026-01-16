import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/user_service.dart';
import '../services/navigation_service.dart';
import '../screens/settings_screen.dart';
import '../screens/game_rooms_screen.dart';
import '../screens/customize_avatar_screen.dart';

class MainLayout extends StatelessWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // TODO: Podrías añadir un fondo de estrellas aquí
          // Image.asset('assets/images/background_stars.png', fit: BoxFit.cover, width: double.infinity, height: double.infinity,),
          _MainMenuContent(),
          _BottomActionBar(),
        ],
      ),
    );
  }
}

class _MainMenuContent extends StatelessWidget {
  const _MainMenuContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.displayLarge?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      letterSpacing: 4,
      shadows: [
        const Shadow(blurRadius: 10.0, color: Colors.white, offset: Offset(0, 0)),
      ],
    );

    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),
            // Game Title
            Text('TODOS MIENTEN', style: titleStyle),
            const Spacer(flex: 1),
            // Menu Buttons
            _MainMenuButton(
              text: 'EN LÍNEA',
              onPressed: () => NavigationService.push(GameRoomsScreen.routeName),
            ),
            const SizedBox(height: 20),
            _MainMenuButton(
              text: 'PERSONALIZAR',
              onPressed: () {
                final userService = Provider.of<UserService>(context, listen: false);
                final character = userService.currentUser?.selectedCharacter ?? 'robot.glb';
                NavigationService.push(CustomizeAvatarScreen.routeName, arguments: {'characterFile': character});
              },
            ),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}

class _MainMenuButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const _MainMenuButton({required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonTextStyle = theme.textTheme.headlineMedium?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      letterSpacing: 2,
    );

    return InkWell(
      onTap: onPressed,
      child: Container(
        width: 350, // Ancho fijo para los botones
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 3),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(text, style: buttonTextStyle),
        ),
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _RoundIconButton(icon: Icons.settings, onPressed: () => NavigationService.push(SettingsScreen.routeName)),
            const SizedBox(width: 20),
            _RoundIconButton(icon: Icons.person, onPressed: () { /* TODO: Perfil de usuario */ }),
            const SizedBox(width: 20),
            _RoundIconButton(icon: Icons.store, onPressed: () { /* TODO: Tienda */ }),
          ],
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _RoundIconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      customBorder: const CircleBorder(),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Icon(icon, color: Colors.white, size: 30),
      ),
    );
  }
}
