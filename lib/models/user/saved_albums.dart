class SavedAlbums {
  final String _id; //No modificable
  final String _albumId;
  final DateTime _savedAt; //No modificable

  //Constructor
  SavedAlbums({required String id, required String playlistId})
    : _id = id,
      _albumId = playlistId,
      _savedAt = DateTime.now();

  //Llista de getters
  String get id => _id;
  String get userId => _albumId;
  DateTime get followedAt => _savedAt;
}
