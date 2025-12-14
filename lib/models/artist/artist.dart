import 'package:cloud_firestore/cloud_firestore.dart';

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
       _createdAt = createdAt ?? Timestamp.now(); //Guarda data de pujada.

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
  void addGenre(String genre) => _genre.add(genre);
  void removeGenre(String genre) => _genre.remove(genre);

  //Metodes per socialLink
  void addSocialLink(String platform, String url) => socialLink[platform] = url;
  void removeSocialLink(String platform) => socialLink.remove(platform);

  factory Artist.fromMap(Map<String, dynamic> data) {
    return Artist(
      id: data['id'],
      name: data['name'],
      bio: data['bio'],
      email: data['email'],
      photoURL: data['photoURL'],
      coverURL: data['coverURL'],
      verified: data['verified'],
      label: data['label'],
      manager: data['manager'],
      genre: List<String>.from(data['genre']),
      socialLink: Map<String, String>.from(data['socialLink']),
      createdAt: data['createdAt'],
    );
  }
  
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
    };
  }
}
