
import 'package:flutter/material.dart';

class AvatarScreen extends StatelessWidget {
  static const routeName = '/avatar';

  const AvatarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personalizar Avatar'), // TODO: Localize
      ),
      body: const Center(
        child: Text('Aquí irán las opciones de personalización del avatar.'), // TODO: Localize
      ),
    );
  }
}
