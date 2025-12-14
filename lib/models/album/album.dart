import 'package:cloud_firestore/cloud_firestore.dart';

class Album {
  final String _id;
  String _name;
  final String _artistId;
  List<String> _collaboratorId;
  String _coverURL;
  List<String> _genre;
  String _type;
  bool _isPublic;
  String _label;
  Timestamp _createdAt;

  //Constructor
  Album({
    required String id,
    required String name,
    required String artistId,
    List<String>? collaboratorId,
    String? coverURL,
    List<String>? genre,
    String? type,
    bool? isPublic,
    String? label,
  }) : _id = id,
       _name = name,
       _artistId = artistId,
       _collaboratorId = collaboratorId ?? [],
       _coverURL = coverURL ?? '',
       _genre = genre ?? [],
       _type = type ?? 'album',
       _isPublic = isPublic ?? false,
       _label = label ?? '',
       _createdAt = Timestamp.now();

  //Llista de getters
  String get id => _id;
  String get name => _name;
  String get artistId => _artistId;
  String get coverURL => _coverURL;
  String get type => _type;
  bool get isPublic => _isPublic;
  String get label => _label;
  Timestamp get createdAt => _createdAt;

  //Llista de Setters
  set name(String name) => _name = name;
  set coverURL(String coverURL) => _coverURL = coverURL;
  set type(String type) => _type = type;
  set isPublic(bool isPublic) => _isPublic = isPublic;
  set label(String label) => _label = label;

  //Metode per colaboratorsId
  void addCollaboratorId(String id) => _collaboratorId.add(id);
  void removeCollaboratorId(String id) => _collaboratorId.remove(id);

  //Metode per genre
  void addGenre(String genre) => _genre.add(genre);
  void removeGenre(String genre) => _genre.remove(genre);
}
