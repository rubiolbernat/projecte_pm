import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projecte_pm/models/playlist.dart';
import 'package:projecte_pm/models/subClass/playlist_song.dart';

class PlaylistService {
  //////////////////////////////////////////////////////////////////////////////

  final FirebaseFirestore _firestore; // Instància de Firestore

  PlaylistService({FirebaseFirestore? firestore}) // Constructor
    : _firestore =
          firestore ?? FirebaseFirestore.instance; // Inicialitzar Firestore

  static Future<Playlist?> getPlaylist(String playlistId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('playlists')
          .doc(playlistId)
          .get();

      if (!doc.exists) return null; //Id no valid, retorna null

      final data = doc.data();
      data!['id'] = doc.id; // añadimos el id del documento

      Playlist playlist = Playlist.fromMap(data);

      return playlist; //Id valid, retorna album
    } catch (e) {
      throw Exception('Error obtenint playlist: $e');
    }
  }

  //////////////////////////////////////////////////////////////////////////////

  static Future<void> updatePlaylist(Playlist playlist) async {
    try {
      await FirebaseFirestore.instance
          .collection("playlists")
          .doc(playlist.id)
          .update(playlist.toMap());
    } catch (e) {
      throw Exception('Error actualitzant Playlist $e');
    }
  }

  //////////////////////////////////////////////////////////////////////////////

  // Petició de les playlists d'un usuari

  Future<List<Playlist>> getUserPlaylists(String userId) async {
    // Obtindre playlists d'un usuari
    try {
      //  Intentem obtenir les dades
      final userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get(); // Obtenir document de l'usuari

      if (!userDoc.exists) {
        // Si no existeix l'usuari
        return [];
      }

      final userData =
          userDoc.data() as Map<String, dynamic>; // Dades de l'usuari com a Map

      final ownedPlaylists = List<Map<String, dynamic>>.from(
        userData['ownedPlaylist'] ?? [],
      ); // Array de playlists propietat de l'usuari

      final playlists =
          <Playlist>[]; // Llista per emmagatzemar les playlists carregades

      for (final playlistRef in ownedPlaylists) {
        // Iterar per cada referència de playlist
        final playlistId =
            playlistRef['id'] as String?; // Obtenir l'ID de la playlist

        if (playlistId == null || playlistId.isEmpty)
          continue; // Si l'ID no és vàlid, saltar

        try {
          // Intentem carregar la playlist
          final playlistDoc =
              await _firestore // Obtenir document de la playlist
                  .collection('playlists') // Col·lecció de playlists
                  .doc(playlistId) // Document de la playlist
                  .get(); // Obtenir document

          if (playlistDoc.exists) {
            // Si la playlist existeix
            final data =
                playlistDoc.data()
                    as Map<String, dynamic>; // Dades de la playlist
            data['id'] = playlistDoc.id; // Afegim l'ID del document

            final playlist = Playlist.fromMap(
              data,
            ); // Convertim a objecte Playlist
            playlists.add(playlist); // Afegim a la llista
          }
        } catch (e) {
          rethrow; // Propagar l'error
        }
      }
      return playlists; // Retornar la llista de playlists
    } catch (e) {
      return []; // En cas d'error, retornar llista buida
    }
  }

  Future<String> createPlaylist({
    // Crear nova playlist
    required String userId, // ID de l'usuari propietari
    required String name, // Nom de la playlist
    required String description, // Descripció de la playlist
    required String coverURL, // URL de la portada
    bool isPublic = false, // Si la playlist és pública
  }) async {
    // Retornar l'ID de la nova playlist
    try {
      // Intentem crear la playlist
      final newPlaylistRef = _firestore
          .collection('playlists')
          .doc(); // Nova referència
      final now = Timestamp.now(); // Timestamp actual
      final playlistData = {
        // Dades de la nova playlist
        'id': newPlaylistRef.id, // ID de la playlist
        'name': name, // Nom
        'description': description.isNotEmpty ? description : '', // Descripció
        'ownerId': userId, // ID del propietari
        'coverURL':
            coverURL
                .isNotEmpty // Si hi ha portada, usar-la
            ? coverURL // Usar portada donada
            : 'https://via.placeholder.com/300', // Portada per defecte
        'isPublic': isPublic, // Si és pública
        'isCollaborative': false, // No és col·laborativa per defecte
        'createdAt': now, // Timestamp de creació
        'updatedAt': now, // Timestamp d'actualització
        'song': [], // Array de cançons buit
        'follower': [], // Array de seguidors buit
        'collaborator': [], // Array de col·laboradors buit
      };

      await newPlaylistRef.set(playlistData); // Crear la playlist a Firestore

      final playlistForUser = {
        // Dades per afegir a l'usuari
        'id': newPlaylistRef.id, // ID de la playlist
        'name': name, // Nom de la playlist
        'createdAt': now, // Timestamp de creació
        'isPublic': isPublic, // Si és pública
      };

      final userRef = _firestore
          .collection('users')
          .doc(userId); // Referència de l'usuari

      try {
        // Intentem afegir la playlist a l'array de l'usuari
        await userRef.update({
          'ownedPlaylist': FieldValue.arrayUnion([
            playlistForUser,
          ]), // Afegir a l'array
        });
      } catch (e) {
        // Si falla l'actualització, pot ser perquè l'array no existeix, ho afegim manualment
        final userDoc = await userRef.get(); // Obtenir document de l'usuari
        if (userDoc.exists) {
          // Si l'usuari existeix
          final userData =
              userDoc.data()
                  as Map<String, dynamic>; // Dades de l'usuari com a Map
          final currentPlaylists = List<Map<String, dynamic>>.from(
            // Obtenir l'array actual
            userData['ownedPlaylist'] ?? [], // Si no existeix, crear buit
          );

          currentPlaylists.add(playlistForUser); // Afegir la nova playlist

          await userRef.update({
            'ownedPlaylist': currentPlaylists,
          }); // Actualitzar l'array a Firestore
        } else {
          throw Exception(
            'Usuari no trobat',
          ); // Si l'usuari no existeix, llençar error
        }
      }
      return newPlaylistRef.id; // Retornar l'ID de la nova playlist
    } catch (e) {
      // Capturar errors
      rethrow; // Propagar l'error
    }
  }

  Future<void> addSongToPlaylist({
    // Afegir cançó a la playlist
    required String playlistId, // ID de la playlist
    required String songId, // ID de la cançó
    required String userId, // ID de l'usuari que afegeix
  }) async {
    try {
      // Intentem afegir la cançó
      final playlistRef = _firestore
          .collection('playlists')
          .doc(playlistId); // Referència de la playlist
      final playlistDoc = await playlistRef
          .get(); // Obtenir document de la playlist

      if (!playlistDoc.exists) {
        // Si no existeix la playlist
        throw Exception('Playlist no trobada'); // Llençar error
      }

      final playlistData =
          playlistDoc.data() as Map<String, dynamic>; // Dades de la playlist
      final songs = List<Map<String, dynamic>>.from(
        playlistData['song'] ?? [],
      ); // Array de cançons

      if (songs.any((song) => song['songId'] == songId)) {
        // Si la cançó ja està a la playlist
        throw Exception('La canço ja es a la playlist'); // Llençar error
      }

      final newSong = PlaylistSong(
        // Nova cançó
        songId: songId, // ID de la cançó
        trackNumber: songs.length + 1, // Número de pista
        addedBy: userId, // ID de l'usuari que afegeix
      );

      // Convertir a mapa
      songs.add(newSong.toMap()); // Afegir la nova cançó a l'array

      await playlistRef.update({
        // Actualitzar la playlist a Firestore
        'song': songs, // Actualitzar l'array de cançons
        'updatedAt': FieldValue.serverTimestamp(), // Actualitzar timestamp
      });
    } catch (e) {
      // Capturar errors
      rethrow; // Propagar l'error
    }
  }
}
