import 'package:flutter/material.dart';
import 'package:projecte_pm/services/AlbumService.dart';
import 'package:projecte_pm/models/album.dart';

class AlbumDetailScreen extends StatefulWidget {
  final String albumId;
  const AlbumDetailScreen({required this.albumId, super.key});

  @override
  State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen> {
  Album? album; // aquí guardaremos el álbum
  bool isLoading = true; // para mostrar un loader mientras carga

  @override
  void initState() {
    super.initState();
    _loadAlbum(); // cargamos el álbum al iniciar
  }

  Future<void> _loadAlbum() async {
    try {
      final result = await AlbumService.getAlbum(widget.albumId);
      setState(() {
        album = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Error cargando álbum: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (album == null) {
      return const Center(
        child: Text(
          "Álbum no encontrado",
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            album!.name,
            style: const TextStyle(color: Colors.white, fontSize: 20),
          ),
          Text(
            "Artista: ${album!.artistId}",
            style: const TextStyle(color: Colors.grey),
          ),
          Text(
            "Canciones: ${album!.songCount()}",
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
