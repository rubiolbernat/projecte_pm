import 'package:cloud_firestore/cloud_firestore.dart';

class AlbumSong {
  final String _id;
  String _songId;
  int _trackNumber;
  final Timestamp _addedAt;

  //Constructor
  AlbumSong({
    required String id,
    required String songId,
    required int trackNumber,
  }) : _id = id,
       _songId = songId,
       _trackNumber = trackNumber,
       _addedAt = Timestamp.now();

  //Llista de getters
  String get id => _id;
  String get songId => _songId;
  int get trackNumber => _trackNumber;
  Timestamp get addedAt => _addedAt;

  //Llista de setters
  set songId(String songId) => _songId = songId;
  set trackNumber(int trackNumber) => _trackNumber = trackNumber;
}
