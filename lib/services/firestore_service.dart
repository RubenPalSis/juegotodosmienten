
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
      'lastAccess': FieldValue.serverTimestamp(), // Also update last access time
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

    final randomColor = availableColors[Random().nextInt(availableColors.length)];
    hostData['color'] = randomColor;

    await roomRef.set({
      'roomCode': roomCode,
      'maxPlayers': maxPlayers,
      'hostId': hostId,
      'isPublic': isPublic,
      'players': [hostData],
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'waiting',
      'emptyAt': null, // Initialize emptyAt field
    });

    return roomCode;
  }

  Future<bool> joinGameRoom({
    required String roomCode,
    required Map<String, dynamic> playerData,
  }) async {
    final roomRef = _db.collection('rooms').doc(roomCode);
    final doc = await roomRef.get();

    if (!doc.exists) {
      throw 'La sala no existe o el código es incorrecto.';
    }

    final roomData = doc.data()!;
    final players = List<Map<String, dynamic>>.from(roomData['players'] ?? []);

    if (players.length >= roomData['maxPlayers']) {
      throw 'La sala ya está llena.';
    }

    if (players.any((p) => p['uid'] == playerData['uid'])) {
      return true; // Already in the room
    }

    final usedColors = players.map((p) => p['color']).whereType<String>().toSet();
    final available = availableColors.where((c) => !usedColors.contains(c)).toList();
    playerData['color'] = available.isEmpty ? availableColors[Random().nextInt(availableColors.length)] : available.first;

    // When a player joins, cancel the deletion timer by setting emptyAt to null.
    await roomRef.update({
      'players': FieldValue.arrayUnion([playerData]),
      'emptyAt': null,
    });

    return true;
  }

  Future<void> leaveGameRoom({
    required String roomCode,
    required String userId,
  }) async {
    final roomRef = _db.collection('rooms').doc(roomCode);
    final doc = await roomRef.get();

    if (doc.exists) {
      final roomData = doc.data()!;
      final players = List<Map<String, dynamic>>.from(roomData['players'] ?? []);

      if (roomData['hostId'] == userId) {
        await roomRef.delete(); // Host leaves, room is deleted instantly
      } else {
        players.removeWhere((p) => p['uid'] == userId);
        if (players.isEmpty) {
          // If the last player leaves, set a timestamp to delete the room later.
          await roomRef.update({
            'players': [],
            'emptyAt': FieldValue.serverTimestamp(),
          });
        } else {
          await roomRef.update({'players': players});
        }
      }
    }
  }

  Future<void> cleanupInactiveRooms() async {
    final fifteenSecondsAgo = Timestamp.fromMillisecondsSinceEpoch(
      DateTime.now().subtract(const Duration(seconds: 15)).millisecondsSinceEpoch,
    );

    final snapshot = await _db
        .collection('rooms')
        .where('emptyAt', isLessThanOrEqualTo: fifteenSecondsAgo)
        .get();

    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }


  Future<void> changePlayerColor(String roomCode, String userId, String newColor) async {
    final roomRef = _db.collection('rooms').doc(roomCode);
    final doc = await roomRef.get();

    if (doc.exists) {
      final roomData = doc.data()!;
      final players = List<Map<String, dynamic>>.from(roomData['players'] ?? []);
      final otherPlayersColors = players
          .where((p) => p['uid'] != userId)
          .map((p) => p['color'])
          .whereType<String>()
          .toSet();

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
