import 'package:cloud_firestore/cloud_firestore.dart';

class AlbumFollower {
  final String _id;
  final String _userId;
  final Timestamp _followedAt;

  //Constructor
  AlbumFollower({required String id, required String userId})
    : _id = id,
      _userId = userId,
      _followedAt = Timestamp.now();

  //Llista de getters
  String get id => _id;
  String get userId => _userId;
  Timestamp get followedAt => _followedAt;
}
