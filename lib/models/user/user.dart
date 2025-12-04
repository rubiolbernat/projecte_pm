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
    required String name,
    required String email,
    String? photoURL,
    String? bio,
  }) : _id = id,
       _name = name,
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
}
