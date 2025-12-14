/*import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:projecte_pm/models/user/user.dart' as models; 
import 'package:projecte_pm/models/artist/artist.dart'; 

class UserDataService {
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtenir l'UID de l'usuari actual
  String get _currentUserId {
    final uid = FirebaseAuth.instance.currentUser?.uid; 
    if (uid == null) {
      throw Exception("Usuari no autenticat. UID no disponible.");
    }
    return uid;
  }

  Future<Map<String, dynamic>?> _getDocumentFromReference(
    DocumentReference ref,
  ) async {
    try {
      final doc = await ref.get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; 
        return data;
      }
      return null;
    } catch (e) {
      print("Error al recuperar referència ${ref.path}: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>> fetchUserOrArtistProfile() async {
    final uid = _currentUserId;

    // 1. Intentar llegir el perfil d'USUARI
    final userDoc = await _firestore.collection('users').doc(uid).get();
    if (userDoc.exists) {
      return {
        'isArtist': false,
        'profile': models.User.fromFirestore(userDoc), 
      };
    }

    // 2. Intentar llegir el perfil d'ARTISTA
    final artistDoc = await _firestore.collection('artists').doc(uid).get();
    if (artistDoc.exists) {
      return {
        'isArtist': true,
        'profile': Artist.fromFirestore(artistDoc), 
      };
    }
    return {};
  }

  Future<List<Map<String, dynamic>>> fetchOwnedPlaylists() async {
    final subCollectionPath = 'users/$_currentUserId/ownedPlaylists';
    final playlistRefsSnapshot = await _firestore
        .collection(subCollectionPath)
        .get();

    final List<Future<Map<String, dynamic>?>> playlistFutures = [];

    for (var doc in playlistRefsSnapshot.docs) {
      final refData = doc.data();
      final playlistRef = refData['playlistRef'] as DocumentReference?;

      if (playlistRef != null) {
        playlistFutures.add(
          _getDocumentFromReference(playlistRef).then((playlistData) {
            if (playlistData != null) {
              playlistData['ownedId'] = doc.id;
              playlistData['createdAt'] = refData['createdAt'];
              playlistData['type'] = 'playlist_owned';
            }
            return playlistData;
          }),
        );
      }
    }
    final results = await Future.wait(playlistFutures);
    return results.whereType<Map<String, dynamic>>().toList();
  }

  Future<List<Map<String, dynamic>>> fetchSavedPlaylists() async {
    final subCollectionPath = 'users/$_currentUserId/savedPlaylists';
    final savedRefsSnapshot = await _firestore
        .collection(subCollectionPath)
        .get();

    final List<Future<Map<String, dynamic>?>> playlistFutures = [];

    for (var doc in savedRefsSnapshot.docs) {
      final refData = doc.data();
      final playlistRef = refData['playlistRef'] as DocumentReference?;

      if (playlistRef != null) {
        playlistFutures.add(
          _getDocumentFromReference(playlistRef).then((playlistData) {
            if (playlistData != null) {
              playlistData['savedId'] = doc.id;
              playlistData['savedAt'] = refData['savedAt'];
              playlistData['type'] = 'playlist_saved'; 
            }
            return playlistData;
          }),
        );
      }
    }
    final results = await Future.wait(playlistFutures);
    return results.whereType<Map<String, dynamic>>().toList();
  }

  Future<List<Map<String, dynamic>>> fetchSavedAlbums() async {
    final subCollectionPath = 'users/$_currentUserId/savedAlbums';
    final savedRefsSnapshot = await _firestore
        .collection(subCollectionPath)
        .get();

    final List<Future<Map<String, dynamic>?>> albumFutures = [];

    for (var doc in savedRefsSnapshot.docs) {
      final refData = doc.data();
      final albumRef = refData['albumRef'] as DocumentReference?;

      if (albumRef != null) {
        albumFutures.add(
          _getDocumentFromReference(albumRef).then((albumData) {
            if (albumData != null) {
              albumData['savedId'] = doc.id;
              albumData['savedAt'] = refData['savedAt'];
              albumData['type'] = 'album_saved';
            }
            return albumData;
          }),
        );
      }
    }
    final results = await Future.wait(albumFutures);
    return results.whereType<Map<String, dynamic>>().toList();
  }

  Future<List<Map<String, dynamic>>> fetchPlayHistory({int limit = 50}) async {
    final subCollectionPath = 'users/$_currentUserId/playHistory';
    final historySnapshot = await _firestore
        .collection(subCollectionPath)
        .orderBy('playedAt', descending: true)
        .limit(limit)
        .get();

    final List<Future<Map<String, dynamic>?>> historyFutures = [];

    for (var doc in historySnapshot.docs) {
      final historyData = doc.data();
      final songRef = historyData['songId'] as DocumentReference?;

      if (songRef != null) {
        historyFutures.add(
          _getDocumentFromReference(songRef).then((songData) {
            if (songData != null) {
              historyData['songDetails'] = songData;
              historyData['historyId'] = doc.id;
              return historyData;
            }
            return null;
          }),
        );
      }
    }
    final results = await Future.wait(historyFutures);
    return results.whereType<Map<String, dynamic>>().toList();
  }

  Future<List<Map<String, dynamic>>> fetchArtistSongs() async {
    final artistRef = _firestore.collection('artists').doc(_currentUserId);
    final songsSnapshot = await _firestore
        .collection('songs')
        .where('artistId', isEqualTo: artistRef)
        .get();

    return songsSnapshot.docs
        .map((doc) => doc.data()..['id'] = doc.id)
        .toList();
  }

  Future<List<Map<String, dynamic>>> fetchArtistAlbums() async {
    final artistRef = _firestore.collection('artists').doc(_currentUserId);
    final albumsSnapshot = await _firestore
        .collection('albums')
        .where('artistId', isEqualTo: artistRef)
        .get();

    return albumsSnapshot.docs
        .map((doc) => doc.data()..['id'] = doc.id)
        .toList();
  }
  

  Future<Map<String, dynamic>> loadLandingPageData() async {
      
      final profileResult = await fetchUserOrArtistProfile();
      
      if (profileResult.isEmpty) {
          final currentUser = FirebaseAuth.instance.currentUser;
          return {
            'profileFound': false, 
            'userName': currentUser?.displayName ?? currentUser?.email?.split('@').first ?? 'Usuari',
          };
      }
      
      final isArtist = profileResult['isArtist'] as bool;
      final profile = profileResult['profile'];
      
      if (isArtist) {
          final artist = profile as Artist;
          
          final artistAlbums = await fetchArtistAlbums(); 
          final artistSongs = await fetchArtistSongs(); 

          return {
              'profileFound': true,
              'isArtist': true,
              'profile': artist,
              'userName': artist.name,
              'artistAlbums': artistAlbums,
              'artistSongs': artistSongs,
          };
      }
      
      // Perfil d'usuari estàndard
      final user = profile as models.User; 
      
      final results = await Future.wait([
        fetchOwnedPlaylists(),
        fetchSavedPlaylists(),
        fetchSavedAlbums(),
        fetchPlayHistory(),
      ]);
      
      final ownedPlaylists = results[0];
      final savedPlaylists = results[1];
      final savedAlbums = results[2];
      final history = results[3];
      
      final combinedList = [
        ...ownedPlaylists,
        ...savedPlaylists,
        ...savedAlbums,
      ];

      return {
          'profileFound': true,
          'isArtist': false,
          'profile': user,
          'userName': user.name,
          'savedContent': combinedList,
          'history': history,
      };
  }
}*/