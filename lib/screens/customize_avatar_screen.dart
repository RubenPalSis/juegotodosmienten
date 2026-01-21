import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:provider/provider.dart';

import '../services/theme_service.dart';

class CustomizeAvatarScreen extends StatelessWidget {
  static const routeName = '/customize-avatar';
  final String characterFile;

  const CustomizeAvatarScreen({super.key, required this.characterFile});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        final isDarkMode =
            themeService.themeMode == ThemeMode.dark ||
                (themeService.themeMode == ThemeMode.system &&
                    MediaQuery.of(context).platformBrightness ==
                        Brightness.dark);

        final fabBackgroundColor =
            isDarkMode ? Colors.grey[800] : Colors.white;
        final fabIconColor = isDarkMode ? Colors.white : Colors.lightBlue;

        final backgroundImage = isDarkMode
            ? 'assets/img/Backgound_darkMode.png'
            : 'assets/img/Background_lightMode.png';

        return Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true,
          body: Stack(
            children: [
              Image.asset(
                backgroundImage,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
              Column(
                children: [
                  Expanded(
                    flex: 3,
                    child: ModelViewer(
                      src: 'assets/models/$characterFile',
                      alt: "Avatar Preview",
                      autoRotate: true,
                      cameraControls: true,
                      environmentImage: 'neutral',
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                  const Expanded(
                    flex: 2,
                    child: Center(
                      child: Text('Aquí irán las opciones de personalización'),
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 20,
                left: 20,
                child: FloatingActionButton(
                  onPressed: () => Navigator.of(context).pop(),
                  backgroundColor: fabBackgroundColor,
                  child: Icon(Icons.arrow_back, color: fabIconColor),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
