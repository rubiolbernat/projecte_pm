import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projecte_pm/models/song.dart';

class SongService {
  //////////////////////////////////////////////////////////////////////////////

  static Future<Song?> getSong(String songId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('songs')
          .doc(songId)
          .get();

      if (!doc.exists) return null; //Id no valid, retorna null

      final data = doc.data();
      data!['id'] = doc.id; // añadimos el id del documento

      Song song = Song.fromMap(data);

      return song; //Id valid, retorna song
    } catch (e) {
      throw Exception('Error obtenint song: $e');
    }
  }

  //////////////////////////////////////////////////////////////////////////////

  static Future<void> updateSong(Song song) async {
    try {
      await FirebaseFirestore.instance
          .collection("songs")
          .doc(song.id)
          .update(song.toMap());
    } catch (e) {
      throw Exception('Error actualitzant Song $e');
    }
  }

  //////////////////////////////////////////////////////////////////////////////
}
