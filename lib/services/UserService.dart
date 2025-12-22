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
  Future<User?> getCurrentUser() async {
    if (_currentUserRef == null) return null;
    final snap = await _currentUserRef!.get();
    if (!snap.exists) return null;
    log('Dades usuari rebudes: ${snap.data()}', name: 'FIREBASE_LOG');
    return User.fromMap(snap.data() as Map<String, dynamic>);
  }

  Future<void> refreshUser() async {
    final snap = await _currentUserRef!.get();
    _user = User.fromMap(snap.data() as Map<String, dynamic>);
  }

  Future<void> updateUser(User user) async {
    if (_currentUserRef == null) return;
    try {
      // Actualitzem només els camps necessaris (excepte ID i email que solen ser fixos)
      await _currentUserRef!.update(user.toMap());
    } catch (e) {
      print("Error actualitzant usuari: $e");
      rethrow; // Llancem l'error perquè la UI sàpiga que ha fallat
    }
  }

  // Altres Mètodes
  Future<void> followUser(String targetUserId) async {
    if (_currentUserRef == targetUserId) return;

    final batch = _firestore.batch();

    final myFollowingRef = _currentUserRef!
        .collection('following')
        .doc(targetUserId);

    final targetUserRef = _firestore
        .collection('users')
        .doc(targetUserId)
        .collection('followers')
        .doc(_user.id);

    final relation = SaveId(id: targetUserId);

    batch.set(myFollowingRef, relation.toMap());
    batch.set(targetUserRef, relation.toMap());

    await batch.commit();
  }

  Future<void> unfollowUser(String targetUserId) async {
    if (_currentUserRef == targetUserId || _currentUserRef == null) return;

    final batch = _firestore.batch();

    batch.delete(_currentUserRef!.collection('following').doc(targetUserId));
    batch.delete(
      _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('followers')
          .doc(_user.id),
    );

    await batch.commit();
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

      // 1. SONGS
      // log('2. Llançant consulta Songs...', name: 'DEBUG_FIREBASE');
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

      // 2. ALBUMS
      // log('3. Llançant consulta Albums...', name: 'DEBUG_FIREBASE');
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

      // 3. PLAYLISTS (Aquesta sol fallar per l'índex)
      //log('4. Llançant consulta Playlists...', name: 'DEBUG_FIREBASE');
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

      // 4. ARTISTS
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

      // 5. USERS
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

      /* log(
        '5. Resultats rebuts. Songs: ${results[0].size}, Albums: ${results[1].size}, Playlists: {results[2].size}',
        name: 'DEBUG_FIREBASE',
      );*/

      final mixedList = <Map<String, dynamic>>[];

      // Funció auxiliar per llegir dates de forma segura
      Timestamp getDate(DocumentSnapshot doc) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data?['createdAt'] is Timestamp) {
          return (data!['createdAt'] as Timestamp);
        }
        return Timestamp.now(); // fallback seguro
      }

      for (var snap in results) {
        if (snap.docs.isEmpty) continue;
        for (var doc in snap.docs) {
          final data = doc.data() as Map<String, dynamic>;

          // Normalizamos el tipo: quitamos la 's' final
          String parentId =
              doc.reference.parent.id; // 'songs', 'albums', 'playlists'
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

  // Novetats artistes que segueixo
  Future<List<Map<String, dynamic>>> getFollowedArtistsReleases() async {
    try {
      // Pas 1: Obtenir la llista d'artistes que l'usuari segueix
      final followingSnapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('following')
          .get();

      if (followingSnapshot.docs.isEmpty) return [];

      // Obtenir la llista d'IDs
      List<String> followedArtistIds = followingSnapshot.docs
          .map((doc) => doc.id)
          .toList();

      List<String> targetIds = followedArtistIds.take(10).toList();

      // Pas 2: Buscar cançons d'aquests artistes
      List<DocumentReference> artistRefs = targetIds
          .map((id) => _firestore.collection('artists').doc(id))
          .toList();

      final songsSnapshot = await _firestore
          .collection('songs')
          .where('artistId', whereIn: artistRefs)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      List<Map<String, dynamic>> releases = [];

      for (var doc in songsSnapshot.docs) {
        releases.add({
          'id': doc.id,
          'type': 'song',
          'title': doc['title'],
          'subtitle': doc['artistName'],
          'imageUrl': doc['coverURL'],
        });
      }

      return releases;
    } catch (e) {
      print("Error fetching followed artists releases: $e");
      return [];
    }
  }
}
