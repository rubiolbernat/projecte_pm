import 'song.dart';

class Playlist {
  final String id; // id de la playlist
  final String name; // nom de la playlist
  final String description; // descripció de la playlist
  final bool isPublic; // si la playlist és pública o privada
  final List<Song> _songs; // llista de cançons de la playlist
  final String CreatorId; // id de l'usuari que ha creat la playlist
  final DateTime createdAt; // data de creació de la playlist

  Playlist({
    required this.id, // id de la playlist
    required this.name, // nom de la playlist
    required this.description, // descripció de la playlist
    required this.isPublic, // si la playlist és pública o privada
    required List<Song> songs, // llista de cançons de la playlist
    required this.CreatorId, // id de l'usuari que ha creat la playlist
    required this.createdAt, // data de creació de la playlist
  }) : _songs = songs; // inicialització de la llista de cançons
}
