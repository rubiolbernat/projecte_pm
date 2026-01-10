import 'package:flutter/material.dart';
import 'package:projecte_pm/services/ArtistService.dart';
import 'package:projecte_pm/pages/artist_pages/library_page.dart';

class LibraryNavigator extends StatelessWidget {
  final ArtistService artistService;
  final GlobalKey<NavigatorState> navigatorKey;

  const LibraryNavigator({
    super.key,
    required this.artistService,
    required this.navigatorKey,
  });

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (_) => LibraryPage(artistService: artistService),
        );
      },
    );
  }
}
