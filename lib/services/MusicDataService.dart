import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projecte_pm/models/song.dart';
import 'package:projecte_pm/models/album.dart';

class MusicDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createAlbum({
    required String artistId,
    required String title,
    required String coverUrl,
    required List<Song> songs,
    List<String>? genres,
    List<String>? collaborators,
  }) async {
    final createdTime = Timestamp.now();
    final batch = _firestore.batch();

    try {
      // Creem l'àlbum
      final albumRef = _firestore.collection('albums').doc();
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

      for (int i = 0; i < songs.length; i++) {
        final songRef = _firestore.collection('songs').doc();
        final Song songData = songs[i];

        final Song finalSong = Song(
          id: songRef.id,
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
        newAlbum.addSong(songRef.id, i + 1, songData.name, songData.duration);

        batch.set(songRef, finalSong.toMap());
      }

      batch.set(albumRef, newAlbum.toMap());

      final artistRef = _firestore.collection('artists').doc(artistId);

      batch.update(artistRef, {
        'stats.totalAlbums': FieldValue.increment(1),
        'stats.totalTracks': FieldValue.increment(songs.length),
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Error creant l’àlbum: $e');
    }
  }
}
