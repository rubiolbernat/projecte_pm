import 'package:cloud_firestore/cloud_firestore.dart';

class AlbumSong {
  String _songId;
  int _trackNumber;
  final Timestamp _addedAt;
  String _title;
  double _duration;

  //Constructor
  AlbumSong({
    required String songId,
    required int trackNumber,
    required String title,
    required double duration,
    Timestamp? addedAt,
  }) : _songId = songId,
       _trackNumber = trackNumber,
       _title = title,
       _duration = duration,
       _addedAt = addedAt ?? Timestamp.now();

  //Llista de getters
  String get songId => _songId;
  int get trackNumber => _trackNumber;
  String get title => _title;
  double get duration => _duration;
  Timestamp get addedAt => _addedAt;

  //Llista de setters
  set songId(String songId) => _songId = songId;
  set trackNumber(int trackNumber) => _trackNumber = trackNumber;

  factory AlbumSong.fromMap(Map<String, dynamic> data) {
    return AlbumSong(
      songId: data['songId'] as String,
      trackNumber: (data['trackNumber'] as num).toInt(),
      title: data['title'] as String,
      duration: (data['duration'] as num).toDouble(),
      addedAt: data['addedAt'] as Timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'songId': _songId,
      'trackNumber': _trackNumber,
      'title': _title,
      'duration': _duration,
      'addedAt': _addedAt,
    };
  }
}
