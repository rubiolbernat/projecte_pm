class Album {
  final String _id;
  final String _creadorId;
  String _titol;
  List<String> _artista;
  List<String> _songId;
  DateTime _dataPujada;

  //Constructor
  Album({
    required String id,
    required String creadorId,
    required String titol,
    required List<String> artista,
    List<String>? songId,
  }) : _id = id,
       _creadorId = creadorId,
       _titol = titol,
       _artista = artista,
       _songId = [],
       _dataPujada = DateTime.now(); //Guarda data de pujada.

  //Llista de getters
  String get id => _id;
  String get creadorId => _creadorId;
  String get titol => _titol;
  List<String> get artista => _artista;
  List<String> get songId => _songId;
  DateTime get dataPujada => _dataPujada;

  //Llista de Setters
  set titol(String titol) => _titol = titol;
  set artista(List<String> artista) => _artista = artista;
  set songId(List<String> songId) => _songId = songId;
}
