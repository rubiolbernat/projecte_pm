import 'package:flutter/material.dart';
import 'package:projecte_pm/models/artist/artist.dart';
import 'package:projecte_pm/models/user/user.dart' as models;

class HomePage extends StatefulWidget {
  final dynamic userProfile; // Model User o Artist
  final bool isArtist;

  const HomePage({
    super.key,
    required this.userProfile,
    required this.isArtist,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Aquí definiràs les teves llistes locals
  // List<Album> _recentAlbums = [];

  @override
  void initState() {
    super.initState();
    // AQUÍ és on cridaràs al teu servei per omplir aquesta vista
    // _loadHomeData(widget.userProfile.id);
    print(
      "Iniciant HomePage per a: ${widget.isArtist ? (widget.userProfile as Artist).name : (widget.userProfile as models.User).name}",
    );
  }

  @override
  Widget build(BuildContext context) {
    // Extracció de dades segura per mostrar a la UI
    String bio = widget.isArtist
        ? (widget.userProfile as Artist).bio
        : (widget.userProfile as models.User).bio;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Home View",
            style: TextStyle(color: Colors.white, fontSize: 24),
          ),
          const SizedBox(height: 10),
          Text(
            "Bio del model passat: $bio",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          const Text(
            "(Aquí carregaràs els àlbums, history, etc.)",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
