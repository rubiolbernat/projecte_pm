import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:projecte_pm/models/subClass/album_song.dart';
import 'package:projecte_pm/models/subClass/save_id.dart';

//Clase album
class Album {
  final String _id;
  String _name;
  final String _artistId;
  List<String> _collaboratorId;
  String _coverURL;
  List<String> _genre;
  bool _isPublic;
  String _label;
  Timestamp _createdAt;

  List<AlbumSong> _albumSong;
  List<SaveId> _albumFollower;

  //Constructor
  Album({
    required String id,
    required String name,
    required String artistId,
    List<String>? collaboratorId,
    String? coverURL,
    List<String>? genre,
    bool? isPublic,
    String? label,
    Timestamp? createdAt,
    List<AlbumSong>? albumSong,
    List<SaveId>? albumFollower,
  }) : _id = id,
       _name = name,
       _artistId = artistId,
       _collaboratorId = collaboratorId ?? [],
       _coverURL = coverURL ?? '',
       _genre = genre ?? [],
       _isPublic = isPublic ?? false,
       _label = label ?? '',
       _createdAt = createdAt ?? Timestamp.now(),
       _albumSong = albumSong ?? [],
       _albumFollower = albumFollower ?? [];

  //Llista de getters
  String get id => _id;
  String get name => _name;
  String get artistId => _artistId;
  String get coverURL => _coverURL;
  bool get isPublic => _isPublic;
  String get label => _label;
  Timestamp get createdAt => _createdAt;

  //Llista de Setters
  set name(String name) => _name = name;
  set coverURL(String coverURL) => _coverURL = coverURL;
  set isPublic(bool isPublic) => _isPublic = isPublic;
  set label(String label) => _label = label;

  //Metode per colaboratorsId
  void addCollaboratorId(String id) => _collaboratorId.add(id);
  void removeCollaboratorId(String id) => _collaboratorId.remove(id);

  //Metode per genre
  void addGenre(String genre) => _genre.add(genre);
  void removeGenre(String genre) => _genre.remove(genre);

  //Metode per afegir un seguidor al album
  void addFollower(String userId) {
    _albumFollower.add(SaveId(id: userId));
  }

  //Metode per eliminar un seguidor de l'album
  void removeFollower(String userId) {
    _albumFollower.removeWhere((follower) => follower.id == userId);
  }

  //Metode que retorna true si l'user que li envies segueix l'album
  bool isFollower(String userId) {
    return _albumFollower.any((follower) => follower.id == userId);
  }

  //Metode per afegir una cançó al album
  void addSong(String songId, int trackNumber, String title, double duration) {
    _albumSong.add(AlbumSong(songId: songId, trackNumber: trackNumber, title: title, duration: duration));
  }

  //Metode per eliminar una cançó de l'album
  void removeSong(String songId) {
    _albumSong.removeWhere((song) => song.songId == songId);
  }

  //Metode que retorna true si la cançó que li envies esta en l'album
  bool isSong(String songId) {
    return _albumSong.any((song) => song.songId == songId);
  }

  //Metodes per estadistiques
  int followerCount() => _albumFollower.length;
  int songCount() => _albumSong.length;

  //Metode que ompleix la clase a partir de un map de Firebase
  factory Album.fromMap(Map<String, dynamic> data) {
    return Album(
      id: data['id'] as String,
      name: data['name'] as String,
      artistId: data['artistId'] as String,
      collaboratorId: List<String>.from(data['collaboratorId'] ?? []),
      coverURL: data['coverURL'] ?? '',
      genre: List<String>.from(data['genre'] ?? []),
      isPublic: data['isPublic'] ?? false,
      label: data['label'] ?? '',
      createdAt: data['createdAt'] as Timestamp,
      albumSong: (data['albumSong'] as List<dynamic>? ?? [])
          .map(
            (songData) => AlbumSong.fromMap(songData as Map<String, dynamic>),
          )
          .toList(),
      albumFollower: (data['albumFollower'] as List<dynamic>? ?? [])
          .map(
            (followerData) =>
                SaveId.fromMap(followerData as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  //Metode que pasa la clase a map per pujar a Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': _id,
      'name': _name,
      'artistId': _artistId,
      'collaboratorId': _collaboratorId,
      'coverURL': _coverURL,
      'genre': _genre,
      'isPublic': _isPublic,
      'label': _label,
      'createdAt': _createdAt,
      'albumSong': _albumSong.map((song) => song.toMap()).toList(),
      'albumFollower': _albumFollower
          .map((follower) => follower.toMap())
          .toList(),
    };
  }
}
