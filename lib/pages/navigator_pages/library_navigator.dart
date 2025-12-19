import 'package:flutter/material.dart';
import 'package:projecte_pm/services/UserService.dart';
import 'package:projecte_pm/pages/library_page.dart';

class LibraryNavigator extends StatelessWidget {
  final UserService userService;
  const LibraryNavigator({super.key, required this.userService});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (_) => LibraryPage(userService: userService),
        );
      },
    );
  }
}
