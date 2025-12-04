class Following {
  final String _id; //No modificable
  final String _userId;
  final DateTime _followedAt; //No modificable

  //Constructor
  Following({required String id, required String userId})
    : _id = id,
      _userId = userId,
      _followedAt = DateTime.now();

  //Llista de getters
  String get id => _id;
  String get userId => _userId;
  DateTime get followedAt => _followedAt;
}
