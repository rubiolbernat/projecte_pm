import 'package:flutter/material.dart';
import 'package:projecte_pm/services/ArtistService.dart';
import 'package:projecte_pm/widgets/artist_app_bar_widget.dart';

class LibraryPage extends StatefulWidget {
  final ArtistService artistService;

  const LibraryPage({super.key, required this.artistService});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Handler d'errors
    return Scaffold(
      appBar: AppBarWidget(artistService: widget.artistService),
      body: Center(child: Text("Library Artist")),
    );
  }
}
