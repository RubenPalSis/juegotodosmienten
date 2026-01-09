import 'package:flutter/foundation.dart';

@immutable
class Character {
  final String name;
  final String assetFile;

  const Character({required this.name, required this.assetFile});
}

class CharacterService {
  final List<Character> _characters = [
    const Character(name: 'Robot', assetFile: 'robot.glb'),
    const Character(name: 'Little Man', assetFile: 'little_man.glb'),
  ];

  List<Character> get characters => _characters;
}
