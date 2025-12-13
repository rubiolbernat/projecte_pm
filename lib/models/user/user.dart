import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String _id;
  String _name;
  final String _email;
  String _photoURL;
  String _bio;
  final DateTime _createdAt;

  //Constructor
  User({
    required String id,
    String? name,
    required String email,
    String? photoURL,
    String? bio,
    DateTime? createdAt,
  }) : _id = id,
       _name = name ?? 'unnamed',
       _email = email,
       _photoURL = photoURL ?? '',
       _bio = bio ?? '',
       _createdAt = DateTime.now();

  //Llista de getters
  String get id => _id;
  String get name => _name;
  String get email => _email;
  String get photoURL => _photoURL;
  String get bio => _bio;
  DateTime get createdAt => _createdAt;

  //Llista de Setters
  set name(String name) => _name = name;
  set photoURL(String photoURL) => _photoURL = photoURL;
  set bio(String bio) => _bio = bio;

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

  factory User.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Converteix Timestamp a DateTime
    final createdAtTimestamp = data['createdAt'] as Timestamp?;
    final createdAt = createdAtTimestamp?.toDate();

    return User(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      photoURL: data['photoURL'],
      bio: data['bio'],
      createdAt: createdAt,
    );
  }
}
