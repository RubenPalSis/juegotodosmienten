import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/user_service.dart';
import '../services/navigation_service.dart';
import '../services/theme_service.dart';
import '../screens/settings_screen.dart';
import '../screens/game_rooms_screen.dart';
import '../screens/customize_avatar_screen.dart';
import '../screens/shop_screen.dart';

class MainLayout extends StatelessWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          final isDarkMode =
              themeService.themeMode == ThemeMode.dark ||
              (themeService.themeMode == ThemeMode.system &&
                  MediaQuery.of(context).platformBrightness == Brightness.dark);

          final backgroundImage = isDarkMode
              ? 'assets/img/Backgound_darkMode.png'
              : 'assets/img/Background_lightMode.png';

          return Stack(
            children: [
              Image.asset(
                backgroundImage,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
              const _MainMenuContent(),
              Positioned(
                right: 20,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _CircularIconButton(
                        icon: Icons.settings,
                        onPressed: () =>
                            NavigationService.push(SettingsScreen.routeName),
                      ),
                      const SizedBox(height: 20),
                      _CircularIconButton(
                        icon: Icons.person,
                        onPressed: () {
                          final userService = Provider.of<UserService>(
                            context,
                            listen: false,
                          );
                          final character =
                              userService.currentUser?.selectedCharacter ??
                                  'robot.glb';
                          NavigationService.push(
                            CustomizeAvatarScreen.routeName,
                            arguments: {'characterFile': character},
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      _CircularIconButton(
                        icon: Icons.store,
                        onPressed: () =>
                            NavigationService.push(ShopScreen.routeName),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MainMenuContent extends StatelessWidget {
  const _MainMenuContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    final titleShadowColor = isDarkMode ? Colors.lightBlueAccent : Colors.blue.shade900;

    final titleStyle = theme.textTheme.displayLarge?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      letterSpacing: 6,
      shadows: [
        Shadow(
          blurRadius: 15.0,
          color: titleShadowColor,
          offset: const Offset(0, 0),
        ),
        Shadow(
          blurRadius: 30.0,
          color: titleShadowColor.withOpacity(0.7),
          offset: const Offset(0, 0),
        ),
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
            const Spacer(flex: 2),
            // Menu Buttons
            _MainMenuButton(
              text: 'EN LÍNEA',
              icon: Icons.wifi_tethering,
              onPressed: () =>
                  NavigationService.push(GameRoomsScreen.routeName),
            ),
            const SizedBox(height: 25),
            _MainMenuButton(
              text: 'JUGAR EN LOCAL',
              icon: Icons.people_alt_outlined,
              onPressed: () {
                // TODO: Implement local play
              },
            ),
            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }
}

class _MainMenuButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onPressed;

  const _MainMenuButton({required this.text, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDarkMode
        ? Colors.black.withOpacity(0.3)
        : Colors.white.withOpacity(0.2);
    final borderColor = isDarkMode ? Colors.white60 : Colors.white;

    final buttonTextStyle = theme.textTheme.headlineSmall?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      letterSpacing: 2,
    );

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white, size: 28),
      label: Text(text, style: buttonTextStyle),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(380, 70),
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderColor, width: 2),
        ),
        shadowColor: Colors.black.withOpacity(0.5),
        elevation: 8,
      ),
    );
  }
}

class _CircularIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _CircularIconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode
        ? Colors.black.withOpacity(0.4)
        : Colors.white.withOpacity(0.25);

    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white, size: 34),
      style: IconButton.styleFrom(
        padding: const EdgeInsets.all(16),
        shape: const CircleBorder(),
        backgroundColor: backgroundColor,
        side: BorderSide(color: Colors.white.withOpacity(0.7), width: 1),
      ),
    );
  }
}
