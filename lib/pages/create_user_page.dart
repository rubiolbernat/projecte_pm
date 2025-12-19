import 'package:flutter/material.dart';
import 'package:projecte_pm/models/user.dart';
import 'package:projecte_pm/services/UserService.dart';

class CreateUserPage extends StatefulWidget {
  final UserService userService;

  const CreateUserPage({super.key, required this.userService});

  @override
  State<CreateUserPage> createState() => _CreateUserPageState();
}

class _CreateUserPageState extends State<CreateUserPage> {
  @override
  void initState() {
    super.initState();
    // _loadMyLibrary(widget.userProfile.id);
  }

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        "Create User Page",
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}
