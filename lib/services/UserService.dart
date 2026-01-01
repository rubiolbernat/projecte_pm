import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projecte_pm/models/subClass/save_id.dart';
import 'package:projecte_pm/models/user.dart';
import 'dart:developer';

class UserService {
  final FirebaseFirestore _firestore;
  final DocumentReference? _currentUserRef;
  User _user;

  UserService._({
    required FirebaseFirestore firestore,
    required DocumentReference currentUserRef,
    required User user,
  }) : _firestore = firestore,
       _currentUserRef = currentUserRef,
       _user = user;

  static Future<UserService> create({required String userId}) async {
    final firestore = FirebaseFirestore.instance;
    final ref = firestore.collection('users').doc(userId);

    final snap = await ref.get();
    if (!snap.exists) {
      throw Exception('Usuari no trobat');
    }

    final user = User.fromMap(snap.data() as Map<String, dynamic>);

    return UserService._(firestore: firestore, currentUserRef: ref, user: user);
  }

  String? get currentUserId => _user.id;
  DocumentReference? get currentUserRef => _currentUserRef;

  // Getters de user
  User get user => _user;

  // Metòdes CRUD
  Future<void> refreshUser() async {
    final snap = await _currentUserRef!.get();
    _user = User.fromMap(snap.data() as Map<String, dynamic>);
  }

  Future<void> updateUser(User user) async {
    if (_currentUserRef == null) return;
    try {
      await _currentUserRef!.update(user.toMap());
    } catch (e) {
      print("Error actualitzant usuari: $e");
      rethrow;
    }
  }

  // Metode per seguir/desseguir usuaris
  Future<void> followUser(String targetUserId) async {
    if (_currentUserRef == targetUserId) return;

    try {
      final targetUserRef = _firestore.collection('users').doc(targetUserId);
      final targetUserDoc = await targetUserRef.get();

      if (!targetUserDoc.exists) {
        throw Exception('Usuari no trobat');
      }

      final currentUserDoc = await _currentUserRef!.get();
      final currentUserData = currentUserDoc.data() as Map<String, dynamic>;

      final targetUserData = targetUserDoc.data() as Map<String, dynamic>;

      final currentFollowers = List<Map<String, dynamic>>.from(
        targetUserData['follower'] ?? [],
      );

      final currentFollowing = List<Map<String, dynamic>>.from(
        currentUserData['following'] ?? [],
      );

      if (currentFollowing.any(
        (following) => following['id'] == targetUserId,
      )) {
        print("L'usuari ja segueix a aquest usuari");
        return;
      }

      final batch = _firestore.batch();

      currentFollowers.add({'id': _user.id});
      batch.update(targetUserRef, {'follower': currentFollowers});

      currentFollowing.add({'id': targetUserId});
      batch.update(_currentUserRef!, {'following': currentFollowing});

      await batch.commit();
      print("Usuari ${_user.id} ara segueix a l'usuari $targetUserId");

      // Actualizar estado local
      await refreshUser();
    } catch (e) {
      print("Error seguint usuari: $e");
      rethrow;
    }
  }

  Future<void> unfollowUser(String targetUserId) async {
    if (_currentUserRef == targetUserId || _currentUserRef == null) return;

    try {
      final targetUserRef = _firestore.collection('users').doc(targetUserId);
      final targetUserDoc = await targetUserRef.get();
      final currentUserDoc = await _currentUserRef!.get();
      final currentUserData = currentUserDoc.data() as Map<String, dynamic>;

      if (!targetUserDoc.exists) {
        throw Exception('Usuari no trobat');
      }

      // Obtener arrays actuales
      final targetUserData = targetUserDoc.data() as Map<String, dynamic>;
      final currentFollowers = List<Map<String, dynamic>>.from(
        targetUserData['follower'] ?? [],
      );

      final currentFollowing = List<Map<String, dynamic>>.from(
        currentUserData['following'] ?? [],
      );

      final batch = _firestore.batch();

      // Eliminar de seguidores del target user
      final updatedFollowers = currentFollowers
          .where((follower) => follower['id'] != _user.id)
          .toList();
      batch.update(targetUserRef, {'follower': updatedFollowers});

      // Eliminar de seguidos del usuario actual
      final updatedFollowing = currentFollowing
          .where((following) => following['id'] != targetUserId)
          .toList();
      batch.update(_currentUserRef!, {'following': updatedFollowing});

      await batch.commit();
      print("Usuari ${_user.id} ha deixat de seguir a l'usuari $targetUserId");

      // Actualizar estado local
      await refreshUser();
    } catch (e) {
      print("Error al deixar de seguir usuari: $e");
      rethrow;
    }
  }

  // Metode per seguir artistes
  Future<void> followArtist(String artistId) async {
    // Seguir artista
    if (_currentUserRef == null) return; // Si no hi ha usuari actual, surt

    final batch = _firestore.batch(); // Inicia una operació en lot

    try {
      // Fetch del artista i la seva llista de followers
      final artistRef = _firestore.collection('artists').doc(artistId);
      final artistDoc = await artistRef.get();

      if (!artistDoc.exists) {
        // Comprovar si l'artista existeix
        throw Exception('Artista no trobat');
      }

      final artistData = artistDoc.data()!; // Obtenir dades de l'artista
      final currentFollowers = List<Map<String, dynamic>>.from(
        // Obtenir llista actual de followers
        artistData['artistFollower'] ?? [],
      );

      // Comprovar si l'usuari ja segueix a l'artista
      if (currentFollowers.any((follower) => follower['id'] == _user.id)) {
        print("L'usuari ja segueixe a aquest artista");
        return;
      }

      // Afegir l'usuari a la llista de followers de l'artista
      currentFollowers.add({'id': _user.id});
      batch.update(artistRef, {'artistFollower': currentFollowers});
      // Afegir l'artista a la llista de followingArtists de l'usuari
      final userFollowingRef = _currentUserRef!
          .collection('followingArtists')
          .doc(artistId);
      // Actualitzar la llista de followers a Firestore
      batch.set(userFollowingRef, {
        'artistId': artistId,
        'followedAt': FieldValue.serverTimestamp(),
      });
      // Actualitzar la llista de followers a Firestore
      await batch.commit();
      // Print de debug per confirmar que funciona
      print("Usuari ${_user.id} ara segueix al artista $artistId");
    } catch (e) {
      // Capturar errors de Firestore
      print("Error seguint artista: $e");
      rethrow;
    }
  }

  // Metode per deixar de seguir artistes
  Future<void> unfollowArtist(String artistId) async {
    if (_currentUserRef == null) return;

    try {
      // Fetch del artista i la seva llista de followers
      final artistRef = _firestore.collection('artists').doc(artistId);
      final artistDoc = await artistRef.get();
      // Comprovar si l'artista existeix, igual que abans
      if (!artistDoc.exists) {
        throw Exception('Artista no encontrado');
      }
      // Obtenim llista de followers actual
      final artistData = artistDoc.data()!;
      final currentFollowers = List<Map<String, dynamic>>.from(
        artistData['artistFollower'] ?? [],
      );
      // Fetch del usuari i l'eliminem l'usuari de la llista de followers
      final updatedFollowers = currentFollowers
          .where((follower) => follower['id'] != _user.id)
          .toList();
      // Eliminar l'artista de la llista de followingArtists de l'usuari
      final userFollowingRef = _currentUserRef!
          .collection('followingArtists')
          .doc(artistId);
      // Eliminar document
      await userFollowingRef.delete();
      // Actualitzar la llista de followers a Firestore
      await artistRef.update({'artistFollower': updatedFollowers});
      // Print de debug per confirmar que funciona
      print("Usuari ${_user.id} ha deixat de seguir al artista $artistId");
      // Capturar errors de Firestore
    } catch (e) {
      print("Error al fer unfollow: $e");
      rethrow;
    }
  }

  // Verificar si l'usuari segueix a un artista
  Future<bool> isFollowingArtist(String artistId) async {
    // Si no hi ha usuari actual, retornem false
    if (_currentUserRef == null) return false;
    // Fetch del artista i comprovació de si l'usuari el segueix
    try {
      final artistDoc = await _currentUserRef!
          .collection('followingArtists')
          .doc(artistId)
          .get();
      // Comprovació si l'artista existeix
      return artistDoc.exists;
    } catch (e) {
      // Capturar errors de Firestore
      print("Error verificant follow: $e");
      return false;
    }
  }

  // Verificar si l'usuari segueix a un altre usuari artista
  Future<bool> isFollowingUser(String targetUserId) async {
    // Si no hi ha usuari actual, retornem false
    if (_currentUserRef == null || _user.id == targetUserId) return false;
    // Fetch del artista i comprovació de si l'usuari el segueix
    try {
      final currentFollowing = _user.following ?? [];
      return currentFollowing.any((following) => following.id == targetUserId);
    } catch (e) {
      // Capturar errors de Firestore
      print("Error verificant follow: $e");
      return false;
    }
  }

  // Metodes de PlayerService
  Future<void> addToHistory(String songId) async {
    try {
      final historyRef = _currentUserRef!.collection(
        'playHistory',
      ); // Referència a l'historial de reproducció

      await historyRef.add({
        // Afegeix una nova entrada a l'historial
        'songId': _firestore.doc('songs/$songId'), // Referència a la cançó
        'playedAt': FieldValue.serverTimestamp(), // Timestamp de reproducció
        'playDuration': 0, // Duració de reproducció (inicialment 0)
        'completed': false, // Estat de completat (inicialment false)
      });

      log(
        'Cançó $songId afegida a historial',
        name: 'UserService',
      ); // Log de confirmació
    } catch (e) {
      // Captura d'errors
      print("Error guardant historial: $e");
    }
  }

  /////////////////////////////////////////////////////////////////////////////
  // Rebre novetats                                                          //
  /////////////////////////////////////////////////////////////////////////////
  Future<List<Map<String, dynamic>>> getGlobalNewReleases({
    String? name,
    bool readSongs = false,
    bool readAlbums = false,
    bool readPlaylists = false,
    bool readArtists = false,
    bool readUsers = false,
  }) async {
    try {
      final futures = <Future<QuerySnapshot>>[];

      if (readSongs) {
        Query<Map<String, dynamic>> query = _firestore.collection('songs');
        query = (name == null || name.isEmpty)
            ? query.orderBy('createdAt', descending: true).limit(5)
            : query
                  .where('name', isGreaterThanOrEqualTo: name)
                  .where('name', isLessThan: name + '\uf8ff')
                  .orderBy('name');

        futures.add(query.get());
      }

      if (readAlbums) {
        Query<Map<String, dynamic>> query = _firestore.collection('albums');
        query = (name == null || name.isEmpty)
            ? query.orderBy('createdAt', descending: true).limit(5)
            : query
                  .where('name', isGreaterThanOrEqualTo: name)
                  .where('name', isLessThan: name + '\uf8ff')
                  .orderBy('name');

        futures.add(query.get());
      }

      if (readPlaylists) {
        var query = _firestore
            .collection('playlists')
            .where('isPublic', isEqualTo: true);
        query = (name == null || name.isEmpty)
            ? query.orderBy('createdAt', descending: true).limit(5)
            : query
                  .where('name', isGreaterThanOrEqualTo: name)
                  .where('name', isLessThan: name + '\uf8ff')
                  .orderBy('name');
        futures.add(query.get());
      }

      if (readArtists) {
        Query<Map<String, dynamic>> query = _firestore.collection('artists');
        query = (name == null || name.isEmpty)
            ? query.orderBy('createdAt', descending: true).limit(5)
            : query
                  .where('name', isGreaterThanOrEqualTo: name)
                  .where('name', isLessThan: name + '\uf8ff')
                  .orderBy('name');
        futures.add(query.get());
      }

      if (readUsers) {
        Query<Map<String, dynamic>> query = _firestore.collection('users');
        query = (name == null || name.isEmpty)
            ? query.orderBy('createdAt', descending: true).limit(5)
            : query
                  .where('name', isGreaterThanOrEqualTo: name)
                  .where('name', isLessThan: name + '\uf8ff')
                  .orderBy('name');
        futures.add(query.get());
      }

      final results = await Future.wait(futures);

      final mixedList = <Map<String, dynamic>>[];

      Timestamp getDate(DocumentSnapshot doc) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data?['createdAt'] is Timestamp) {
          return (data!['createdAt'] as Timestamp);
        }
        return Timestamp.now();
      }

      for (var snap in results) {
        if (snap.docs.isEmpty) continue;
        for (var doc in snap.docs) {
          final data = doc.data() as Map<String, dynamic>;

          String parentId = doc.reference.parent.id;
          String type;
          switch (parentId) {
            case 'songs':
              type = 'song';
              break;
            case 'albums':
              type = 'album';
              break;
            case 'playlists':
              type = 'playlist';
              break;
            case 'artists':
              type = 'artist';
              break;
            case 'users':
              type = 'user';
              break;
            default:
              type = parentId;
          }

          mixedList.add({
            'id': doc.id,
            'type': type,
            'title': data['name'] ?? 'Sin título',
            'subtitle': type,
            'imageUrl': (type == 'user' || type == 'artist')
                ? data['photoURL']
                : data['coverURL'],
            'createdAt': getDate(doc),
          });
        }
      }

      mixedList.sort((a, b) => b['createdAt'].compareTo(a['createdAt']));
      return (name == null || name.isEmpty)
          ? mixedList.take(10).toList()
          : mixedList.toList();
    } catch (e, stackTrace) {
      log('ERROR CRÍTICO: $e', name: 'DEBUG_ERROR');
      log('STACK TRACE: $stackTrace', name: 'DEBUG_ERROR');
      return [];
    }
  }

  // Rebre novetats d'artistes seguits
  Future<List<Map<String, dynamic>>> getFollowedArtistsReleases() async {
    // Rebre novetats d'artistes seguits
    try {
      // Obtenir IDs d'artistes seguits
      final followingSnapshot = await _firestore
          .collection('users') // Col·lecció d'usuaris
          .doc(currentUserId) // Document de l'usuari actual
          .collection('followingArtists') // Col·lecció d'artistes seguits
          .get(); // Obtenir documents

      if (followingSnapshot.docs.isEmpty)
        return []; // Si no segueix a ningú, retorna llista buida

      // Llista d'IDs d'artistes seguits
      List<String> followedArtistIds = followingSnapshot.docs
          .map((doc) => doc.id) // Obtenir ID de cada document
          .toList(); // Convertir a llista

      // Limitar a 10
      List<String> targetIds = followedArtistIds.take(10).toList();

      if (targetIds.isEmpty) return []; // Si no hi ha IDs, retorna llista buida

      // Obtenir cançons dels artistes seguits
      final songsSnapshot = await _firestore
          .collection('songs') // Col·lecció de cançons
          .where('artistId', whereIn: targetIds) // Filtrar per artistes seguits
          .orderBy('createdAt', descending: true) // Ordenar per data de creació
          .limit(10) // Limitar a 10 resultats
          .get(); // Obtenir documents

      List<Map<String, dynamic>> releases =
          []; // Llista per emmagatzemar resultats

      for (var doc in songsSnapshot.docs) {
        // Iterar sobre documents
        releases.add({
          // Afegir informació de la cançó a la llista
          'id': doc.id, // ID de la cançó
          'type': 'song', // Tipus de contingut
          'title':
              doc['name'] ??
              'Sin título', // Nom de la cançó, o 'Sin título' si no existeix
          'subtitle': 'Del artista', // Subtítol
          'imageUrl': doc['coverURL'] ?? '', // URL de la imatge de portada
        });
      }

      return releases; // Retornar llista de novetats
    } catch (e) {
      print("Error trobant releases dels artistes: $e"); // Fetch d'errors
      return []; // Retornar llista buida en cas d'error
    }
  }

  static Future<User?> getUser(String userId) async {
    // Metode estàtic per obtenir un usuari per ID
    try {
      // Intentar obtenir l'usuari
      final doc = await FirebaseFirestore.instance
          .collection('users') // Col·lecció d'usuaris
          .doc(userId) // Document de l'usuari
          .get(); // Obtenir document

      if (!doc.exists) return null; // Si no existeix, retorna null

      final data = doc.data(); // Obtenir dades del document
      data!['id'] = doc.id; // Assignar ID del document a les dades

      User user = User.fromMap(data); // Crear instància d'usuari

      return user; // Retornar l'usuari
    } catch (e) {
      // Capturar errors
      throw Exception('Error obtenint usuari: $e'); //
    }
  }
}
