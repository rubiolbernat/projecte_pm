import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:projecte_pm/models/subClass/save_id.dart';

class Artist {
  //Atributs clase User
  final String _id;
  String _name;
  String _bio;
  final String _email;
  String _photoURL;
  String _coverURL;
  bool _verified;
  String _label;
  String _manager;
  List<String> _genre;
  Map<String, String> _socialLink;
  final Timestamp _createdAt;

  List<SaveId> _artistFollower;
  List<SaveId> _artistSong;
  List<SaveId> _artistAlbum;

  //Constructor
  Artist({
    required String id,
    String? name,
    required String email,
    String? photoURL,
    String? coverURL,
    String? bio,
    bool? verified,
    String? label,
    String? manager,
    List<String>? genre,
    Map<String, String>? socialLink,
    Timestamp? createdAt,
    List<SaveId>? artistFollower,
    List<SaveId>? artistSong,
    List<SaveId>? artistAlbum,
  }) : _id = id,
       _name = name ?? 'unnamed',
       _email = email,
       _photoURL = photoURL ?? '',
       _coverURL = coverURL ?? '',
       _bio = bio ?? '',
       _verified = verified ?? false,
       _label = label ?? '',
       _manager = manager ?? '',
       _genre = genre ?? [],
       _socialLink = socialLink ?? {},
       _createdAt = createdAt ?? Timestamp.now(),
       _artistFollower = artistFollower ?? [],
       _artistSong = artistSong ?? [],
       _artistAlbum = artistAlbum ?? [];

  //Llista de getters
  String get id => _id;
  String get name => _name;
  String get email => _email;
  String get photoURL => _photoURL;
  String get coverURL => _coverURL;
  String get bio => _bio;
  bool get verified => _verified;
  String get label => _label;
  String get manager => _manager;
  List<String> get genre => _genre;
  Map<String, String> get socialLink => _socialLink;
  Timestamp get createdAt => _createdAt;

  //Llista de Setters
  set name(String name) => _name = name;
  set photoURL(String photoURL) => _photoURL = photoURL;
  set coverURL(String coverURL) => _coverURL = coverURL;
  set bio(String bio) => _bio = bio;
  set verified(bool verified) => _verified = verified;
  set label(String label) => _label = label;
  set manager(String manager) => _manager = manager;

  //Metodes per genre
  set genre(List<String> genre) => _genre = genre;
  void addGenre(String genre) => _genre.add(genre);
  void removeGenre(String genre) => _genre.remove(genre);

  //Metodes per socialLink
  set socialLink(Map<String, String> socialLink) => _socialLink = socialLink;
  void addSocialLink(String platform, String url) => socialLink[platform] = url;
  void removeSocialLink(String platform) => socialLink.remove(platform);

  //Metode per afegir un seguidor al artista
  void addFollower(String userId) {
    _artistFollower.add(SaveId(id: userId));
  }

  //Metode per eliminar un seguidor de l'artista
  void removeFollower(String userId) {
    _artistFollower.removeWhere((follower) => follower.id == userId);
  }

  //Metode que retorna true si l'user que li envies segueix l'artista
  bool isFollower(String userId) {
    return _artistFollower.any((follower) => follower.id == userId);
  }

  //Metode per asociar una cançó a l'artista (ha pujat una cançó)
  void addSong(String songId) {
    _artistSong.add(SaveId(id: songId));
  }

  //Metode per eliminar una cançó de l'artista (ha donat de baixa una cançó)
  void removeSong(String songId) {
    _artistSong.removeWhere((song) => song.id == songId);
  }

  //Metode que retorna true si aquesta cançó esta pujada per l'artista
  bool isSong(String songId) {
    return _artistSong.any((song) => song.id == songId);
  }

  //Metode per asociar un album amb l'artista (ha pujat album)
  void addAlbum(String albumId) {
    _artistAlbum.add(SaveId(id: albumId));
  }

  //Metode per eliminar un album del artista (ha donat de baixa un album)
  void removeAlbum(String albumId) {
    _artistAlbum.removeWhere((album) => album.id == albumId);
  }

  //Metode que retorna true si aquest album es de l'artista
  bool isAlbum(String albumId) {
    return _artistAlbum.any((album) => album.id == albumId);
  }

  int followerCount() => _artistFollower.length;
  int songCount() => _artistSong.length;
  int albumCount() => _artistAlbum.length;

  //Metode que ompleix la clase a partir de un map de Firebase
  factory Artist.fromMap(Map<String, dynamic> data) {
    return Artist(
      id: data['id'] as String,
      name: data['name'] ?? 'unnamed',
      bio: data['bio'] ?? '',
      email: data['email'] as String,
      photoURL: data['photoURL'] ?? '',
      coverURL: data['coverURL'] ?? '',
      verified: data['verified'] ?? false,
      label: data['label'] ?? '',
      manager: data['manager'] ?? '',
      genre: List<String>.from(data['genre']),
      socialLink: Map<String, String>.from(data['socialLink']),
      createdAt: data['createdAt'] as Timestamp,
      artistFollower: (data['artistFollower'] as List<dynamic>? ?? [])
          .map(
            (followerData) =>
                SaveId.fromMap(followerData as Map<String, dynamic>),
          )
          .toList(),
      artistSong: (data['artistSong'] as List<dynamic>? ?? [])
          .map((songData) => SaveId.fromMap(songData as Map<String, dynamic>))
          .toList(),
      artistAlbum: (data['artistAlbum'] as List<dynamic>? ?? [])
          .map((albumData) => SaveId.fromMap(albumData as Map<String, dynamic>))
          .toList(),
    );
  }

  //Metode que pasa la clase a map per pujar a Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': _id,
      'name': _name,
      'bio': _bio,
      'email': _email,
      'photoURL': _photoURL,
      'coverURL': _coverURL,
      'verified': _verified,
      'label': _label,
      'manager': _manager,
      'genre': _genre,
      'socialLink': _socialLink,
      'createdAt': _createdAt,
      'artistFollower': _artistFollower
          .map((follower) => follower.toMap())
          .toList(),
      'artistSong': _artistSong.map((song) => song.toMap()).toList(),
      'artistAlbum': _artistAlbum.map((album) => album.toMap()).toList(),
    };
  }
}
