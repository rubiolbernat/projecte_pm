import 'package:flutter/material.dart';
import 'package:projecte_pm/models/user/user.dart';
import 'package:projecte_pm/widgets/history_list.dart';

class HomePage extends StatefulWidget {
  final User? userProfile;

  const HomePage({super.key, required this.userProfile});

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
    print("Iniciant HomePage per a: ${widget.userProfile?.name}");
  }

  @override
  Widget build(BuildContext context) {
    // Extracció de dades segura per mostrar a la UI
    String bio = widget.userProfile?.bio ?? "Bio no disponible";

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
