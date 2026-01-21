import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String uid;
  final String alias;
  final String email;
  final int totalExp;
  final int goldCoins;
  final int bronzeCoins;
  final String selectedCharacter;
  final List<String> unlockedCharacters;
  final List<int> unlockedColors;

  User({
    required this.uid,
    required this.alias,
    this.email = '',
    this.totalExp = 0,
    this.goldCoins = 0,
    this.bronzeCoins = 0,
    this.selectedCharacter = 'robot.glb',
    List<String>? unlockedCharacters,
    List<int>? unlockedColors,
  }) : unlockedCharacters = unlockedCharacters ?? ['robot.glb'],
       unlockedColors = unlockedColors ?? [];

  factory User.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return User(
      uid: data['uid'],
      alias: doc.id,
      email: data['email'] ?? '',
      totalExp: data['totalExp'] ?? 0,
      goldCoins: data['gold_coins'] ?? 0,
      bronzeCoins: data['bronze_coins'] ?? 0,
      selectedCharacter: data['selectedCharacter'] ?? 'robot.glb',
      unlockedCharacters: List<String>.from(
        data['unlockedCharacters'] ?? ['robot.glb'],
      ),
      unlockedColors: List<int>.from(data['unlockedColors'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'totalExp': totalExp,
      'gold_coins': goldCoins,
      'bronze_coins': bronzeCoins,
      'selectedCharacter': selectedCharacter,
      'unlockedCharacters': unlockedCharacters,
      'unlockedColors': unlockedColors,
    };
  }
}
