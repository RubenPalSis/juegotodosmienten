import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ... (otros métodos existentes) ...

  /// Actualiza las monedas del usuario usando incrementos atómicos para mayor seguridad.
  Future<void> updateUserCoins(String alias, {int? gold, int? bronze}) async {
    Map<String, dynamic> dataToUpdate = {};
    if (gold != null) dataToUpdate['gold_coins'] = FieldValue.increment(gold);
    if (bronze != null)
      dataToUpdate['bronze_coins'] = FieldValue.increment(bronze);

    if (dataToUpdate.isNotEmpty) {
      await _db.collection('aliases').doc(alias).update(dataToUpdate);
    }
  }

  // Obtener un usuario por su alias
  Future<User?> getUserByAlias(String alias) async {
    DocumentSnapshot doc = await _db.collection('aliases').doc(alias).get();
    if (doc.exists) {
      return User.fromFirestore(doc);
    }
    return null;
  }

  // Crear un nuevo usuario con valores iniciales
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

  /// Crea una nueva sala y añade al host como primer jugador.
  Future<String> createRoom({
    required String hostAlias,
    required Map<String, dynamic> hostData,
    required int maxPlayers,
    required bool isPublic,
  }) async {
    // Genera un código de 6 dígitos único para la sala
    String roomCode;
    DocumentReference roomRef;

    do {
      roomCode = (100000 + Random().nextInt(900000)).toString();
      roomRef = _db.collection('rooms').doc(roomCode);
    } while ((await roomRef.get()).exists);

    // Crea la sala y añade al host en una transacción para asegurar la consistencia
    await _db.runTransaction((transaction) async {
      // Crea el documento de la sala
      transaction.set(roomRef, {
        'hostAlias': hostAlias,
        'maxPlayers': maxPlayers,
        'isPublic': isPublic,
        'createdAt': FieldValue.serverTimestamp(),
        'playerCount': 1,
      });

      // Añade al host a la subcolección de jugadores
      final playerRef = roomRef.collection('players').doc(hostAlias);
      transaction.set(playerRef, hostData);
    });

    return roomCode;
  }

  /// Devuelve un stream con todas las salas públicas.
  Stream<QuerySnapshot> getAllRooms() {
    return _db
        .collection('rooms')
        .where('isPublic', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Permite a un jugador unirse a una sala, con comprobaciones de seguridad.
  Future<void> joinGameRoom({
    required String roomCode,
    required String playerAlias,
    required Map<String, dynamic> playerData,
  }) async {
    final roomRef = _db.collection('rooms').doc(roomCode);
    final playerRef = roomRef.collection('players').doc(playerAlias);

    await _db.runTransaction((transaction) async {
      final roomDoc = await transaction.get(roomRef);
      if (!roomDoc.exists) {
        throw Exception('La sala no existe.');
      }

      final playerDoc = await transaction.get(playerRef);
      // Si el jugador ya está en la sala, no hagas nada y permite el acceso.
      if (playerDoc.exists) {
        return;
      }

      final roomData = roomDoc.data() as Map<String, dynamic>;
      final playerCount = roomData['playerCount'] ?? 0;
      final maxPlayers = roomData['maxPlayers'] ?? 0;

      if (playerCount >= maxPlayers) {
        throw Exception('La sala está llena.');
      }

      transaction.update(roomRef, {'playerCount': FieldValue.increment(1)});
      transaction.set(playerRef, playerData);
    });
  }

  /// Elimina las salas que lleven más de 2 horas inactivas.
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

  // Actualizar el idioma del usuario
  Future<void> updateUserLanguage(String alias, String languageCode) async {
    await _db.collection('aliases').doc(alias).update({
      'language': languageCode,
    });
  }

  // Actualizar el email del usuario
  Future<void> updateUserEmail(String alias, String email) async {
    await _db.collection('aliases').doc(alias).update({'email': email});
  }

  /// Devuelve un stream con los datos de una sala específica.
  Stream<DocumentSnapshot> getGameRoomStream(String roomCode) {
    return _db.collection('rooms').doc(roomCode).snapshots();
  }

  /// Permite a un jugador abandonar una sala.
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

  /// Devuelve un stream con los mensajes del chat de una sala.
  Stream<QuerySnapshot> getChatStream(String roomCode) {
    return _db
        .collection('rooms')
        .doc(roomCode)
        .collection('chat')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots();
  }

  /// Envía un mensaje al chat de la sala.
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

  /// Actualiza los ajustes de una sala (para el host).
  Future<void> updateRoomSettings(
    String roomCode, {
    bool? isPublic,
    int? maxPlayers,
  }) async {
    final Map<String, dynamic> dataToUpdate = {};
    if (isPublic != null) dataToUpdate['isPublic'] = isPublic;
    if (maxPlayers != null) dataToUpdate['maxPlayers'] = maxPlayers;

    if (dataToUpdate.isNotEmpty) {
      await _db.collection('rooms').doc(roomCode).update(dataToUpdate);
    }
  }

  /// Expulsa a un jugador de la sala.
  Future<void> kickPlayer(String roomCode, String playerAlias) async {
    // Simplemente elimina al jugador de la sala.
    // La lógica para evitar que vuelva a entrar se podría gestionar con una lista de "kicked",
    // pero por simplicidad, solo lo eliminamos.
    await leaveGameRoom(roomCode: roomCode, playerAlias: playerAlias);
  }

  /// Banea a un jugador de la sala.
  Future<void> banPlayer(String roomCode, String playerAlias) async {
    // Añade el alias a una subcolección de 'banned' y luego expulsa al jugador.
    final roomRef = _db.collection('rooms').doc(roomCode);
    await roomRef.collection('banned').doc(playerAlias).set({});
    await kickPlayer(roomCode, playerAlias);
  }

  Stream<QuerySnapshot> getPlayersStream(String roomCode) {
    return _db
        .collection('rooms')
        .doc(roomCode)
        .collection('players')
        .snapshots();
  }

  // Añadir un personaje desbloqueado
  Future<void> addUnlockedCharacter(String alias, String character) async {
    await _db.collection('aliases').doc(alias).update({
      'unlockedCharacters': FieldValue.arrayUnion([character]),
    });
  }

  // Actualizar personaje seleccionado
  Future<void> updateSelectedCharacter(String alias, String character) async {
    await _db.collection('aliases').doc(alias).update({
      'selectedCharacter': character,
    });
  }
}
