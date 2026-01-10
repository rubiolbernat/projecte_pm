import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  final String artistId;
  const ProfilePage({required this.artistId, super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(child: Text("Profile Page Artist")),
    );
  }
}
