import 'package:flutter/material.dart';

class UserDetailScreen extends StatelessWidget {
  final String userId;
  const UserDetailScreen({required this.userId, super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: Center(
      child: Text("User: $userId", style: const TextStyle(color: Colors.white)),
    ),
  );
}
