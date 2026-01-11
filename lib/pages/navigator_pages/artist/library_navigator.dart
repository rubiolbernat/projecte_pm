import 'package:flutter/material.dart';
import 'package:projecte_pm/pages/user_pages/player_screen.dart';
import 'package:projecte_pm/services/ArtistService.dart';
import 'package:projecte_pm/pages/artist_pages/library_page.dart';
import 'package:projecte_pm/services/PlayerService.dart';
import 'package:projecte_pm/services/UserService.dart';

class LibraryNavigator extends StatelessWidget {
  final ArtistService artistService;
  final PlayerService playerService;
  final UserService userService;
  final GlobalKey<NavigatorState> navigatorKey;

  const LibraryNavigator({
    super.key,
    required this.artistService,
    required this.navigatorKey,
    required this.playerService,
    required this.userService,
  });

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (_) => ArtistLibraryPage(
            artistService: artistService,
            playerService: playerService,
          ),
        );
      },
    );
  }
}
