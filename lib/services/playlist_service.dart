import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projecte_pm/models/song.dart';
import 'package:projecte_pm/models/playlist.dart';

class PlaylistService {
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
}
