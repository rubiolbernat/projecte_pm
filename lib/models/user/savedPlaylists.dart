class SavedPlaylists {
  final String _id; //No modificable
  final String _playlistId;
  final DateTime _savedAt; //No modificable

  //Constructor
  SavedPlaylists({required String id, required String playlistId})
    : _id = id,
      _playlistId = playlistId,
      _savedAt = DateTime.now();

  //Llista de getters
  String get id => _id;
  String get userId => _playlistId;
  DateTime get followedAt => _savedAt;
}
