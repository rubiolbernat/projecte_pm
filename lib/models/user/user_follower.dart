class UserFollower {
  final String? _id;
  final String _userId;
  final DateTime _followedAt;

  //Constructor
  UserFollower({String? id, required String userId, DateTime? followedAt})
    : _id = id,
      _userId = userId,
      _followedAt = followedAt ?? DateTime.now();

  //Llista de getters
  String? get id => _id;
  String get userId => _userId;
  DateTime get followedAt => _followedAt;

  factory UserFollower.fromMap(Map<String, dynamic> data) {
    return UserFollower(
      id: data['id'] as String?,
      userId: data['userId'] as String,
      followedAt: data['followedAt'] as DateTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'userId': userId, 'followedAt': followedAt};
  }
}
