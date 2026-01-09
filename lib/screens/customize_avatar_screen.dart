import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class CustomizeAvatarScreen extends StatelessWidget {
  static const routeName = '/customize-avatar';
  final String characterFile;

  const CustomizeAvatarScreen({super.key, required this.characterFile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personalizar Avatar'),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: ModelViewer(
              src: 'assets/models/$characterFile',
              alt: "Avatar Preview",
              autoRotate: true,
              cameraControls: true,
              environmentImage: 'neutral',
              backgroundColor: Theme.of(context).canvasColor,
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
    );
  }
}
