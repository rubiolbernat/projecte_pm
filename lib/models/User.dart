class User {
  String id; // id de l'usuari
  bool role; // true = artista/admin, false = usuari normal
  String name; // nom de l'usuari
  String email; // correu electrònic de l'usuari
  String password; // contrasenya de l'usuari
  List<String>? albumId; // àlbums creats (si és artista)
  List<String> playlistId; // llistes creades
  List<String> seguits; // usuaris/artistes seguits
  List<String> seguidors; // usuaris/artistes que segueixen aquest usuari
  DateTime createdAt; // data de creació del compte

  User({
    required this.id, // id de l'usuari
    required this.role, // true = artista/admin, false = usuari normal
    required this.name, // nom de l'usuari
    required this.email, // correu electrònic de l'usuari
    required this.password, // contrasenya de l'usuari
    this.albumId, // àlbums creats (si és artista)
    required this.playlistId, // llistes creades
    required this.seguits, // usuaris/artistes seguits
    required this.seguidors, // usuaris/artistes que segueixen aquest usuari
    required this.createdAt, // data de creació del compte
  });
}
