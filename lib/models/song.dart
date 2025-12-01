class Song {
  final String id; // id de la cançó
  final String name; // nom de la cançó
  final List<String> artists; // llista d'ids d'artistes
  final String? albumId; // pot ser null si no està en cap àlbum
  final Duration duration; // durada de la cançó
  final String creatorId; // id de l'usuari que ha pujat la cançó
  final DateTime createdAt; // data de creació pujada

  Song({
    required this.id, // id de la cançó
    required this.name, // nom de la cançó
    required this.artists, // llista d'ids d'artistes
    this.albumId, // pot ser null si no està en cap àlbum
    required this.duration, // durada de la cançó
    required this.creatorId, // id de l'usuari que ha pujat la cançó
    required this.createdAt, // data de creació pujada
  });
}
