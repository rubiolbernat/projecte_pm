import 'package:flutter/material.dart';
import 'package:projecte_pm/services/UserService.dart';
import 'package:projecte_pm/pages/home_page.dart';

class HomeNavigator extends StatelessWidget {
  final UserService userService;
  final GlobalKey<NavigatorState> navigatorKey;

  const HomeNavigator({
    super.key,
    required this.userService,
    required this.navigatorKey,
  });

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (_) => HomePage(userService: userService),
        );
      },
    );
  }
}
