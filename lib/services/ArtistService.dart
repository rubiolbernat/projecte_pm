import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projecte_pm/models/artist.dart';
import 'dart:developer';

class ArtistService {
  final FirebaseFirestore _firestore;
  final DocumentReference? _currentArtistRef;
  Artist _artist;

  ArtistService._({
    required FirebaseFirestore firestore,
    required DocumentReference currentArtistRef,
    required Artist artist,
  }) : _firestore = firestore,
       _currentArtistRef = currentArtistRef,
       _artist = artist;

  static Future<ArtistService> create({required String artistId}) async {
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
    );
  }

  String? get currentArtistId => _artist.id;
  DocumentReference? get currentArtistRef => _currentArtistRef;

  // Getters de artist
  Artist get artist => _artist;

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
      // Actualitzem només els camps necessaris (excepte ID i email que solen ser fixos)
      await _currentArtistRef!.update(artist.toMap());
    } catch (e) {
      print("Error actualitzant usuari: $e");
      rethrow; // Llancem l'error perquè la UI sàpiga que ha fallat
    }
  }

  //////////////////////////////////////////////////////////////////////////////
  //**************************************************************************//

  static Future<Artist?> getArtist(String artistId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('artists')
          .doc(artistId)
          .get();

      if (!doc.exists) return null; //Id no valid, retorna null

      final data = doc.data();
      data!['id'] = doc.id; // añadimos el id del documento

      Artist artist = Artist.fromMap(data);

      return artist; //Id valid, retorna album
    } catch (e) {
      throw Exception('Error obtenint artist: $e');
    }
  }

  //**************************************************************************//
  //////////////////////////////////////////////////////////////////////////////

  Future<Map<String, dynamic>> getArtistStats() async {
    // Estadístiques de l'artista
    if (_currentArtistRef == null)
      return {}; // Si no hi ha referència, retorna buit

    try {
      // Intentem obtenir les dades
      final artistData = _artist.toMap(); // Dades de l'artista
      final stats =
          artistData['stats'] as Map<String, dynamic>? ?? {}; // Estadístiques

      final songs =
          await _firestore // Obtenir cançons de l'artista
              .collection('songs') // Col·lecció de cançons
              .where(
                'artistId',
                isEqualTo: _currentArtistRef,
              ) // Filtrar per artista
              .get(); // Obtenir documents

      int totalPlays = 0; // Comptador de reproduccions
      for (final doc in songs.docs) {
        // Iterar per cada cançó
        final songData =
            doc.data() as Map<String, dynamic>; // Dades de la cançó
        final songStats =
            songData['stats'] as Map<String, dynamic>? ??
            {}; // Estadístiques de la cançó
        totalPlays +=
            (songStats['playCount'] as int? ?? 0); // Sumar reproduccions
      }

      final albums =
          await _firestore // Obtenir àlbums de l'artista
              .collection('albums') // Col·lecció d'àlbums
              .where(
                'artistId',
                isEqualTo: _currentArtistRef,
              ) // Filtrar per artista
              .get(); // Obtenir documents

      return {
        // Retornar estadístiques
        'followers': stats['followers'] ?? 0, // Nombre de seguidors
        'monthlyListeners': stats['monthlyListeners'] ?? 0, // Oients mensuals
        'totalAlbums': albums.docs.length, // Nombre d'àlbums
        'totalTracks': songs.docs.length, // Nombre de cançons
        'totalPlays': totalPlays, // Total de reproduccions
        'songCount': songs.docs.length, // Nombre de cançons
        'albumCount': albums.docs.length, // Nombre d'àlbums
      };
    } catch (e) {
      // Capturar errors
      print("Error obteniendo estadísticas de artista: $e"); // Missatge d'error
      return {}; // Retornar buit en cas d'error
    }
  }

  // Obtindre les cancons més populars de l'artista
  Future<List<Map<String, dynamic>>> getTopSongs({int limit = 10}) async {
    // Limitar a 10 per defecte
    if (_currentArtistRef == null)
      return []; // Si no hi ha referència, retorna buit

    try {
      // Intentem obtenir les dades
      final songs =
          await _firestore // Obtenir cançons
              .collection('songs') // Col·lecció de cançons
              .where(
                'artistId',
                isEqualTo: _currentArtistRef,
              ) // Filtrar per artista
              .orderBy(
                'stats.playCount',
                descending: true,
              ) // Ordenar per popularitat
              .limit(limit) // Limitar resultats
              .get(); // Obtenir documents

      return songs.docs.map((doc) {
        // Mapear documents
        final data = doc.data() as Map<String, dynamic>; // Dades de la cançó
        final songStats =
            data['stats'] as Map<String, dynamic>? ?? {}; // Estadístiques

        return {
          // Retornar dades rellevants
          'id': doc.id, // ID de la cançó
          'title':
              data['title'] ??
              'Sense Titol', // Títol, si no hi ha posem "Sin título", que no hauria de passar
          'playCount':
              songStats['playCount'] ??
              0, // Comptador de reproduccions, si no hi ha, 0
          'likes':
              songStats['likes'] ?? 0, // Comptador de likes, si no hi ha, 0
          'duration':
              data['duration'] ?? 0, // Durada de la cançó, si no hi ha, 0
          'coverURL':
              data['coverURL'] ?? '', // URL de la portada, si no hi ha, buit
        };
      }).toList(); // Convertir a llista
    } catch (e) {
      // Capturar errors
      print("Error obtenint top de cançons: $e"); // Missatge d'error
      return []; // Retornar buit en cas d'error
    }
  }

  Future<List<Map<String, dynamic>>> getArtistAlbums() async {
    // Obtenir àlbums de l'artista
    if (_currentArtistRef == null)
      return []; // Si no hi ha referència, retorna buit

    try {
      // Intentem obtenir les dades
      final albums =
          await _firestore // Obtenir àlbums
              .collection('albums') // Col·lecció d'àlbums
              .where(
                'artistId',
                isEqualTo: _currentArtistRef,
              ) // Filtrar per artista
              .orderBy(
                'stats.playCount',
                descending: true,
              ) // Ordenar per popularitat
              .get(); // Obtenir documents

      return albums.docs.map((doc) {
        // Mapear documents
        final data = doc.data() as Map<String, dynamic>; // Dades de l'àlbum
        final albumStats =
            data['stats'] as Map<String, dynamic>? ??
            {}; // Estadístiques, si no hi ha, buit

        return {
          // Retornar dades rellevants
          'id': doc.id, // ID de l'àlbum
          'title':
              data['title'] ??
              'Sense Titol', // Títol de l'àlbum, si no hi ha posem "Sense Titol", que no hauria de passar
          'coverURL':
              data['coverURL'] ?? '', // URL de la portada, si no hi ha, buit
          'type': data['type'] ?? 'album', // Tipus d'àlbum, per defecte "album"
          'playCount':
              albumStats['playCount'] ??
              0, // Comptador de reproduccions, si no hi ha, 0
          'saves':
              albumStats['saves'] ?? 0, // Comptador de guardats, si no hi ha, 0
          'totalTracks':
              albumStats['totalTracks'] ??
              0, // Nombre total de cançons, si no hi ha, 0
        };
      }).toList(); // Convertir a llista
    } catch (e) {
      print("Error obtenint albums del artista: $e");
      return [];
    }
  }

  Future<void> saveAlbum({
    // Metode per guardar album
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
    // Metode per treure album del guardat
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
}
