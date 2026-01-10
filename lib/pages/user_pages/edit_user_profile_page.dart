import 'package:flutter/material.dart';
import 'package:projecte_pm/models/user.dart';
import 'package:projecte_pm/services/UserService.dart';

class EditUserProfilePage extends StatefulWidget {
  final UserService userService;

  const EditUserProfilePage({super.key, required this.userService});

  @override
  State<EditUserProfilePage> createState() => _EditUserProfilePageState();
}

class _EditUserProfilePageState extends State<EditUserProfilePage> {
  late final TextEditingController nameController;
  late final TextEditingController bioController;
  late final TextEditingController photoURLController;
  late User draftUser;

  bool saving = false;

  @override
  void initState() {
    super.initState();

    draftUser = User(
      id: widget.userService.user.id,
      name: widget.userService.user.name,
      email: widget.userService.user.email,
      photoURL: widget.userService.user.photoURL,
      bio: widget.userService.user.bio,
    );

    nameController = TextEditingController(text: draftUser.name);
    bioController = TextEditingController(text: draftUser.bio);
    photoURLController = TextEditingController(text: draftUser.photoURL);
  }

  @override
  void dispose() {
    nameController.dispose();
    bioController.dispose();
    photoURLController.dispose();
    super.dispose();
  }

  Future<void> save() async {
    setState(() => saving = true);

    draftUser.name = nameController.text.trim();
    draftUser.bio = bioController.text.trim();
    draftUser.photoURL = photoURLController.text.trim();

    await widget.userService.updateUser(draftUser);

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
                label: "URL imatge de perfil",
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
