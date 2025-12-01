import 'song.dart';

class album {
  final String id; // id de l'àlbum
  final String name; // nom de l'àlbum
  final String artistId; // id de l'artista
  final List<Song> _songs; // llista de cançons de l'àlbum
  final String creatorID; // id de l'usuari que ha creat l'àlbum
  final DateTime createdAt; // data de creació de l'àlbum

  album({
    required this.id, // id de l'àlbum
    required this.name, // nom de l'àlbum
    required this.artistId, // id de l'artista
    required List<Song> songs, // llista de cançons de l'àlbum
    required this.creatorID, // id de l'usuari que ha creat l'àlbum
    required this.createdAt, // data de creació de l'àlbum
  }) : _songs = songs; // inicialització de la llista de cançons
}
