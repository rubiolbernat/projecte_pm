import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projecte_pm/models/subClass/save_id.dart';

class Artist {
  //Atributs clase Artist
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
  final DateTime _createdAt;

  // **NOUS CAMPS PER ESTADÍSTIQUES**
  int _totalListeningTime; // Temps total en segons
  DateTime? _lastListened; // Última vegada que algú va escoltar
  int _monthlyListeners; // Oients del mes actual
  int _totalPlays; // Reproduccions totals

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
    DateTime? createdAt,

    // **NOUS PARÀMETRES**
    int? totalListeningTime,
    DateTime? lastListened,
    int? monthlyListeners,
    int? totalPlays,

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
       _createdAt = createdAt ?? DateTime.now(),
       // **INICIALITZAR NOUS CAMPS**
       _totalListeningTime = totalListeningTime ?? 0,
       _lastListened = lastListened,
       _monthlyListeners = monthlyListeners ?? 0,
       _totalPlays = totalPlays ?? 0,
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
  DateTime get createdAt => _createdAt;

  // **NOUS GETTERS**
  int get totalListeningTime => _totalListeningTime;
  DateTime? get lastListened => _lastListened;
  int get monthlyListeners => _monthlyListeners;
  int get totalPlays => _totalPlays;

  List<SaveId> get artistAlbum => _artistAlbum;
  List<SaveId> get artistFollower => _artistFollower;
  List<SaveId> get artistSong => _artistSong;

  //Llista de Setters
  set name(String name) => _name = name;
  set photoURL(String photoURL) => _photoURL = photoURL;
  set coverURL(String coverURL) => _coverURL = coverURL;
  set bio(String bio) => _bio = bio;
  set verified(bool verified) => _verified = verified;
  set label(String label) => _label = label;
  set manager(String manager) => _manager = manager;

  // **NOUS SETTERS**
  set totalListeningTime(int value) => _totalListeningTime = value;
  set lastListened(DateTime? value) => _lastListened = value;
  set monthlyListeners(int value) => _monthlyListeners = value;
  set totalPlays(int value) => _totalPlays = value;

  //Metodes per genre
  set genre(List<String> genre) => _genre = genre;
  void addGenre(String genre) => _genre.add(genre);
  void removeGenre(String genre) => _genre.remove(genre);

  //Metodes per socialLink
  set socialLink(Map<String, String> socialLink) => _socialLink = socialLink;
  void addSocialLink(String platform, String url) => socialLink[platform] = url;
  void removeSocialLink(String platform) => socialLink.remove(platform);

  //Mètodes per incrementar estadístiques
  void addListeningTime(int seconds) {
    _totalListeningTime += seconds;
    _lastListened = DateTime.now();
  }

  void incrementPlays() {
    _totalPlays++;
  }

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

  // Mètode per formatejar el temps d'escolta
  String formatListeningTime() {
    if (_totalListeningTime <= 0) return '0 minuts';

    final hours = _totalListeningTime ~/ 3600;
    final minutes = (_totalListeningTime % 3600) ~/ 60;

    if (hours > 0) {
      if (minutes > 0) {
        return '${hours}h ${minutes}m';
      } else {
        return '${hours}h';
      }
    } else if (minutes > 0) {
      return '${minutes} minuts';
    } else {
      return '${_totalListeningTime} segons';
    }
  }

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
      genre: List<String>.from(data['genre'] ?? []),
      socialLink: Map<String, String>.from(data['socialLink'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),

      // **NOUS CAMPS**
      totalListeningTime: (data['totalListeningTime'] as int?) ?? 0,
      lastListened: (data['lastListened'] as Timestamp?)?.toDate(),
      monthlyListeners: (data['monthlyListeners'] as int?) ?? 0,
      totalPlays: (data['totalPlays'] as int?) ?? 0,

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
      'createdAt': Timestamp.fromDate(_createdAt),

      // **NOUS CAMPS**
      'totalListeningTime': _totalListeningTime,
      'lastListened': _lastListened != null
          ? Timestamp.fromDate(_lastListened!)
          : null,
      'monthlyListeners': _monthlyListeners,
      'totalPlays': _totalPlays,

      'artistFollower': _artistFollower
          .map((follower) => follower.toMap())
          .toList(),
      'artistSong': _artistSong.map((song) => song.toMap()).toList(),
      'artistAlbum': _artistAlbum.map((album) => album.toMap()).toList(),
    };
  }
}
