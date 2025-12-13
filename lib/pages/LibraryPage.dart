import 'package:flutter/material.dart';

class LibraryPage extends StatefulWidget{
  final dynamic userProfile;
  final bool isArtist;

  const LibraryPage({super.key, required this.userProfile, required this.isArtist});

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