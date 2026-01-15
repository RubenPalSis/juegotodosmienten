import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final List<String> availableColors = [
    '#E6194B', '#3CB44B', '#4363D8', '#FFE119', '#F58231', '#911EB4',
    '#42D4F4', '#F032E6', '#BFEF45', '#FABED4', '#9A6324', '#469990',
    '#2E7D32', '#000075', '#000000', '#FFFAC8'
  ];

  // --- User Profile Methods ---

  Future<DocumentSnapshot?> getUserProfile(String uid) async {
    final query = await _db.collection('aliases').where('uid', isEqualTo: uid).limit(1).get();
    if (query.docs.isNotEmpty) {
      return query.docs.first;
    }
    return null;
  }

  Future<bool> isAliasTaken(String alias) async {
    final doc = await _db.collection('aliases').doc(alias).get();
    return doc.exists;
  }

  Future<void> createUserProfile({
    required String alias,
    required String uid,
    required String language,
  }) async {
    final docRef = _db.collection('aliases').doc(alias);
    await docRef.set({
      'uid': uid,
      'language': language,
      'totalExp': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'lastAccess': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateUserLanguage(String alias, String newLanguage) async {
    final docRef = _db.collection('aliases').doc(alias);
    await docRef.update({
      'language': newLanguage,
      'lastAccess': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addXpToPlayer(String uid, int xp) async {
    final query = await _db.collection('aliases').where('uid', isEqualTo: uid).limit(1).get();
    if (query.docs.isNotEmpty) {
      final docRef = query.docs.first.reference;
      await docRef.update({'totalExp': FieldValue.increment(xp)});
    }
  }

  // --- Chat Methods ---

  Stream<QuerySnapshot> getChatStream(String roomCode) {
    return _db.collection('rooms').doc(roomCode).collection('messages').orderBy('timestamp', descending: true).limit(50).snapshots();
  }

  Future<void> sendMessage({
    required String roomCode,
    required String text,
    required String alias,
    required String uid,
    required String color,
    bool isEvent = false,
  }) async {
    await _db.collection('rooms').doc(roomCode).collection('messages').add({
      'text': text,
      'alias': alias,
      'uid': uid,
      'color': color,
      'isEvent': isEvent,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // --- Game Room Methods ---

  Future<String> _generateUniqueRoomCode() async {
    String code;
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final random = Random();
    do {
      final numbers = (1000 + random.nextInt(9000)).toString();
      final letter = letters[random.nextInt(letters.length)];
      code = numbers + letter;
    } while (await _db.collection('rooms').doc(code).get().then((doc) => doc.exists));
    return code;
  }

  Stream<QuerySnapshot> getAllRooms() {
    return _db.collection('rooms').where('status', isEqualTo: 'waiting').snapshots();
  }

  Stream<DocumentSnapshot> getGameRoomStream(String roomCode) {
    return _db.collection('rooms').doc(roomCode).snapshots();
  }

  Future<String> createRoom({
    required String hostId,
    required Map<String, dynamic> hostData,
    required int maxPlayers,
    required bool isPublic,
  }) async {
    final roomCode = await _generateUniqueRoomCode();
    final roomRef = _db.collection('rooms').doc(roomCode);

    hostData['color'] = availableColors[Random().nextInt(availableColors.length)];
    hostData['isReady'] = false;

    await roomRef.set({
      'roomCode': roomCode,
      'maxPlayers': maxPlayers,
      'hostId': hostId,
      'isPublic': isPublic,
      'players': [hostData],
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'waiting',
      'bannedUIDs': [], // Initialize banned list
    });

    return roomCode;
  }

  Future<bool> joinGameRoom({
    required String roomCode,
    required Map<String, dynamic> playerData,
  }) async {
    final roomRef = _db.collection('rooms').doc(roomCode);
    final doc = await roomRef.get();

    if (!doc.exists) throw 'La sala no existe o el código es incorrecto.';

    final roomData = doc.data()!;
    final players = List<Map<String, dynamic>>.from(roomData['players'] ?? []);
    final bannedUIDs = List<String>.from(roomData['bannedUIDs'] ?? []);

    if (bannedUIDs.contains(playerData['uid'])) throw 'Has sido baneado de esta sala.';
    if (players.length >= roomData['maxPlayers']) throw 'La sala ya está llena.';
    if (players.any((p) => p['uid'] == playerData['uid'])) return true;

    final usedColors = players.map((p) => p['color']).whereType<String>().toSet();
    final available = availableColors.where((c) => !usedColors.contains(c)).toList();
    playerData['color'] = available.isEmpty ? availableColors[Random().nextInt(availableColors.length)] : available.first;
    playerData['isReady'] = false;

    await roomRef.update({
      'players': FieldValue.arrayUnion([playerData]),
    });
    
    await sendMessage(roomCode: roomCode, text: 'se ha unido a la sala', alias: playerData['alias'], uid: playerData['uid'], color: playerData['color'], isEvent: true);

    return true;
  }

  Future<void> leaveGameRoom({ required String roomCode, required String userId }) async {
    final roomRef = _db.collection('rooms').doc(roomCode);
    await _db.runTransaction((transaction) async {
      final doc = await transaction.get(roomRef);
      if (!doc.exists) return;

      final roomData = doc.data()!;
      final players = List<Map<String, dynamic>>.from(roomData['players'] ?? []);
      final playerLeaving = players.firstWhere((p) => p['uid'] == userId, orElse: () => {});

      if (playerLeaving.isNotEmpty) {
        await sendMessage(roomCode: roomCode, text: 'ha salido de la sala', alias: playerLeaving['alias'], uid: userId, color: playerLeaving['color'], isEvent: true);
      }

      if (roomData['hostId'] == userId) {
        transaction.delete(roomRef);
      } else {
        players.removeWhere((p) => p['uid'] == userId);
        FieldValue? emptyAtValue = (players.isEmpty) ? FieldValue.serverTimestamp() : null;
        transaction.update(roomRef, {'players': players, 'emptyAt': emptyAtValue});
      }
    });
  }

  Future<void> kickPlayer(String roomCode, String userIdToKick, String hostAlias, String kickedAlias) async {
    final roomRef = _db.collection('rooms').doc(roomCode);
    final players = List<Map<String, dynamic>>.from((await roomRef.get()).data()!['players'] ?? []);
    players.removeWhere((p) => p['uid'] == userIdToKick);
    await roomRef.update({'players': players});
    await sendMessage(roomCode: roomCode, text: 'ha expulsado a $kickedAlias', alias: hostAlias, uid: '', color: '#FFFFFF', isEvent: true);
  }

  Future<void> banPlayer(String roomCode, String userIdToBan, String hostAlias, String bannedAlias) async {
    final roomRef = _db.collection('rooms').doc(roomCode);
    final players = List<Map<String, dynamic>>.from((await roomRef.get()).data()!['players'] ?? []);
    players.removeWhere((p) => p['uid'] == userIdToBan);
    await roomRef.update({
      'players': players,
      'bannedUIDs': FieldValue.arrayUnion([userIdToBan]),
    });
    await sendMessage(roomCode: roomCode, text: 'ha baneado a $bannedAlias', alias: hostAlias, uid: '', color: '#FFFFFF', isEvent: true);
  }

  Future<void> togglePlayerReadyState(String roomCode, String userId) async {
    final roomRef = _db.collection('rooms').doc(roomCode);
    final doc = await roomRef.get();
    if (doc.exists) {
      final players = List<Map<String, dynamic>>.from(doc.data()!['players'] ?? []);
      final playerIndex = players.indexWhere((p) => p['uid'] == userId);
      if (playerIndex != -1) {
        players[playerIndex]['isReady'] = !(players[playerIndex]['isReady'] ?? false);
        await roomRef.update({'players': players});
      }
    }
  }

  Future<void> startGame(String roomCode) async {
    final roomRef = _db.collection('rooms').doc(roomCode);
    final doc = await roomRef.get();
    if(doc.exists) {
      final players = List<Map<String, dynamic>>.from(doc.data()!['players'] ?? []);
      final random = Random();
      for (var player in players) {
        await addXpToPlayer(player['uid'], random.nextInt(101));
      }
      await roomRef.delete();
    }
  }

   Future<void> updateRoomSettings(String roomCode, {int? maxPlayers, bool? isPublic}) async {
    final Map<String, dynamic> updates = {};
    if (maxPlayers != null) updates['maxPlayers'] = maxPlayers;
    if (isPublic != null) updates['isPublic'] = isPublic;

    if (updates.isNotEmpty) {
      await _db.collection('rooms').doc(roomCode).update(updates);
    }
  }

  Future<void> cleanupInactiveRooms() async {
    final now = Timestamp.now();
    final fifteenSecondsAgo = Timestamp.fromMillisecondsSinceEpoch(now.millisecondsSinceEpoch - 15000);
    final fiveMinutesAgo = Timestamp.fromMillisecondsSinceEpoch(now.millisecondsSinceEpoch - 300000);

    final emptyRoomsQuery = _db.collection('rooms').where('emptyAt', isLessThanOrEqualTo: fifteenSecondsAgo);
    final staleRoomsQuery = _db.collection('rooms').where('createdAt', isLessThanOrEqualTo: fiveMinutesAgo);

    final batch = _db.batch();

    final emptyRoomsSnapshot = await emptyRoomsQuery.get();
    for (final doc in emptyRoomsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    final staleRoomsSnapshot = await staleRoomsQuery.get();
    for (final doc in staleRoomsSnapshot.docs) {
      final data = doc.data();
      final players = data['players'] as List<dynamic>? ?? [];
      if (players.length == 1) {
        batch.delete(doc.reference);
      }
    }

    await batch.commit();
  }


  Future<void> changePlayerColor(String roomCode, String userId, String newColor) async {
    final roomRef = _db.collection('rooms').doc(roomCode);
    final doc = await roomRef.get();

    if (doc.exists) {
      final roomData = doc.data()!;
      final players = List<Map<String, dynamic>>.from(roomData['players'] ?? []);
      final otherPlayersColors = players.where((p) => p['uid'] != userId).map((p) => p['color']).whereType<String>().toSet();

      if (otherPlayersColors.contains(newColor)) {
        throw 'El color ya está en uso por otro jugador.';
      }

      final playerIndex = players.indexWhere((p) => p['uid'] == userId);
      if (playerIndex != -1) {
        players[playerIndex]['color'] = newColor;
        await roomRef.update({'players': players});
      }
    }
  }
}
