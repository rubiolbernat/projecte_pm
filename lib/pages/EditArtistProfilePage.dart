import 'package:flutter/material.dart';
import 'package:projecte_pm/models/artist/artist.dart';
import 'package:projecte_pm/services/ArtistService.dart';

class EditArtistProfilePage extends StatefulWidget {
  final ArtistService artistService;

  const EditArtistProfilePage({super.key, required this.artistService});

  @override
  State<EditArtistProfilePage> createState() => _EditArtistProfilePageState();
}

class _EditArtistProfilePageState extends State<EditArtistProfilePage> {
  late TextEditingController nameController;
  late TextEditingController bioController;
  late Artist draftArtist;

  bool saving = false;

  @override
  void initState() {
    super.initState();

    draftArtist = Artist(
      id: widget.artistService.artist.id,
      name: widget.artistService.artist.name,
      email: widget.artistService.artist.email,
      bio: widget.artistService.artist.bio,
    );

    nameController = TextEditingController(text: draftArtist.name);
    bioController = TextEditingController(text: draftArtist.bio);
  }

  Future<void> save() async {
    setState(() => saving = true);

    draftArtist.name = nameController.text.trim();
    draftArtist.bio = bioController.text.trim();

    await widget.artistService.updateArtist(draftArtist);

    if (mounted) {
      Navigator.pop(context, true);
    }
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
            _darkField(controller: nameController, label: "Nom d'usuari"),
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
