import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projecte_pm/models/artist.dart';
import 'package:projecte_pm/models/user.dart';

class LoginRegisterService {
  static Future<String> getUserRole(String uid) async {
    try {
      final artistDoc = await FirebaseFirestore.instance
          .collection('artists')
          .doc(uid)
          .get();

      if (artistDoc.exists) {
        return 'artist';
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (userDoc.exists) {
        return 'user';
      }

      return 'unknown';
    } catch (e) {
      print("Error comprovant rol: $e");
      return 'error';
    }
  }

  static Future<void> newUser({
    required String userId,
    required String userEmail,
  }) async {
    final user = User(id: userId, email: userEmail);
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.id)
        .set(user.toMap());
  }

  static Future<void> newArtist({
    required String artistId,
    required String artistEmail,
  }) async {
    final artist = Artist(id: artistId, email: artistEmail);
    await FirebaseFirestore.instance
        .collection('artists')
        .doc(artist.id)
        .set(artist.toMap());
  }
}
