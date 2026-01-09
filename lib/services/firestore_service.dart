
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final List<String> availableColors = [
    '#E6194B', '#3CB44B', '#4363D8', '#FFE119', '#F58231', '#911EB4',
    '#42D4F4', '#F032E6', '#BFEF45', '#FABED4', '#9A6324', '#469990',
    '#2E7D32', '#000075', '#000000', '#FFFAC8'
  ];

  String _generateRoomCode() {
    return (100000 + Random().nextInt(900000)).toString();
  }

  Stream<QuerySnapshot> getPublicRooms() {
    return _db.collection('rooms').where('status', isEqualTo: 'waiting').snapshots();
  }

  Stream<DocumentSnapshot> getGameRoomStream(String roomCode) {
    return _db.collection('rooms').doc(roomCode).snapshots();
  }

  Future<String> createRoom({
    required String hostId,
    required Map<String, dynamic> hostData,
    required int maxPlayers,
  }) async {
    final roomCode = _generateRoomCode();
    final roomRef = _db.collection('rooms').doc(roomCode);

    final randomColor = availableColors[Random().nextInt(availableColors.length)];
    hostData['color'] = randomColor;

    await roomRef.set({
      'roomCode': roomCode,
      'maxPlayers': maxPlayers,
      'hostId': hostId,
      'players': [hostData],
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'waiting',
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

    if (!players.any((p) => p['uid'] != null && p['uid'] == playerData['uid'])) {
      final usedColors = players.map((p) => p['color']).whereType<String>().toSet();
      final availableColorsInRoom = availableColors.where((c) => !usedColors.contains(c)).toList();

      if (availableColorsInRoom.isEmpty) {
        playerData['color'] = availableColors[Random().nextInt(availableColors.length)];
      } else {
        playerData['color'] = availableColorsInRoom[Random().nextInt(availableColorsInRoom.length)];
      }
      
      await roomRef.update({
        'players': FieldValue.arrayUnion([playerData])
      });
    }

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
      if (roomData['hostId'] == userId) {
        await roomRef.delete();
      } else {
        final players = List<Map<String, dynamic>>.from(roomData['players'] ?? []);
        players.removeWhere((p) => p['uid'] == userId);
        await roomRef.update({'players': players});
      }
    }
  }

  Future<void> changePlayerColor(String roomCode, String userId, String newColor) async {
    final roomRef = _db.collection('rooms').doc(roomCode);
    final doc = await roomRef.get();

    if (doc.exists) {
      final roomData = doc.data()!;
      final players = List<Map<String, dynamic>>.from(roomData['players'] ?? []);
      final otherPlayersColors = players
          .where((p) => p['uid'] != null && p['uid'] != userId)
          .map((p) => p['color'])
          .whereType<String>()
          .toSet();

      if (otherPlayersColors.contains(newColor)) {
        throw 'El color ya está en uso por otro jugador.';
      }

      final playerIndex = players.indexWhere((p) => p['uid'] != null && p['uid'] == userId);
      if (playerIndex != -1) {
        players[playerIndex]['color'] = newColor;
        await roomRef.update({'players': players});
      }
    }
  }
}
