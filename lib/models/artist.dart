class User {
  //Atributs clase User
  final String _id;
  String _name;
  final String _email;
  String _photoURL;
  String _coverURL;
  String _bio;
  String _label;
  String _manager;
  List<String> _genre;
  Map<String, String> _socialLink;
  final DateTime _createdAt;

  //Constructor
  User({
    required String id,
    required String name,
    required String email,
    String? photoURL,
    String? coverURL,
    String? bio,
    String? label,
    String? manager,
    List<String>? genre,
    Map<String, String>? socialLink,
    DateTime? createdAt,
  }) : _id = id,
       _name = name,
       _email = email,
       _photoURL = photoURL ?? '',
       _coverURL = coverURL ?? '',
       _bio = bio ?? '',
       _label = label ?? '',
       _manager = manager ?? '',
       _genre = genre ?? [],
       _socialLink = socialLink ?? {},
       _createdAt = createdAt ?? DateTime.now(); //Guarda data de pujada.

  //Llista de getters
  String get id => _id;
  String get name => _name;
  String get email => _email;
  String get photoURL => _photoURL;
  String get coverURL => _coverURL;
  String get bio => _bio;
  String get label => _label;
  String get manager => _manager;
  List<String> get genre => _genre;
  Map<String, String> get socialLink => _socialLink;
  DateTime get createdAt => _createdAt;

  //Llista de Setters
  set name(String name) => _name = name;
  set photoURL(String photoURL) => _photoURL = photoURL;
  set coverURL(String coverURL) => _coverURL = coverURL;
  set bio(String bio) => _bio = bio;
  set label(String label) => _label = label;
  set manager(String manager) => _manager = manager;

  //Metodes per genre
  void addGenre(String genre) => _genre.add(genre);
  void removeGenre(String genre) => _genre.remove(genre);

  //Metodes per socialLink
  void addSocialLink(String platform, String url) => socialLink[platform] = url;
  void deleteSocialLink(String platform) => socialLink.remove(platform);
}
