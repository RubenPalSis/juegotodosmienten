import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> updateUserCoins(String alias, {int? gold, int? bronze}) async {
    Map<String, dynamic> dataToUpdate = {};
    if (gold != null) dataToUpdate['gold_coins'] = FieldValue.increment(gold);
    if (bronze != null) dataToUpdate['bronze_coins'] = FieldValue.increment(bronze);
    if (dataToUpdate.isNotEmpty) {
      await _db.collection('aliases').doc(alias).update(dataToUpdate);
    }
  }

  Future<User?> getUserByAlias(String alias) async {
    DocumentSnapshot doc = await _db.collection('aliases').doc(alias).get();
    if (doc.exists) {
      return User.fromFirestore(doc);
    }
    return null;
  }

  Future<void> createUser(String alias, String uid) async {
    final user = User(
      alias: alias,
      uid: uid,
      email: '',
      totalExp: 0,
      goldCoins: 0,
      bronzeCoins: 0,
      selectedCharacter: 'robot.glb',
      unlockedCharacters: ['robot.glb'],
    );
    await _db.collection('aliases').doc(alias).set(user.toFirestore());
  }

  Future<String> createRoom({
    required String hostAlias,
    required String hostUid,
    required Map<String, dynamic> hostData,
    required int maxPlayers,
    required bool isPublic,
  }) async {
    String roomCode;
    DocumentReference roomRef;
    do {
      roomCode = (100000 + Random().nextInt(900000)).toString();
      roomRef = _db.collection('rooms').doc(roomCode);
    } while ((await roomRef.get()).exists);

    await _db.runTransaction((transaction) async {
      transaction.set(roomRef, {
        'hostId': hostUid,
        'hostAlias': hostAlias,
        'maxPlayers': maxPlayers,
        'isPublic': isPublic,
        'createdAt': FieldValue.serverTimestamp(),
        'playerCount': 1,
      });
      final playerRef = roomRef.collection('players').doc(hostAlias);
      transaction.set(playerRef, hostData);
    });
    return roomCode;
  }

  Stream<QuerySnapshot> getAllRooms() {
    return _db
        .collection('rooms')
        .where('isPublic', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> joinGameRoom({
    required String roomCode,
    required String playerAlias,
    required Map<String, dynamic> playerData,
  }) async {
    final roomRef = _db.collection('rooms').doc(roomCode);
    final playerRef = roomRef.collection('players').doc(playerAlias);
    await _db.runTransaction((transaction) async {
      final roomDoc = await transaction.get(roomRef);
      if (!roomDoc.exists) throw Exception('La sala no existe.');
      final playerDoc = await transaction.get(playerRef);
      if (playerDoc.exists) return;
      final roomData = roomDoc.data() as Map<String, dynamic>;
      if ((roomData['playerCount'] ?? 0) >= (roomData['maxPlayers'] ?? 0)) {
        throw Exception('La sala está llena.');
      }
      transaction.update(roomRef, {'playerCount': FieldValue.increment(1)});
      transaction.set(playerRef, playerData);
    });
  }

  Future<void> cleanupInactiveRooms() async {
    final twoHoursAgo = DateTime.now().subtract(const Duration(hours: 2));
    final snapshot = await _db
        .collection('rooms')
        .where('createdAt', isLessThan: twoHoursAgo)
        .get();
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> updateUserLanguage(String alias, String languageCode) async {
    await _db.collection('aliases').doc(alias).update({
      'language': languageCode,
    });
  }

  Future<void> updateUserEmail(String alias, String email) async {
    await _db.collection('aliases').doc(alias).update({'email': email});
  }

  Stream<DocumentSnapshot> getGameRoomStream(String roomCode) {
    return _db.collection('rooms').doc(roomCode).snapshots();
  }

  Future<void> leaveGameRoom({
    required String roomCode,
    required String playerAlias,
  }) async {
    final roomRef = _db.collection('rooms').doc(roomCode);
    final playerRef = roomRef.collection('players').doc(playerAlias);
    await _db.runTransaction((transaction) async {
      transaction.delete(playerRef);
      transaction.update(roomRef, {'playerCount': FieldValue.increment(-1)});
    });
  }

  Stream<QuerySnapshot> getChatStream(String roomCode) {
    return _db
        .collection('rooms')
        .doc(roomCode)
        .collection('chat')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  Future<void> sendMessage({
    required String roomCode,
    required String alias,
    required String text,
  }) async {
    await _db.collection('rooms').doc(roomCode).collection('chat').add({
      'alias': alias,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'isEvent': false,
    });
  }

  Future<void> updateRoomSettings(String roomCode, {bool? isPublic, int? maxPlayers}) async {
    final Map<String, dynamic> dataToUpdate = {};
    if (isPublic != null) dataToUpdate['isPublic'] = isPublic;
    if (maxPlayers != null) dataToUpdate['maxPlayers'] = maxPlayers;
    if (dataToUpdate.isNotEmpty) {
      await _db.collection('rooms').doc(roomCode).update(dataToUpdate);
    }
  }

  Future<void> kickPlayer(String roomCode, String playerAlias) async {
    await leaveGameRoom(roomCode: roomCode, playerAlias: playerAlias);
  }

  Future<void> banPlayer(String roomCode, String playerAlias) async {
    final roomRef = _db.collection('rooms').doc(roomCode);
    await roomRef.collection('banned').doc(playerAlias).set({});
    await kickPlayer(roomCode, playerAlias);
  }

  Stream<QuerySnapshot> getPlayersStream(String roomCode) {
    return _db.collection('rooms').doc(roomCode).collection('players').snapshots();
  }

  Future<void> updatePlayerColor(String roomCode, String playerAlias, int colorValue) async {
    final playerRef = _db.collection('rooms').doc(roomCode).collection('players').doc(playerAlias);
    await playerRef.update({'color': colorValue});
  }
  
  Future<void> setPlayerReadyStatus({required String roomCode, required String playerAlias, required bool isReady}) async {
    final playerRef = _db.collection('rooms').doc(roomCode).collection('players').doc(playerAlias);
    await playerRef.update({'isReady': isReady});
  }

  Future<void> purchaseAndUnlockColor(String alias, int colorValue, int cost) async {
    final userRef = _db.collection('aliases').doc(alias);
    await _db.runTransaction((transaction) async {
      final userDoc = await transaction.get(userRef);
      if (!userDoc.exists) throw Exception("User not found");

      final currentGold = (userDoc.data()! as Map<String, dynamic>)['gold_coins'] ?? 0;
      if (currentGold < cost) throw Exception("Not enough gold coins");

      transaction.update(userRef, {
        'gold_coins': FieldValue.increment(-cost),
        'unlockedColors': FieldValue.arrayUnion([colorValue]),
      });
    });
  }

  Future<void> addUnlockedCharacter(String alias, String character) async {
    await _db.collection('aliases').doc(alias).update({
      'unlockedCharacters': FieldValue.arrayUnion([character]),
    });
  }

  Future<void> updateSelectedCharacter(String alias, String character) async {
    await _db.collection('aliases').doc(alias).update({
      'selectedCharacter': character,
    });
  }
}
