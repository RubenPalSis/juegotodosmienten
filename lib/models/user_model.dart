class User {
  final int id;
  final String uid;
  final String alias;
  final int totalExp;
  final String? selectedCharacter;

  static const String colId = 'id';
  static const String colUid = 'uid';
  static const String colAlias = 'alias';
  static const String colTotalExp = 'totalExp';
  static const String colSelectedCharacter = 'selectedCharacter';

  User({
    required this.id,
    required this.uid,
    required this.alias,
    required this.totalExp,
    this.selectedCharacter,
  });

  Map<String, dynamic> toMap() {
    return {
      colId: id,
      colUid: uid,
      colAlias: alias,
      colTotalExp: totalExp,
      colSelectedCharacter: selectedCharacter,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map[colId],
      uid: map[colUid],
      alias: map[colAlias],
      totalExp: map[colTotalExp],
      selectedCharacter: map[colSelectedCharacter],
    );
  }
}
