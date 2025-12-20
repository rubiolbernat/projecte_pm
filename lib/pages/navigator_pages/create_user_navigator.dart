import 'package:flutter/material.dart';
import 'package:projecte_pm/services/UserService.dart';
import 'package:projecte_pm/pages/create_user_page.dart';

class CreateUserNavigator extends StatelessWidget {
  final UserService userService;
  final GlobalKey<NavigatorState> navigatorKey;

  const CreateUserNavigator({
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
          builder: (_) => CreateUserPage(userService: userService),
        );
      },
    );
  }
}
