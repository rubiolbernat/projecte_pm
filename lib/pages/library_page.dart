import 'package:flutter/material.dart';
import 'package:projecte_pm/models/user.dart';
import 'package:projecte_pm/services/UserService.dart';

class LibraryPage extends StatefulWidget {
  final UserService userService;

  const LibraryPage({super.key, required this.userService});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  @override
  void initState() {
    super.initState();
    // _loadMyLibrary(widget.userProfile.id);
  }

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        "Library View\n(Aquí carregaràs playlists guardades)",
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}
