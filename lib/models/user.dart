import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:projecte_pm/models/subClass/save_id.dart';
import 'package:projecte_pm/models/subClass/user_play_history.dart';

class User {
  final String _id;
  String _name;
  final String _email;
  String _photoURL;
  String _bio;
  final DateTime _createdAt;

  List<SaveId> _follower;
  List<SaveId> _following;
  List<SaveId> _ownedPlaylist;
  List<SaveId> _savedPlaylist;
  List<SaveId> _savedAlbum;
  List<UserPlayHistory> _playHistory;

  //Constructor
  User({
    required String id,
    String? name,
    required String email,
    String? photoURL,
    String? bio,
    DateTime? createdAt,
    List<SaveId>? follower,
    List<SaveId>? following,
    List<SaveId>? ownedPlaylist,
    List<SaveId>? savedPlaylist,
    List<SaveId>? savedAlbum,
    List<UserPlayHistory>? playHistory,
  }) : _id = id,
       _name = name ?? 'unnamed',
       _email = email,
       _photoURL = photoURL ?? '',
       _bio = bio ?? '',
       _createdAt = createdAt ?? DateTime.now(),
       _follower = follower ?? [],
       _following = following ?? [],
       _ownedPlaylist = ownedPlaylist ?? [],
       _savedPlaylist = savedPlaylist ?? [],
       _savedAlbum = savedAlbum ?? [],
       _playHistory = playHistory ?? [];

  //Llista de getters
  String get id => _id;
  String get name => _name;
  String get email => _email;
  String get photoURL => _photoURL;
  String get bio => _bio;
  DateTime get createdAt => _createdAt;
  List<SaveId> get ownedPlaylist => _ownedPlaylist;

  //Llista de Setters
  set name(String name) => _name = name;
  set photoURL(String photoURL) => _photoURL = photoURL;
  set bio(String bio) => _bio = bio;

  //Metode per afegir un seguidor a l'user
  void addFollower(String userId) {
    _follower.add(SaveId(id: userId));
  }

  //Metode per eliminar un seguidor de l'usuari
  void removeFollower(String userId) {
    _follower.removeWhere((follower) => follower.id == userId);
  }

  //Metode que retorna true si l'user que li envies segueix l'usuari
  bool isFollower(String userId) {
    return _follower.any((follower) => follower.id == userId);
  }

  //Metode per seguir a un altre usuari
  void addFollowing(String userId) {
    _following.add(SaveId(id: userId));
  }

  //Metode per deixar de seguir a un usuari
  void removeFollowing(String userId) {
    _following.removeWhere((follower) => follower.id == userId);
  }

  //Metode que retorna true si estic seguint a l'user que li pases
  bool isFollowing(String userId) {
    return _following.any((follower) => follower.id == userId);
  }

  //Metode per asociar la playlist amb l'usuari quan crea una nova
  void addOwnedPlaylist(String playlistId) {
    _ownedPlaylist.add(SaveId(id: playlistId));
  }

  //Metode per desasociar playlist amb l'usuari quan la elimina
  void removeOwnedPlaylist(String playlistId) {
    _ownedPlaylist.removeWhere((playlist) => playlist.id == playlistId);
  }

  //Metode que retorna true si l'usuari es el creador de la playlist
  bool isOwnedPlaylist(String playlistId) {
    return _ownedPlaylist.any((playlist) => playlist.id == playlistId);
  }

  //Metode per asociar una playlist amb l'usuari quan la guarda
  void addSavedPlaylist(String playlistId) {
    _savedPlaylist.add(SaveId(id: playlistId));
  }

  //Metode per deixar de guardar una playlist
  void removeSavedPlaylist(String playlistId) {
    _savedPlaylist.removeWhere((playlist) => playlist.id == playlistId);
  }

  //Metode que retorna true si l'user esta guardant aquesta playlist
  bool isSavedPlaylist(String playlistId) {
    return _savedPlaylist.any((playlist) => playlist.id == playlistId);
  }

  //Metode per afegir un album a la biblioteca de l'usuari
  void addSavedAlbum(String albumId) {
    _savedAlbum.add(SaveId(id: albumId));
  }

  //Metode per eliminar un album de la biblioteca de l'usuari
  void removeSavedAlbum(String albumId) {
    _savedAlbum.removeWhere((album) => album.id == albumId);
  }

  //Metode que retorna true si l'user te guardat l'album
  bool isSavedAlbum(String albumId) {
    return _savedAlbum.any((album) => album.id == albumId);
  }

  //Metode per afegir un album a la biblioteca de l'usuari
  void addPlayHistory({
    required String songId,
    bool? completed,
    DateTime? playedAt,
  }) {
    _playHistory.add(
      UserPlayHistory(songId: songId, completed: completed, playedAt: playedAt),
    );
  }

  //Cridar a aquest metode abans de saltar a altre cançó
  void markLastSongAsCompleted() {
    if (_playHistory.isNotEmpty) {
      _playHistory.last.songCompleted();
    }
  }

  //La última cançó està completada? Si no ho està mostrar-la a l'usuari
  bool isLastSongCompleted() {
    if (_playHistory.isEmpty) {
      return true;
    }
    return _playHistory.last.completed;
  }

  //Metodes auxiliars per estadistiques
  int followerCount() => _follower.length;
  int followingCount() => _following.length;
  int savedPlaylist() => _savedPlaylist.length;
  int savedAlbum() => _savedAlbum.length;
  int playHistory() => _playHistory.length;

  //Metode que ompleix la clase a partir de un map de Firebase
  factory User.fromMap(Map<String, dynamic> data) {
    return User(
      id: data['id'] as String,
      name: data['name'] as String,
      email: data['email'] as String,
      photoURL: data['photoURL'] ?? '',
      bio: data['bio'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      follower: (data['follower'] as List<dynamic>? ?? [])
          .map(
            (followData) => SaveId.fromMap(followData as Map<String, dynamic>),
          )
          .toList(),
      following: (data['following'] as List<dynamic>? ?? [])
          .map(
            (followData) => SaveId.fromMap(followData as Map<String, dynamic>),
          )
          .toList(),
      ownedPlaylist: (data['ownedPlaylist'] as List<dynamic>? ?? [])
          .map(
            (ownedPData) => SaveId.fromMap(ownedPData as Map<String, dynamic>),
          )
          .toList(),
      savedPlaylist: (data['savedPlaylist'] as List<dynamic>? ?? [])
          .map(
            (savedPData) => SaveId.fromMap(savedPData as Map<String, dynamic>),
          )
          .toList(),
      savedAlbum: (data['savedAlbum'] as List<dynamic>? ?? [])
          .map(
            (savedAData) => SaveId.fromMap(savedAData as Map<String, dynamic>),
          )
          .toList(),
      playHistory: (data['playHistory'] as List<dynamic>? ?? [])
          .map(
            (pHData) => UserPlayHistory.fromMap(pHData as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  //Metode que pasa la clase a map per pujar a Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': _id,
      'name': _name,
      'email': _email,
      'photoURL': _photoURL,
      'bio': _bio,
      'createdAt': Timestamp.fromDate(_createdAt),
      'follower': _follower.map((follower) => follower.toMap()).toList(),
      'following': _following.map((following) => following.toMap()).toList(),
      'ownedPlaylist': _ownedPlaylist.map((ownedP) => ownedP.toMap()).toList(),
      'savedPlaylist': _savedPlaylist.map((savedP) => savedP.toMap()).toList(),
      'savedAlbum': _savedAlbum.map((savedA) => savedA.toMap()).toList(),
      'playHistory': _playHistory.map((playH) => playH.toMap()).toList(),
    };
  }
}
