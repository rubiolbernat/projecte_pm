class Llista {
  final String _id;
  final String _creadorId;
  final DateTime _dataPujada;
  List<String> _songId;
  String _nom;
  String _descripcio;
  bool _esPublica;

  //Constructor
  Llista({
    required String id,
    required String creadorId,
    required String nom,
    String? descripcio,
    bool? esPublica,
  }) : _id = id,
       _creadorId = creadorId,
       _dataPujada = DateTime.now(), //Guarda data de pujada.
       _songId = [],
       _nom = nom,
       _descripcio = descripcio ?? '',
       _esPublica = esPublica ?? false;

  //Llista de getters
  String get id => _id;
  String get creadorId => _creadorId;
  DateTime get dataPujada => _dataPujada;
  List<String> get songId => _songId;
  String get nom => _nom;
  String get descripcio => _descripcio;
  bool get esPublica => _esPublica;

  //Llista de Setters
  set songId(List<String> songId) => _songId = songId;
  set nom(String nom) => _nom = nom;
  set descripcio(String descripcio) => _descripcio = descripcio;
  set esPublica(bool esPublica) => _esPublica = esPublica;
}
