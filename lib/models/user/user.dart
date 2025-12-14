import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String _id;
  String _name;
  final String _email;
  String _photoURL;
  String _bio;
  final Timestamp _createdAt;

  //Constructor
  User({
    required String id,
    String? name,
    required String email,
    String? photoURL,
    String? bio,
    Timestamp? createdAt,
  }) : _id = id,
       _name = name ?? 'unnamed',
       _email = email,
       _photoURL = photoURL ?? '',
       _bio = bio ?? '',
       _createdAt = createdAt ?? Timestamp.now();

  //Llista de getters
  String get id => _id;
  String get name => _name;
  String get email => _email;
  String get photoURL => _photoURL;
  String get bio => _bio;
  Timestamp get createdAt => _createdAt;

  //Llista de Setters
  set name(String name) => _name = name;
  set photoURL(String photoURL) => _photoURL = photoURL;
  set bio(String bio) => _bio = bio;

  factory User.fromMap(Map<String, dynamic> data) {
    return User(
      id: data['id'] as String,
      name: data['name'] as String,
      email: data['email'] as String,
      photoURL: data['photoURL'] as String? ?? '',
      bio: data['bio'] as String? ?? '',
      createdAt: data['createdAt'] as Timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': _id,
      'name': _name,
      'email': _email,
      'photoURL': _photoURL,
      'bio': _bio,
      'createdAt': _createdAt,
    };
  }
}
