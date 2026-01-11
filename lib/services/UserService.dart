import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projecte_pm/models/user.dart';
import 'package:projecte_pm/services/ArtistService.dart'; // Importa el servei d'artista per seguir artistes
import 'package:projecte_pm/services/AlbumService.dart'; // Importa el servei d'àlbum per seguir àlbums
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

  Future<void> updateUser({String? name, String? photoURL, String? bio}) async {
    if (_currentUserRef == null) return;

    try {
      final updateData = <String, dynamic>{};

      if (name != null) updateData['name'] = name;
      if (photoURL != null) updateData['photoURL'] = photoURL;
      if (bio != null) updateData['bio'] = bio;

      if (updateData.isNotEmpty) {
        await _currentUserRef!.update(updateData);

        if (name != null) _user.name = name;
        if (photoURL != null) _user.photoURL = photoURL;
        if (bio != null) _user.bio = bio;
      }
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
    String? currentUserId,
  }) async {
    try {
      final futures = <Future<QuerySnapshot>>[];
      final albumCache = <String, bool>{};

      if (readSongs) {
        final songQuery = _firestore
            .collection('songs')
            .where('isPublic', isEqualTo: true)
            .limit(20);

        futures.add(songQuery.get());
      }

      if (readAlbums) {
        final albumQuery = _firestore
            .collection('albums')
            .where('isPublic', isEqualTo: true)
            .limit(10);

        futures.add(albumQuery.get());
      }

      if (readPlaylists) {
        final playlistQuery = _firestore
            .collection('playlists')
            .where('isPublic', isEqualTo: true)
            .limit(10);

        futures.add(playlistQuery.get());
      }

      if (readArtists) {
        final artistQuery = _firestore.collection('artists').limit(5);
        futures.add(artistQuery.get());
      }

      if (readUsers) {
        final userQuery = _firestore.collection('users').limit(5);
        futures.add(userQuery.get());
      }

      final results = await Future.wait(futures);
      final mixedList = <Map<String, dynamic>>[];

      for (var snap in results) {
        if (snap.docs.isEmpty) continue;

        final type = snap.docs.first.reference.parent.id;

        for (var doc in snap.docs) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) continue;

          if (type == 'songs') {
            try {
              final albumId = data['albumId'];
              if (albumId is String && albumId.isNotEmpty) {
                if (!albumCache.containsKey(albumId)) {
                  final albumDoc = await _firestore
                      .collection('albums')
                      .doc(albumId)
                      .get();

                  albumCache[albumId] = albumDoc.exists
                      ? (albumDoc.data()?['isPublic'] ?? false)
                      : false;
                }

                // Saltar canció si el álbum es privat
                if (albumCache[albumId] == false) continue;
              }
            } catch (e) {
              continue; // En cas d'error
            }
          }

          final uiType = switch (type) {
            'songs' => 'song',
            'albums' => 'album',
            'playlists' => 'playlist',
            'artists' => 'artist',
            'users' => 'user',
            _ => type,
          };

          String? artistName;
          if (uiType == 'song') {
            try {
              final artistRef = data['artistId'];
              if (artistRef is DocumentReference) {
                final artistDoc = await artistRef.get();
                if (artistDoc.exists) {
                  artistName = artistDoc['name'];
                }
              } else if (artistRef is String) {
                final artistDoc = await _firestore
                    .collection('artists')
                    .doc(artistRef)
                    .get();
                if (artistDoc.exists) {
                  artistName = artistDoc['name'];
                }
              }
            } catch (e) {
              // Si no se puede obtindre artista, continuar
            }
          }

          mixedList.add({
            'id': doc.id,
            'type': uiType,
            'title': data['name'] ?? 'Sin título',
            'subtitle': artistName ?? uiType,
            'imageUrl': _getImageUrl(uiType, data),
            'createdAt': (data['createdAt'] as Timestamp?) ?? Timestamp.now(),
            'ispublic': uiType == 'playlist' ? data['isPublic'] ?? false : null,
            'duration': uiType == 'song' ? data['duration'] : null,
          });
        }
      }

      // Sort per dada de publicació
      mixedList.sort((a, b) => b['createdAt'].compareTo(a['createdAt']));

      // Limitar a 10 resultats
      return mixedList.take(10).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> searchContent({
    required String query,
    bool includeSongs = true,
    bool includeAlbums = true,
    bool includePlaylists = true,
    bool includeArtists = true,
    bool includeUsers = true,
    int limit = 100,
  }) async {
    try {
      final futures = <Future<QuerySnapshot>>[];
      final albumCache = <String, bool>{};

      if (query.isNotEmpty) {
        if (includeSongs) {
          futures.add(
            _firestore
                .collection('songs')
                .where('isPublic', isEqualTo: true)
                .limit(limit)
                .get(),
          );
        }

        if (includeAlbums) {
          futures.add(
            _firestore
                .collection('albums')
                .where('isPublic', isEqualTo: true)
                .limit(limit)
                .get(),
          );
        }

        if (includePlaylists) {
          futures.add(
            _firestore
                .collection('playlists')
                .where('isPublic', isEqualTo: true)
                .limit(limit)
                .get(),
          );
        }

        if (includeArtists) {
          futures.add(_firestore.collection('artists').limit(limit).get());
        }

        if (includeUsers) {
          futures.add(_firestore.collection('users').limit(limit).get());
        }
      } else {
        if (includeSongs) {
          futures.add(
            _firestore
                .collection('songs')
                .where('isPublic', isEqualTo: true)
                .limit(limit)
                .get(),
          );
        }

        if (includeAlbums) {
          futures.add(
            _firestore
                .collection('albums')
                .where('isPublic', isEqualTo: true)
                .limit(limit)
                .get(),
          );
        }

        if (includePlaylists) {
          futures.add(
            _firestore
                .collection('playlists')
                .where('isPublic', isEqualTo: true)
                .limit(limit)
                .get(),
          );
        }

        if (includeArtists) {
          futures.add(_firestore.collection('artists').limit(limit).get());
        }

        if (includeUsers) {
          futures.add(_firestore.collection('users').limit(limit).get());
        }
      }

      final results = await Future.wait(futures);
      final mixedList = <Map<String, dynamic>>[];

      for (var snap in results) {
        final type = snap.docs.isNotEmpty
            ? snap.docs.first.reference.parent.id
            : 'unknown';

        for (var doc in snap.docs) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) continue;

          if (type == 'songs') {
            try {
              final albumId = data['albumId'];
              if (albumId is String && albumId.isNotEmpty) {
                if (!albumCache.containsKey(albumId)) {
                  final albumDoc = await _firestore
                      .collection('albums')
                      .doc(albumId)
                      .get();

                  final albumData = albumDoc.data() as Map<String, dynamic>?;
                  albumCache[albumId] = albumDoc.exists
                      ? (albumData?['isPublic'] ?? false)
                      : false;
                }

                if (albumCache[albumId] == false) continue;
              }
            } catch (e) {
              continue;
            }
          }

          final uiType = switch (type) {
            'songs' => 'song',
            'albums' => 'album',
            'playlists' => 'playlist',
            'artists' => 'artist',
            'users' => 'user',
            _ => type,
          };

          String? artistName;
          if (uiType == 'song') {
            try {
              final artistRef = data['artistId'];
              if (artistRef is DocumentReference) {
                final artistDoc = await artistRef.get();
                final artistData = artistDoc.data() as Map<String, dynamic>?;
                if (artistData != null) {
                  artistName = artistData['name'];
                }
              } else if (artistRef is String && artistRef.isNotEmpty) {
                final artistDoc = await _firestore
                    .collection('artists')
                    .doc(artistRef)
                    .get();
                final artistData = artistDoc.data() as Map<String, dynamic>?;
                if (artistData != null) {
                  artistName = artistData['name'];
                }
              }
            } catch (e) {}
          }

          final itemName = data['name'] ?? 'Sin título';

          if (query.isNotEmpty &&
              !itemName.toLowerCase().contains(query.toLowerCase())) {
            continue;
          }

          mixedList.add({
            'id': doc.id,
            'type': uiType,
            'title': itemName,
            'subtitle': artistName ?? uiType,
            'imageUrl': _getImageUrl(uiType, data),
            'createdAt': (data['createdAt'] as Timestamp?) ?? Timestamp.now(),
            'ispublic': uiType == 'playlist' ? data['isPublic'] ?? false : null,
            'duration': uiType == 'song' ? data['duration'] : null,
          });
        }
      }

      // ORDENAR RESULTADOS
      if (query.isNotEmpty) {
        // Para búsquedas: primero los que empiezan con la query, luego los que contienen
        mixedList.sort((a, b) {
          final aTitle = (a['title'] as String).toLowerCase();
          final bTitle = (b['title'] as String).toLowerCase();
          final queryLower = query.toLowerCase();

          final aStartsWith = aTitle.startsWith(queryLower);
          final bStartsWith = bTitle.startsWith(queryLower);

          if (aStartsWith && !bStartsWith) return -1;
          if (!aStartsWith && bStartsWith) return 1;
          return aTitle.compareTo(bTitle);
        });
      } else {
        // Para contenido general: ordenar por fecha
        mixedList.sort((a, b) => b['createdAt'].compareTo(a['createdAt']));
      }

      return mixedList.take(limit).toList();
    } catch (e) {
      print("Error en searchContent: $e");
      return [];
    }
  }

  String _getImageUrl(String type, Map<String, dynamic> data) {
    switch (type) {
      case 'user':
      case 'artist':
        return data['photoURL'] ?? '';
      case 'song':
      case 'album':
      case 'playlist':
        return data['coverURL'] ?? '';
      default:
        return '';
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

  // Obtener estadísticas completas del usuario actual
  Future<Map<String, dynamic>> getUserStats() async {
    // Obtindo estadístiques d'usuari
    if (_currentUserRef == null)
      return {}; // Si no hi ha usuari actual, retorna mapa buit

    try {
      // Intentar obtenir estadístiques
      final ownedPlaylists =
          await _currentUserRef! // Obtenir playlists propietat de l'usuari
              .collection('ownedPlaylists') // Col·lecció de playlists propietat
              .get(); // Obtenir documents
      final savedPlaylists =
          await _currentUserRef! // Obtenir playlists guardades per l'usuari
              .collection('savedPlaylists') // Col·lecció de playlists guardades
              .get(); // Obtenir documents
      final savedAlbums =
          await _currentUserRef! // Obtenir àlbums guardats per l'usuari
              .collection('savedAlbums') // Col·lecció d'àlbums guardats
              .get(); // Obtenir documents
      final playHistory =
          await _currentUserRef! // Obtenir historial de reproducció de l'usuari
              .collection(
                'playHistory',
              ) // Col·lecció d'historial de reproducció
              .get(); // Obtenir documents

      int totalListeningTime = 0; // Inicialitzar temps total d'escolta
      DateTime? lastActive; // Inicialitzar última activitat

      for (final doc in playHistory.docs) {
        // Iterar sobre documents d'historial
        final data =
            doc.data() as Map<String, dynamic>; // Obtenir dades del document
        totalListeningTime +=
            (data['playDuration'] as int? ?? 0); // Sumar duració de reproducció

        final playedAt = (data['playedAt'] as Timestamp?)
            ?.toDate(); // Obtenir data de reproducció
        if (playedAt != null && // Comprovar si és la última activitat
            (lastActive == null || playedAt.isAfter(lastActive))) {
          // Comparar dates
          lastActive = playedAt; // Actualitzar última activitat
        }
      }

      final userData = _user.toMap(); // Obtenir dades de l'usuari
      final stats =
          userData['stats'] as Map<String, dynamic>? ??
          {}; // Obtenir estadístiques

      return {
        // Retornar mapa d'estadístiques
        'followers': _user.followerCount(), // Comptar seguidors
        'following': _user.followingCount(), // Comptar seguidors
        'ownedPlaylistsCount':
            ownedPlaylists.docs.length, // Comptar playlists propietat
        'savedPlaylistsCount':
            savedPlaylists.docs.length, // Comptar playlists guardades
        'savedAlbumsCount': savedAlbums.docs.length, // Comptar àlbums guardats
        'totalListeningTime': totalListeningTime, // Temps total d'escolta
        'lastActive': lastActive, // Última activitat
        'playHistoryCount':
            playHistory.docs.length, // Comptar entrades d'historial
      };
    } catch (e) {
      // Capturar errors
      print("Error obtenint estadistiques de usuari: $e"); // Print d'error
      return {}; // Retornar mapa buit en cas d'error
    }
  }

  Future<List<Map<String, dynamic>>> getTopArtists({int limit = 5}) async {
    // Obtindre artistes més escoltats
    if (_currentUserRef == null)
      return []; // Si no hi ha usuari actual, retorna llista buida

    try {
      // Intentar obtenir artistes
      final playHistory =
          await _currentUserRef! // Obtenir historial de reproducció
              .collection(
                'playHistory',
              ) // Col·lecció d'historial de reproducció
              .orderBy(
                'playedAt',
                descending: true,
              ) // Ordenar per data de reproducció
              .limit(100) // Limitar a 100 entrades
              .get(); // Obtenir documents

      final artistCount = <String, int>{}; // Mapa per comptar artistes

      for (final doc in playHistory.docs) {
        // Iterar sobre documents d'historial
        final data =
            doc.data() as Map<String, dynamic>; // Obtenir dades del document
        final songRef =
            data['songId']
                as DocumentReference?; // Obtenir referència de la cançó

        if (songRef != null) {
          // Si la referència de la cançó no és nul·la
          final songDoc = await songRef.get(); // Obtenir document de la cançó
          if (songDoc.exists) {
            // Si el document de la cançó existeix
            final songData =
                songDoc.data()
                    as Map<String, dynamic>; // Obtenir dades de la cançó
            final artistRef =
                songData['artistId']
                    as DocumentReference?; // Obtenir referència de l'artista

            if (artistRef != null) {
              // Si la referència de l'artista no és nul·la
              final artistId = artistRef.id; // Obtenir ID de l'artista
              artistCount[artistId] =
                  (artistCount[artistId] ?? 0) + 1; // Comptar escoltes
            }
          }
        }
      }

      final topArtists =
          <
            Map<String, dynamic>
          >[]; // Llista per emmagatzemar artistes més escoltats
      final sortedArtists =
          artistCount.entries
              .toList() // Convertir a llista d'entrades
            ..sort(
              (a, b) => b.value.compareTo(a.value),
            ); // Ordenar per nombre d'escoltes

      for (final entry in sortedArtists.take(limit)) {
        // Iterar sobre els artistes més escoltats
        final artist = await ArtistService.getArtist(
          entry.key,
        ); // Obtenir informació de l'artista
        if (artist != null) {
          // Si l'artista existeix
          topArtists.add({
            // Afegir informació de l'artista a la llista
            'id': artist.id, // ID de l'artista
            'name': artist.name, // Nom de l'artista
            'photoURL': artist.photoURL, // URL de la foto de l'artista
            'playCount': entry.value, // Nombre d'escoltes
          });
        }
      }

      return topArtists; // Retornar llista d'artistes més escoltats
    } catch (e) {
      // Capturar errors
      print("Error obtenint top artistas: $e"); // Print d'error
      return []; // Retornar llista buida en cas d'error
    }
  }

  Future<List<Map<String, dynamic>>> getTopAlbums({int limit = 5}) async {
    // Obtindre àlbums més escoltats
    if (_currentUserRef == null)
      return []; // Si no hi ha usuari actual, retorna llista buida

    try {
      // Intentar obtenir àlbums
      final playHistory =
          await _currentUserRef! // Obtenir historial de reproducció
              .collection(
                'playHistory',
              ) // Col·lecció d'historial de reproducció
              .orderBy(
                'playedAt',
                descending: true,
              ) // Ordenar per data de reproducció
              .limit(100) // Limitar a 100 entrades
              .get(); // Obtenir documents

      final albumCount = <String, int>{}; // Mapa per comptar àlbums

      for (final doc in playHistory.docs) {
        // Iterar sobre documents d'historial
        final data =
            doc.data() as Map<String, dynamic>; // Obtenir dades del document
        final songRef =
            data['songId']
                as DocumentReference?; // Obtenir referència de la cançó

        if (songRef != null) {
          // Si la referència de la cançó no és nul·la
          final songDoc = await songRef.get(); // Obtenir document de la cançó
          if (songDoc.exists) {
            // Si el document de la cançó existeix
            final songData =
                songDoc.data()
                    as Map<String, dynamic>; // Obtenir dades de la cançó
            final albumRef =
                songData['albumId']
                    as DocumentReference?; // Obtenir referència de l'àlbum

            if (albumRef != null) {
              // Si la referència de l'àlbum no és nul·la
              final albumId = albumRef.id; // Obtenir ID de l'àlbum
              albumCount[albumId] =
                  (albumCount[albumId] ?? 0) + 1; // Comptar escoltes
            }
          }
        }
      }

      final topAlbums =
          <
            Map<String, dynamic>
          >[]; // Llista per emmagatzemar àlbums més escoltats
      final sortedAlbums =
          albumCount.entries
              .toList() // Convertir a llista d'entrades
            ..sort(
              (a, b) => b.value.compareTo(a.value),
            ); // Ordenar per nombre d'escoltes

      for (final entry in sortedAlbums.take(limit)) {
        // Iterar sobre els àlbums més escoltats
        final album = await AlbumService.getAlbum(
          entry.key,
        ); // Obtenir informació de l'àlbum
        if (album != null) {
          // Si l'àlbum existeix
          topAlbums.add({
            // Afegir informació de l'àlbum a la llista
            'id': album.id, // ID de l'àlbum
            'title': album.name, // Nom de l'àlbum
            'coverURL': album.coverURL, // URL de la portada de l'àlbum
            'artistId': album.artistId, // ID de l'artista
            'playCount': entry.value, // Nombre d'escoltes
          });
        }
      }

      return topAlbums; // Retornar llista d'àlbums més escoltats
    } catch (e) {
      // Capturar errors
      print("Error obtenint top álbumes: $e");
      return [];
    }
  }

  static Future<UserService> createForArtist({required String artistId}) async {
    final firestore = FirebaseFirestore.instance;

    final artistRef = firestore.collection('artists').doc(artistId);
    final artistSnap = await artistRef.get();

    if (!artistSnap.exists) {
      throw Exception('Artista no trobat');
    }

    final artistData = artistSnap.data() as Map<String, dynamic>;

    // Crear un mockup de usuari per artista. No em pregunteu com va aixo perque es magia negra. Sino no et deixa tirar els editors de albums (VICTOR)
    final user = User(
      id: artistId,
      name: artistData['name'] ?? 'Artista',
      email: artistData['email'] ?? '${artistId}@artist.com',
      photoURL: artistData['photoURL'] ?? '',
      bio: artistData['bio'] ?? '',
      createdAt:
          (artistData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      follower: [],
      following: [],
      ownedPlaylist: [],
      savedPlaylist: [],
      savedAlbum: [],
      playHistory: [],
    );

    return UserService._(
      firestore: firestore,
      currentUserRef: artistRef,
      user: user,
    );
  }
}
