import 'package:flutter/material.dart';
import 'package:projecte_pm/models/user.dart';
import 'package:projecte_pm/pages/detail_screen/user_detail_screen.dart';
import 'package:projecte_pm/services/PlayerService.dart';
import 'package:projecte_pm/services/UserService.dart';

class FollowDetails extends StatelessWidget {
  final User user;
  final PlayerService playerService;
  final bool isFollower;

  const FollowDetails({
    required this.user,
    required this.playerService,
    super.key,
    required this.isFollower,
  });

  @override
  Widget build(BuildContext context) {
    final followers = user.follower ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(isFollower ? 'Seguidors' : 'Seguint'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // USER CARD
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundImage:
                          user.photoURL != null && user.photoURL!.isNotEmpty
                          ? NetworkImage(user.photoURL!)
                          : null,
                      child: user.photoURL == null || user.photoURL!.isEmpty
                          ? const Icon(Icons.person, size: 32)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${followers.length} seguidors · ${user.following?.length ?? 0} seguint',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              isFollower ? 'Seguidors' : 'Seguint',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: followers.isEmpty
                  ? Center(
                      child: Text(
                        isFollower
                            ? 'Aquest usuari no el segueix ningú'
                            : 'Aquest usuari no segueix ningú',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: followers.length,
                      itemBuilder: (context, index) {
                        final followerId = followers[index].id;

                        return FutureBuilder<User?>(
                          future: UserService.getUser(followerId),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const ListTile(
                                leading: CircleAvatar(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                title: Text('Carregant...'),
                              );
                            }

                            if (!snapshot.hasData || snapshot.data == null) {
                              return const ListTile(
                                leading: CircleAvatar(child: Icon(Icons.error)),
                                title: Text('Usuari no disponible'),
                              );
                            }

                            final followerUser = snapshot.data!;

                            return ListTile(
                              leading: CircleAvatar(
                                radius: 22,
                                backgroundImage:
                                    followerUser.photoURL.isNotEmpty
                                    ? NetworkImage(followerUser.photoURL)
                                    : null,
                                child: followerUser.photoURL.isEmpty
                                    ? Text(
                                        followerUser.name[0].toUpperCase(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),

                              title: Text(
                                followerUser.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),

                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (followerUser.bio.isNotEmpty)
                                    Text(
                                      followerUser.bio,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  Text(
                                    '${followerUser.followerCount()} seguidors',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),

                              trailing: const Icon(Icons.chevron_right),

                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => UserDetailScreen(
                                      userId: followerUser.id,
                                      playerService: playerService,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
