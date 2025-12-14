import 'package:flutter/material.dart';
import 'package:projecte_pm/models/artist/artist.dart';
import 'package:projecte_pm/services/ArtistService.dart';

class EditArtistProfilePage extends StatefulWidget {
  final Artist artist;
  final ArtistService artistService;

  const EditArtistProfilePage({
    super.key,
    required this.artist,
    required this.artistService,
  });

  @override
  State<EditArtistProfilePage> createState() => _EditArtistProfilePageState();
}

class _EditArtistProfilePageState extends State<EditArtistProfilePage> {
  late TextEditingController nameController;
  late TextEditingController bioController;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.artist.name);
    bioController = TextEditingController(text: widget.artist.bio);
  }

  Future<void> save() async {
    
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Editar perfil',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _darkField(
              controller: nameController,
              label: "Nom d'usuari",
            ),
            const SizedBox(height: 16),
            _darkField(
              controller: bioController,
              label: "Biografia",
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: saving ? null : save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Guardar',
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _darkField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.grey.shade900,
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.grey),
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.blueAccent),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
