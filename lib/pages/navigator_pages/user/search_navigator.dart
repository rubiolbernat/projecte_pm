import 'package:flutter/material.dart';
import 'package:projecte_pm/services/UserService.dart';
import 'package:projecte_pm/pages/user_pages/search_page.dart';
import 'package:projecte_pm/services/PlayerService.dart';

class SearchNavigator extends StatelessWidget {
  final PlayerService playerService;
  final GlobalKey<NavigatorState> navigatorKey;

  const SearchNavigator({
    super.key,
    required this.playerService,
    required this.navigatorKey,
  });

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (_) => SearchPage(
            playerService: playerService,
          ),
        );
      },
    );
  }
}
