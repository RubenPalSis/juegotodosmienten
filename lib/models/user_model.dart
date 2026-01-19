class User {
  final int id;
  final String uid;
  final String alias;
  final int totalExp;
  final String? selectedCharacter;
  final int goldCoins;
  final int bronzeCoins;
  final String? email;

  static const String colId = 'id';
  static const String colUid = 'uid';
  static const String colAlias = 'alias';
  static const String colTotalExp = 'totalExp';
  static const String colSelectedCharacter = 'selectedCharacter';
  static const String colGoldCoins = 'goldCoins';
  static const String colBronzeCoins = 'bronzeCoins';
  static const String colEmail = 'email';

  User({
    required this.id,
    required this.uid,
    required this.alias,
    required this.totalExp,
    this.selectedCharacter,
    this.goldCoins = 0,
    this.bronzeCoins = 0,
    this.email,
  });

  Map<String, dynamic> toMap() {
    return {
      colId: id,
      colUid: uid,
      colAlias: alias,
      colTotalExp: totalExp,
      colSelectedCharacter: selectedCharacter,
      colGoldCoins: goldCoins,
      colBronzeCoins: bronzeCoins,
      colEmail: email,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map[colId],
      uid: map[colUid],
      alias: map[colAlias],
      totalExp: map[colTotalExp],
      selectedCharacter: map[colSelectedCharacter],
      goldCoins: map[colGoldCoins] ?? 0,
      bronzeCoins: map[colBronzeCoins] ?? 0,
      email: map[colEmail],
    );
  }
}
