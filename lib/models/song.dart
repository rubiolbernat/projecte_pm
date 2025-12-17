import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:projecte_pm/models/subClass/save_id.dart';

class Song {
  final String _id;
  String _name;
  String _artistId; //Només un artista principal
  final List<String> _collaboratorsId; //Pot tenir mes d'un colaborador
  final String _albumId;
  double _duration;
  String _fileURL;
  String _coverURL;
  final List<String> _genre;
  bool _isPublic;
  String _lyrics;
  final Timestamp _createdAt;

  List<SaveId> _album;
  List<SaveId> _playlist;
  List<SaveId> _share;
  List<SaveId> _like;
  List<SaveId> _play;

  //Constructor
  Song({
    String? id,
    required String name,
    required String artistId,
    List<String>? collaboratorsId,
    String? albumId,
    required double duration,
    required String fileURL,
    required String coverURL,
    List<String>? genre,
    bool? isPublic,
    String? lyrics,
    Timestamp? createdAt,
    List<SaveId>? album,
    List<SaveId>? playlist,
    List<SaveId>? share,
    List<SaveId>? like,
    List<SaveId>? play,
  }) : _id = id ?? '',
       _name = name,
       _artistId = artistId,
       _collaboratorsId = collaboratorsId ?? [],
       _albumId = albumId?? '',
       _duration = duration,
       _fileURL = fileURL,
       _coverURL = coverURL,
       _genre = genre ?? [],
       _isPublic = isPublic ?? false,
       _lyrics = lyrics ?? '',
       _createdAt = createdAt ?? Timestamp.now(),
       _album = album ?? [],
       _playlist = playlist ?? [],
       _share = share ?? [],
       _like = like ?? [],
       _play = play ?? [];

  //Llista de getters
  String get id => _id;
  String get name => _name;
  String get artistId => _artistId;
  double get duration => _duration;
  String get fileURL => _fileURL;
  String get coverURL => _coverURL;
  bool get isPublic => _isPublic;
  String get lyrics => _lyrics;
  Timestamp get createdAt => _createdAt;

  //Llista de Setters
  set name(String name) => _name = name;
  set artistId(String artistId) => _artistId = artistId;
  set duration(double duration) => _duration = duration;
  set fileURL(String fileURL) => _fileURL = fileURL;
  set coverURL(String coverURL) => _coverURL = coverURL;
  set isPublic(bool isPublic) => _isPublic = isPublic;
  set lyrics(String lyrics) => _lyrics = lyrics;

  //Metodes per collaboratosId
  void addCollaboratorsId(String id) => _collaboratorsId.add(id);
  void removeCollaboratorsId(String id) => _collaboratorsId.remove(id);

  //Metodes per genre
  void addGenre(String genre) => _genre.add(genre);
  void removeGenre(String genre) => _genre.remove(genre);

  //Metode per asociar un album amb la cançó
  void addAlbum(String albumId) {
    _album.add(SaveId(id: albumId));
  }

  //Metode per desasociar un album de la cançó
  void removeAlbum(String albumId) {
    _album.removeWhere((album) => album.id == albumId);
  }

  //Metode que retorna true si la cançó està asociada amb el album
  bool isAlbum(String albumId) {
    return _album.any((album) => album.id == albumId);
  }

  //Metode per asociar una playlist amb la cançó
  void addPlaylist(String playlistId) {
    _playlist.add(SaveId(id: playlistId));
  }

  //Metode per desasociar una playlist de la cançó
  void removePlaylist(String playlistId) {
    _playlist.removeWhere((playlist) => playlist.id == playlistId);
  }

  //Metode que retorna true si la cançó està asociada amb la playlist
  bool isPlaylist(String playlistId) {
    return _playlist.any((playlist) => playlist.id == playlistId);
  }

  //Metode per guardar un share
  void addShare(String userId) {
    _share.add(SaveId(id: userId));
  }

  //Metode que retorna true si la cançó ha estat compartida per aquest user
  bool isShare(String userId) {
    return _share.any((user) => user.id == userId);
  }

  //Metode per afegir un like a la cançó d'un user
  void addLike(String userId) {
    _like.add(SaveId(id: userId));
  }

  //Metode per eliminar el like a la cançó de un user
  void removeLike(String userId) {
    _like.removeWhere((user) => user.id == userId);
  }

  //Metode que retorna true si li ha donat like aquest user a la cançó
  bool isLike(String userId) {
    return _like.any((user) => user.id == userId);
  }

  //Metode per afegir un play de un user
  void addPlay(String userId) {
    _play.add(SaveId(id: userId));
  }

  //Metode que retorna true si li ha donat play aquest user
  bool isPlayed(String userId) {
    return _play.any((user) => user.id == userId);
  }

  //Metodes que et retornen el numero de x que te la cançó
  int likeCount() => _like.length;
  int playCount() => _play.length;
  int shareCount() => _share.length;

  //Metode que ompleix la clase a partir de un map de Firebase
  factory Song.fromMap(Map<String, dynamic> data) {
    return Song(
      id: data['id'] as String,
      name: data['name'] as String,
      artistId: data['artistId'] as String,
      collaboratorsId: data['collaboratorsId'] as List<String>,
      albumId: data['albumId'] as String,
      duration: data['duration'] as double,
      fileURL: data['fileURL'] as String,
      coverURL: data['coverURL'] as String,
      genre: data['genre'] as List<String>,
      isPublic: data['isPublic'] as bool,
      lyrics: data['lyrics'] as String,
      createdAt: data['createdAt'] as Timestamp,
      album: (data['album'] as List<dynamic>? ?? [])
          .map((albumData) => SaveId.fromMap(albumData as Map<String, dynamic>))
          .toList(),
      playlist: (data['playlist'] as List<dynamic>? ?? [])
          .map(
            (playlistData) =>
                SaveId.fromMap(playlistData as Map<String, dynamic>),
          )
          .toList(),
      share: (data['share'] as List<dynamic>? ?? [])
          .map((shareData) => SaveId.fromMap(shareData as Map<String, dynamic>))
          .toList(),
      like: (data['like'] as List<dynamic>? ?? [])
          .map((likeData) => SaveId.fromMap(likeData as Map<String, dynamic>))
          .toList(),
      play: (data['play'] as List<dynamic>? ?? [])
          .map((playData) => SaveId.fromMap(playData as Map<String, dynamic>))
          .toList(),
    );
  }

  //Metode que pasa la clase a map per pujar a Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': _id,
      'name': _name,
      'artistId': _artistId,
      'collaboratorsId': _collaboratorsId,
      'albumId': _albumId,
      'duration': _duration,
      'fileURL': _fileURL,
      'coverURL': _coverURL,
      'genre': _genre,
      'isPublic': _isPublic,
      'lyrics': _lyrics,
      'createdAt': _createdAt,
      'album': _album.map((album) => album.toMap()).toList(),
      'playlist': _playlist.map((playlist) => playlist.toMap()).toList(),
      'share': _share.map((share) => share.toMap()).toList(),
      'like': _like.map((like) => like.toMap()).toList(),
      'play': _play.map((play) => play.toMap()).toList(),
    };
  }
}
