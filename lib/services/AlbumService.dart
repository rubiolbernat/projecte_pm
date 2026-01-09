import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projecte_pm/models/song.dart';
import 'package:projecte_pm/models/album.dart';

class AlbumService {
  Future<void> createAlbum({
    required String artistId,
    required String title,
    required String coverUrl,
    required List<Song> songs,
    List<String>? genres,
    List<String>? collaborators,
  }) async {
    final createdTime = DateTime.now();
    final batch = FirebaseFirestore.instance.batch();

    try {
      // Creem l'àlbum
      final albumRef = FirebaseFirestore.instance.collection('albums').doc();
      final albumId = albumRef.id;

      final Album newAlbum = Album(
        id: albumId,
        name: title,
        artistId: artistId,
        collaboratorId: collaborators ?? [],
        coverURL: coverUrl,
        genre: genres ?? [],
        isPublic: true,
        label: 'Independent',
        createdAt: createdTime,
      );

      List<String> songsIds = [];

      for (int i = 0; i < songs.length; i++) {
        final songRef = FirebaseFirestore.instance.collection('songs').doc();
        final songId = songRef.id;
        songsIds.add(songId);

        final Song songData = songs[i];

        final Song finalSong = Song(
          id: songId,
          albumId: albumId,
          name: songData.name,
          artistId: artistId,
          duration: songData.duration,
          fileURL: songData.fileURL,
          coverURL: coverUrl,
          lyrics: songData.lyrics,
          createdAt: createdTime,
          isPublic: true,
        );

        // Track number comença a 1
        newAlbum.addSong(songId, i + 1, songData.name, songData.duration);

        batch.set(songRef, finalSong.toMap());
      }

      batch.set(albumRef, newAlbum.toMap());

      final artistRef = FirebaseFirestore.instance
          .collection('artists')
          .doc(artistId);

      batch.update(artistRef, {
        'stats.totalAlbums': FieldValue.increment(1),
        'stats.totalTracks': FieldValue.increment(songs.length),
        'artistAlbum': FieldValue.arrayUnion([
          {'id': albumId},
        ]),
        'artistSong': FieldValue.arrayUnion(
          songsIds.map((id) => {'id': id}).toList(),
        ),
      });
      await batch.commit();
    } catch (e) {
      throw Exception('Error creant l’àlbum: $e');
    }
  }

  //////////////////////////////////////////////////////////////////////////////

  static Future<Album?> getAlbum(String albumId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('albums')
          .doc(albumId)
          .get();

      if (!doc.exists) return null; //Id no valid, retorna null

      final data = doc.data();
      data!['id'] = doc.id; // afegim el id del document

      Album album = Album.fromMap(data);

      return album; //Id valid, retorna album
    } catch (e) {
      throw Exception('Error obtenint album: $e');
    }
  }

  //////////////////////////////////////////////////////////////////////////////

  static Future<void> updateAlbum(Album album) async {
    try {
      await FirebaseFirestore.instance
          .collection("albums")
          .doc(album.id)
          .update(album.toMap());
    } catch (e) {
      throw Exception('Error actualitzant Album $e');
    }
  }

  //////////////////////////////////////////////////////////////////////////////

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
      print("Álbum $albumId guardat per usuari $userId");
    } catch (e) {
      print("Error en saveAlbum: $e");
      rethrow;
    }
  }

  // Método per treure album del usuari
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
      print("Álbum $albumId eliminado de guardados para usuario $userId");
    } catch (e) {
      print("Error en removeAlbumFromSaved: $e");
      rethrow;
    }
  }
}
