class User {
  String id;
  bool role;
  String name;
  String email;
  String password;
  List<String>? albumId;
  List<String> playlistId;
  List<String> seguits;
  List<String> seguidors;
  DateTime createdAt;

  User({
    required this.id,
    required this.role,
    required this.name,
    required this.email,
    required this.password,
    this.albumId,
    required this.playlistId,
    required this.seguits,
    required this.seguidors,
    required this.createdAt,
  });

  static User fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      role:
          json['role'] == 'admin' || json['role'] == true, // Convert to boolean
      name: json['name'],
      email: json['email'],
      password: json['password'],
      albumId: json['albumId'] != null
          ? List<String>.from(json['albumId'])
          : null,
      playlistId: List<String>.from(json['playlistId'] ?? []),
      seguits: List<String>.from(json['seguits'] ?? []),
      seguidors: List<String>.from(json['seguidors'] ?? []),
      createdAt: DateTime.parse(
        json['createdAt'],
      ), // Convert string to DateTime
    );
  }
}
