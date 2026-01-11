import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projecte_pm/models/artist.dart';
import 'package:projecte_pm/models/song.dart';
import 'dart:developer';

class ArtistService {
  final FirebaseFirestore _firestore;
  final DocumentReference? _currentArtistRef;
  Artist _artist;
  final String? _currentUserId;

  ArtistService._({
    required FirebaseFirestore firestore,
    required DocumentReference currentArtistRef,
    required Artist artist,
    String? currentUserId,
  }) : _firestore = firestore,
       _currentArtistRef = currentArtistRef,
       _artist = artist,
       _currentUserId = currentUserId;

  static Future<ArtistService> create({
    required String artistId,
    String? currentUserId,
  }) async {
    final firestore = FirebaseFirestore.instance;
    final ref = firestore.collection('artists').doc(artistId);

    final snap = await ref.get();
    if (!snap.exists) {
      throw Exception('Artist no trobat');
    }

    final artist = Artist.fromMap(snap.data() as Map<String, dynamic>);

    return ArtistService._(
      firestore: firestore,
      currentArtistRef: ref,
      artist: artist,
      currentUserId: currentUserId,
    );
  }

  String? getCurrentUserId() => _currentUserId;
  String? get currentArtistId => _artist.id;
  DocumentReference? get currentArtistRef => _currentArtistRef;

  // Getters de artist
  Artist get artist => _artist;
  String get artistId => _artist.id;

  // Metòdes CRUD
  Future<Artist?> getCurrentArtist() async {
    if (_currentArtistRef == null) return null;
    final snap = await _currentArtistRef!.get();
    if (!snap.exists) return null;
    log('Dades artist rebudes: ${snap.data()}', name: 'FIREBASE_LOG');
    return Artist.fromMap(snap.data() as Map<String, dynamic>);
  }

  Future<void> refreshArtist() async {
    final snap = await _currentArtistRef!.get();
    _artist = Artist.fromMap(snap.data() as Map<String, dynamic>);
  }

  Future<void> updateArtist(Artist artist) async {
    if (_currentArtistRef == null) return;
    try {
      await _currentArtistRef!.update(artist.toMap());
    } catch (e) {
      print("Error actualitzant usuari: $e");
      rethrow;
    }
  }

  static Future<Artist?> getArtist(String artistId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('artists')
          .doc(artistId)
          .get();

      if (!doc.exists) return null;

      final data = doc.data();
      data!['id'] = doc.id;

      Artist artist = Artist.fromMap(data);

      return artist;
    } catch (e) {
      throw Exception('Error obtenint artist: $e');
    }
  }

  // Funció auxiliar per formatejar el temps
  String _formatListeningTime(int seconds) {
    if (seconds <= 0) return '0 minuts';

    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;

    if (hours > 0) {
      if (minutes > 0) {
        return '${hours}h ${minutes}m';
      } else {
        return '${hours}h';
      }
    } else if (minutes > 0) {
      if (remainingSeconds > 0) {
        return '${minutes}m ${remainingSeconds}s';
      } else {
        return '${minutes} minuts';
      }
    } else {
      return '${seconds} segons';
    }
  }

  Future<Map<String, dynamic>> getArtistStats() async {
    try {
      // Obtenir estadístiques bàsiques
      final totalLikes = await _getTotalLikes();
      final totalSongPlays = await _getTotalSongPlays();

      return {
        // Estadístiques principals
        'totalPlays': totalSongPlays, // Reproduccions totals
        'totalLikes': totalLikes, // Likes totals ← AQUEST ÉS EL QUE VOLS
        'songCount': _artist.songCount(),
        'albumCount': _artist.albumCount(),

        // Temps d'escolta (si el tens implementat)
        'totalListeningTime': _artist.totalListeningTime,
        'formattedListeningTime': _formatListeningTime(
          _artist.totalListeningTime,
        ),
      };
    } catch (e) {
      print("Error obtenint estadístiques d'artista: $e");
      return _getDefaultStats();
    }
  }

  // Mètode auxiliar per obtenir reproduccions totals
  Future<int> _getTotalSongPlays() async {
    try {
      final songs = await _firestore
          .collection('songs')
          .where('artistId', isEqualTo: _artist.id)
          .get();

      int totalPlays = 0;
      for (final songDoc in songs.docs) {
        final songData = songDoc.data() as Map<String, dynamic>;
        totalPlays += (songData['playCount'] as int? ?? 0);
      }
      return totalPlays;
    } catch (e) {
      print("Error obtenint reproduccions totals: $e");
      return 0;
    }
  }

  // Mètode auxiliar per obtenir likes totals
  Future<int> _getTotalLikes() async {
    try {
      // Obtenir totes les cançons de l'artista
      final songsSnapshot = await _firestore
          .collection('songs')
          .where('artistId', isEqualTo: _artist.id)
          .get();

      int totalLikes = 0;

      for (final songDoc in songsSnapshot.docs) {
        final songData = songDoc.data() as Map<String, dynamic>;

        // Sumar la llista de likes d'aquesta cançó
        final likesList = songData['likes'] as List<dynamic>? ?? [];
        totalLikes += likesList.length;
      }

      print("DEBUG - Likes totals calculats: $totalLikes");
      return totalLikes;
    } catch (e) {
      print("Error obtenint likes totals: $e");
      return 0;
    }
  }

  // Estadístiques per defecte
  Map<String, dynamic> _getDefaultStats() {
    return {
      'totalPlays': 0,
      'totalLikes': 0,
      'songCount': 0,
      'albumCount': 0,
      'totalListeningTime': 0,
      'formattedListeningTime': '0 minuts',
    };
  }

  // Mètodes auxiliars (opcionals, si els necessites)
  Future<int> _getMonthlyListeners() async {
    try {
      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);

      final monthlyListening = await _firestore
          .collectionGroup('artistListeningTime')
          .where('artistId', isEqualTo: _artist.id)
          .where(
            'lastListened',
            isGreaterThanOrEqualTo: Timestamp.fromDate(firstDayOfMonth),
          )
          .get();

      return monthlyListening.docs.length;
    } catch (e) {
      return 0;
    }
  }

  Future<int> _getWeeklyListeners() async {
    try {
      final now = DateTime.now();
      final firstDayOfWeek = now.subtract(Duration(days: now.weekday - 1));

      final weeklyListening = await _firestore
          .collectionGroup('artistListeningTime')
          .where('artistId', isEqualTo: _artist.id)
          .where(
            'lastListened',
            isGreaterThanOrEqualTo: Timestamp.fromDate(firstDayOfWeek),
          )
          .get();

      return weeklyListening.docs.length;
    } catch (e) {
      return 0;
    }
  }

  Future<int> _getUniqueListeners() async {
    try {
      final allListeners = await _firestore
          .collectionGroup('artistListeningTime')
          .where('artistId', isEqualTo: _artist.id)
          .get();

      return allListeners.docs.length;
    } catch (e) {
      return 0;
    }
  }

  // Funció per obtenir estadístiques detallades per període (opcional)
  Future<Map<String, dynamic>> getArtistTimeStats({
    String? period = 'month',
  }) async {
    try {
      final now = DateTime.now();
      DateTime startDate;

      switch (period) {
        case 'day':
          startDate = DateTime(now.year, now.month, now.day);
          break;
        case 'week':
          startDate = now.subtract(Duration(days: now.weekday - 1));
          break;
        case 'year':
          startDate = DateTime(now.year, 1, 1);
          break;
        case 'month':
        default:
          startDate = DateTime(now.year, now.month, 1);
          break;
      }

      final periodStats = await _firestore
          .collectionGroup('artistListeningTime')
          .where('artistId', isEqualTo: _artist.id)
          .where(
            'lastListened',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .get();

      int periodTime = 0;
      final userContributions = <String, int>{};

      for (final doc in periodStats.docs) {
        final data = doc.data();
        final seconds = data['totalSeconds'] as int? ?? 0;
        periodTime += seconds;

        // Obtenir ID d'usuari del path del document
        final pathParts = doc.reference.path.split('/');
        if (pathParts.length >= 2) {
          final userId = pathParts[1];
          userContributions[userId] =
              (userContributions[userId] ?? 0) + seconds;
        }
      }

      return {
        'period': period,
        'totalTime': periodTime,
        'formattedTime': _formatListeningTime(periodTime),
        'listenerCount': periodStats.docs.length,
        'userContributions': userContributions,
      };
    } catch (e) {
      print("Error obtenint estadístiques de temps per període: $e");
      return {};
    }
  }

  // Mètode per incrementar el temps d'escolta de l'artista (per PlayerService)
  Future<void> incrementArtistListeningTime(int seconds) async {
    if (_currentArtistRef == null) return;

    try {
      await _currentArtistRef!.update({
        'totalListeningTime': FieldValue.increment(seconds),
        'lastListened': FieldValue.serverTimestamp(),
      });

      print("Temps incrementat per artista ${_artist.id}: $seconds segons");
    } catch (e) {
      print("Error incrementant temps d'artista: $e");
    }
  }

  // Obtindre les cancons més populars de l'artista
  Future<List<Map<String, dynamic>>> getTopSongs({int limit = 10}) async {
    if (_currentArtistRef == null) return [];

    try {
      final songs = await _firestore
          .collection('songs')
          .where('artistId', isEqualTo: _artist.id)
          .orderBy('playCount', descending: true)
          .limit(limit)
          .get();

      return songs.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final likesList = data['likes'] as List<dynamic>? ?? [];

        return {
          'id': doc.id,
          'title': data['name'] ?? 'Sense Titol',
          'playCount': data['playCount'] ?? 0,
          'likes': likesList.length,
          'duration': data['duration'] ?? 0,
          'coverURL': data['coverURL'] ?? '',
        };
      }).toList();
    } catch (e) {
      print("Error obtenint top de cançons: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getArtistAlbums() async {
    if (_currentArtistRef == null) return [];

    try {
      final albums = await _firestore
          .collection('albums')
          .where('artistId', isEqualTo: _artist.id)
          .orderBy('createdAt', descending: true)
          .get();

      return albums.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final albumSongs = data['albumSong'] as List<dynamic>? ?? [];

        return {
          'id': doc.id,
          'title': data['name'] ?? 'Sense Titol',
          'coverURL': data['coverURL'] ?? '',
          'type': data['type'] ?? 'album',
          'playCount': data['playCount'] ?? 0,
          'saves': data['saves'] ?? 0,
          'totalTracks': albumSongs.length,
          'isPublic': data['isPublic'] ?? true,
        };
      }).toList();
    } catch (e) {
      print("Error obtenint albums del artista: $e");
      return [];
    }
  }

  Future<void> saveAlbum({
    required String userId,
    required String albumId,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'savedAlbum': FieldValue.arrayUnion([
          {'id': albumId},
        ]),
      });
    } catch (e) {
      print("Error en saveAlbum: $e");
      rethrow;
    }
  }

  Future<void> removeAlbumFromSaved({
    required String userId,
    required String albumId,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'savedAlbum': FieldValue.arrayRemove([
          {'id': albumId},
        ]),
      });
    } catch (e) {
      print("Error en removeAlbumFromSaved: $e");
      rethrow;
    }
  }

  static Future<dynamic> getAlbum(String albumId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('albums')
          .doc(albumId)
          .get();

      if (!doc.exists) return null;

      final data = doc.data();
      return data;
    } catch (e) {
      throw Exception('Error obteniendo álbum: $e');
    }
  }

  Future<void> addSongToArtist(Song song) async {
    try {
      final artistDoc = FirebaseFirestore.instance
          .collection('artists')
          .doc(_artist.id);

      await artistDoc.update({
        'artistSong': FieldValue.arrayUnion([
          {'id': song.id},
        ]),
      });
    } catch (e) {
      print("Error añadiendo canción al artista: $e");
      throw e;
    }
  }

  Future<void> removeSongFromArtist(String songId) async {
    try {
      final artistDoc = FirebaseFirestore.instance
          .collection('artists')
          .doc(_artist.id);

      await artistDoc.update({
        'artistSong': FieldValue.arrayRemove([
          {'id': songId},
        ]),
      });
    } catch (e) {
      print("Error eliminando canción del artista: $e");
      throw e;
    }
  }
}
