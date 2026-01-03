import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:projecte_pm/models/subClass/save_id.dart';
import 'package:projecte_pm/models/subClass/playlist_song.dart';
import 'package:projecte_pm/models/subClass/playlist_collaborator.dart';

class Playlist {
  final String _id;
  String _name;
  String _description;
  final String _ownerId;
  String _coverURL;
  bool _isPublic;
  bool _isCollaborative;
  DateTime _updatedAt;
  final DateTime _createdAt;

  List<SaveId> _follower;
  List<PlaylistCollaborator> _collaborator;
  List<PlaylistSong> _song;

  //Constructor
  Playlist({
    required String id,
    required String name,
    String? description,
    required String ownerId,
    String? coverURL,
    bool? isPublic,
    bool? isCollaborative,
    DateTime? updatedAt,
    DateTime? createdAt,
    List<SaveId>? follower,
    List<PlaylistCollaborator>? collaborator,
    List<PlaylistSong>? song,
  }) : _id = id,
       _name = name,
       _description = description ?? '',
       _ownerId = ownerId,
       _coverURL = coverURL ?? '',
       _isPublic = isPublic ?? false,
       _isCollaborative = isCollaborative ?? false,
       _updatedAt = updatedAt ?? DateTime.now(),
       _createdAt = createdAt ?? DateTime.now(),
       _follower = follower ?? [],
       _collaborator = collaborator ?? [],
       _song = song ?? [];

  //Llista de getters
  String get id => _id;
  String get name => _name;
  String get description => _description;
  String get ownerId => _ownerId;
  String get coverURL => _coverURL;
  bool get isPublic => _isPublic;
  bool get isCollaborative => _isCollaborative;
  DateTime get updatedAt => _updatedAt;
  DateTime get createdAt => _createdAt;
  List<String> get songIds =>
      _song // Afegida per obtenir llista de IDs de cançons (VICTOR)
          .map((playlistSong) => playlistSong.songId)
          .toList(); // Llista de IDs de cançons
  int get totalSongCount => _song.length;

  //Llista de Setters
  set name(String name) => _name = name;
  set description(String description) => _description = description;
  set coverURL(String coverURL) => _coverURL = coverURL;
  set isPublic(bool isPublic) => _isPublic = isPublic;
  set isCollaborative(bool isCollabo) => _isCollaborative = isCollabo;

  //Metode per actualitzar updatedAt
  void updatedAtNow() => _updatedAt = DateTime.now();

  //Metode per afegir un follower a la playlist
  void addFollower(String userId) {
    _follower.add(SaveId(id: userId));
  }

  //Metode per eliminar un follower de la playlist
  void removeFollower(String userId) {
    _follower.removeWhere((user) => user.id == userId);
  }

  //Metode que retorna true si l'usuari es follower de la playlist
  bool isFollower(String userId) {
    return _follower.any((user) => user.id == userId);
  }

  //Metode per afegir un collaborator a la playlist
  void addCollaborator({required String userId, bool? canEdit}) {
    _collaborator.add(PlaylistCollaborator(userId: userId, canEdit: canEdit));
  }

  //Metode per eliminar un collaborator de la playlist
  void removeCollaborator(String userId) {
    _collaborator.removeWhere((user) => user.userId == userId);
  }

  //Metode que retorna true si l'usuari es collaborator de la playlist
  bool isCollaborator(String userId) {
    return _collaborator.any((user) => user.userId == userId);
  }

  //Metode per cambiar el permis d'edició de un collaborator
  void changeCanEdit(String userId) {
    for (var collab in _collaborator) {
      if (collab.userId == userId) {
        collab.changeCanEdit();
        break;
      }
    }
  }

  //Metode per afegir una cançó a la playlist
  void addSong({
    required String songId,
    required int trackNumber,
    required String addedBy,
  }) {
    _song.add(
      PlaylistSong(songId: songId, trackNumber: trackNumber, addedBy: addedBy),
    );
  }

  //Metode per eliminar una cançó de la playlist
  void removeSong(String songId) {
    _song.removeWhere((song) => song.songId == songId);
  }

  //Metode que retorna true si la cançó es a la playlist
  bool isSong(String songId) {
    return _song.any((song) => song.songId == songId);
  }

  //Metodes auxiliars per estadistiques
  int followerCount() => _follower.length;
  int songCount() => _song.length;
  int collaboratorCount() => _collaborator.length;

  //Metode que ompleix la clase a partir de un map de Firebase
  factory Playlist.fromMap(Map<String, dynamic> data) {
    return Playlist(
      id: data['id'] as String,
      name: data['name'] as String,
      description: data['description'] ?? '',
      ownerId: data['ownerId'] as String,
      coverURL: data['coverURL'] ?? '',
      isPublic: data['isPublic'] ?? false,
      isCollaborative: data['isCollaborative'] ?? false,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      follower: (data['follower'] as List<dynamic>? ?? [])
          .map(
            (followData) => SaveId.fromMap(followData as Map<String, dynamic>),
          )
          .toList(),
      collaborator: (data['collaborator'] as List<dynamic>? ?? [])
          .map(
            (collabData) => PlaylistCollaborator.fromMap(
              collabData as Map<String, dynamic>,
            ),
          )
          .toList(),
      song: (data['song'] as List<dynamic>? ?? [])
          .map(
            (songData) =>
                PlaylistSong.fromMap(songData as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  //Metode que pasa la clase a map per pujar a Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': _id,
      'name': _name,
      'description': _description,
      'ownerId': _ownerId,
      'coverURL': _coverURL,
      'isPublic': _isPublic,
      'isCollaborative': _isCollaborative,
      'updatedAt': Timestamp.fromDate(_updatedAt),
      'createdAt': Timestamp.fromDate(_createdAt),
      'follower': _follower.map((follower) => follower.toMap()).toList(),
      'collaborator': _collaborator.map((collabo) => collabo.toMap()).toList(),
      'song': _song.map((song) => song.toMap()).toList(),
    };
  }
}
