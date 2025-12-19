import 'package:flutter/material.dart';
import 'package:projecte_pm/services/UserService.dart';
import 'package:projecte_pm/pages/search_page.dart';

class SearchNavigator extends StatelessWidget {
  final UserService userService;
  const SearchNavigator({super.key, required this.userService});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (_) => SearchPage(userService: userService),
        );
      },
    );
  }
}
