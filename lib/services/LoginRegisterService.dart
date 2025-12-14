import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projecte_pm/models/artist/artist.dart';
import 'package:projecte_pm/models/user/user.dart';

class LoginRegisterService {
  static Future<String> getUserRole(String uid) async {
    try {
      // A. Mirem si existeix a la col·lecció 'artists'
      final artistDoc = await FirebaseFirestore.instance
          .collection('artists')
          .doc(uid)
          .get();

      if (artistDoc.exists) {
        return 'artist';
      }

      // B. Mirem si existeix a la col·lecció 'users'
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (userDoc.exists) {
        return 'user';
      }

      // C. Si no està a cap lloc (es va registrar però no va triar rol)
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
        .collection('users') // nom de la col·lecció
        .doc(user.id) // pots usar el teu id o deixar que Firestore en generi un
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
