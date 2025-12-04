class OwnedPlaylists {
  final String _id; //No modificable
  final String _playlistId;
  final DateTime _createdAt; //No modificable

  //Constructor
  OwnedPlaylists({required String id, required String playlistId})
    : _id = id,
      _playlistId = playlistId,
      _createdAt = DateTime.now();

  //Llista de getters
  String get id => _id;
  String get userId => _playlistId;
  DateTime get followedAt => _createdAt;
}
