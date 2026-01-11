import 'package:flutter/material.dart';
import 'package:projecte_pm/services/PlayerService.dart';
import 'package:projecte_pm/services/UserService.dart';
import 'package:projecte_pm/pages/user_pages/create_playlist_page.dart';

class CreatePlaylistNavigator extends StatelessWidget {
  final UserService userService;
  final PlayerService playerService;
  final GlobalKey<NavigatorState> navigatorKey;

  const CreatePlaylistNavigator({
    super.key,
    required this.userService,
    required this.playerService,
    required this.navigatorKey,
  });

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (_) => CreatePlaylistPage(userService: userService, playerService: playerService),
        );
      },
    );
  }
}
