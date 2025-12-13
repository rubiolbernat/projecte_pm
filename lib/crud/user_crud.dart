import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:projecte_pm/models/user/user.dart';

//Clase UserCrud
class UserCrud {
  static Future<void> newUser({
    required String userId,
    required String userEmail,
  }) async {
    final user = User(id: userId, email: userEmail);
    await FirebaseFirestore.instance
        .collection('user') // nom de la col·lecció
        .doc(user.id) // pots usar el teu id o deixar que Firestore en generi un
        .set(user.toMap());
  }
}
