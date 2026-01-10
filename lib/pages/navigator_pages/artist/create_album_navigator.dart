import 'package:flutter/material.dart';
import 'package:projecte_pm/services/ArtistService.dart';
import 'package:projecte_pm/pages/artist_pages/create_album_page.dart';

class CreateAlbumNavigator extends StatelessWidget {
  final ArtistService artistService;
  final GlobalKey<NavigatorState> navigatorKey;

  const CreateAlbumNavigator({
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
          builder: (_) => CreateAlbumPage(artistService: artistService),
        );
      },
    );
  }
}
