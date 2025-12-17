import 'package:flutter/material.dart';
import 'package:projecte_pm/models/artist.dart';
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
  late TextEditingController photoURLController;
  late TextEditingController coverURLController;
  late TextEditingController labelController;
  late TextEditingController managerController;
  late TextEditingController genreController;
  late TextEditingController socialNetController;
  late TextEditingController socialLinkController;

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
      photoURL: widget.artistService.artist.photoURL,
      coverURL: widget.artistService.artist.coverURL,
      label: widget.artistService.artist.label,
      manager: widget.artistService.artist.manager,
      genre: widget.artistService.artist.genre,
      socialLink: widget.artistService.artist.socialLink,
    );

    nameController = TextEditingController(text: draftArtist.name);
    bioController = TextEditingController(text: draftArtist.bio);
    photoURLController = TextEditingController(text: draftArtist.photoURL);
    coverURLController = TextEditingController(text: draftArtist.coverURL);
    labelController = TextEditingController(text: draftArtist.label);
    managerController = TextEditingController(text: draftArtist.manager);
    genreController = TextEditingController(text: '');
    socialNetController = TextEditingController(text: '');
    socialLinkController = TextEditingController(text: '');
  }

  Future<void> save() async {
    setState(() => saving = true);

    draftArtist.name = nameController.text.trim();
    draftArtist.bio = bioController.text.trim();
    draftArtist.photoURL = photoURLController.text.trim();
    draftArtist.coverURL = coverURLController.text.trim();
    draftArtist.label = labelController.text.trim();
    draftArtist.manager = managerController.text.trim();

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
      body: SingleChildScrollView(
        child: Padding(
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
              const SizedBox(height: 16),
              _darkField(
                controller: photoURLController,
                label: "URL de la foto de perfil",
              ),
              const SizedBox(height: 16),
              _darkField(
                controller: coverURLController,
                label: "URL de la foto del cover",
              ),
              const SizedBox(height: 16),
              _darkField(controller: labelController, label: "Nom del label"),
              const SizedBox(height: 16),
              _darkField(
                controller: managerController,
                label: "Nom del manager",
              ),
              const SizedBox(height: 16),
              _genreDarkField(
                controller: genreController,
                label: "Tipus de genre",
              ),
              const SizedBox(height: 16),
              _socialLinkDarkField(
                netController: socialNetController,
                linkController: socialLinkController,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SizedBox(
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
              : const Text('Guardar', style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  ///////////////////////////////////////////////*******************************
  //Widget per afegir o eliminar un camp de text//******************************
  ///////////////////////////////////////////////*******************************
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

  ////////////////////////////////////////**************************************
  //Widget per afegir o eliminar un genre//*************************************
  /////////////////////////////////////////*************************************
  Widget _genreDarkField({
    required TextEditingController controller,
    required String label,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        //Visualitzar genre existents i posibilitat d'eliminar-los fent tap
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var genre in draftArtist.genre)
              InkWell(
                onTap: () {
                  setState(() {
                    draftArtist.removeGenre(genre);
                  });
                },
                child: Chip(
                  label: Text(
                    genre,
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.blueAccent,
                ),
              ),
          ],
        ),

        const SizedBox(height: 16),

        // Afegir un nou genre
        Row(
          children: [
            Expanded(
              child: _darkField(controller: controller, label: label),
            ),
            IconButton(
              icon: const Icon(Icons.add, color: Colors.blueAccent),
              onPressed: () {
                final newGenre = controller.text.trim();
                if (newGenre.isNotEmpty) {
                  setState(() {
                    draftArtist.addGenre(newGenre);
                    controller.clear();
                  });
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  //////////////////////////////////////////////********************************
  //Widget per afegir o eliminar un socialLink//********************************
  //////////////////////////////////////////////********************************
  Widget _socialLinkDarkField({
    required TextEditingController netController,
    required TextEditingController linkController,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Visualitzar i eliminar Social Links
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var entry in draftArtist.socialLink.entries)
              InkWell(
                onTap: () {
                  setState(() {
                    draftArtist.removeSocialLink(entry.key);
                  });
                },
                child: Chip(
                  label: Text(
                    "${entry.key}: ${entry.value}",
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.blueAccent,
                ),
              ),
          ],
        ),

        const SizedBox(height: 16),

        // Afegir nou SocialLink
        Row(
          children: [
            Expanded(
              child: _darkField(controller: netController, label: "SocialNet"),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _darkField(
                controller: linkController,
                label: "SocialLink",
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add, color: Colors.blueAccent),
              onPressed: () {
                final net = netController.text.trim();
                final link = linkController.text.trim();
                if (net.isNotEmpty && link.isNotEmpty) {
                  setState(() {
                    draftArtist.addSocialLink(net, link);
                    netController.clear();
                    linkController.clear();
                  });
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}
