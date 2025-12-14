import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  //dynamic perque aquest component serà per a users i artists
  final dynamic userProfile;

  const SearchPage({super.key, required this.userProfile});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  @override
  void initState() {
    super.initState();
    // _loadLastSearches(widget.userProfile.id);
  }

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        "Search View\n(Aquí buscaràs l'historial de cerca del User)",
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}
