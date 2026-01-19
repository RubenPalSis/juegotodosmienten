import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/theme_service.dart';

class ShopScreen extends StatelessWidget {
  static const routeName = '/shop';

  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        final isDarkMode =
            themeService.themeMode == ThemeMode.dark ||
            (themeService.themeMode == ThemeMode.system &&
                MediaQuery.of(context).platformBrightness == Brightness.dark);

        final fabBackgroundColor = isDarkMode ? Colors.black : Colors.white;
        final fabIconColor = isDarkMode ? Colors.red : Colors.lightBlue;

        final backgroundImage = isDarkMode
            ? 'assets/img/Backgound_darkMode.png'
            : 'assets/img/Background_lightMode.png';

        return Scaffold(
          backgroundColor: Colors.transparent,
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
              const Center(
                child: Text('Próximamente: ¡Tienda de personajes y objetos!'),
              ),
            ],
          ),
        );
      },
    );
  }
}
