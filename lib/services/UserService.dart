import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projecte_pm/models/user/user.dart';
import 'package:projecte_pm/models/user/user_follower.dart';
import 'dart:developer';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _currentUserId; // ID de l'usuari loguejat
  DocumentReference? _currentUserRef;

  UserService({required String userId}) : _currentUserId = userId {
    _currentUserRef = _firestore.collection('users').doc(userId);
  }

  String? get currentUserId => _currentUserId;
  DocumentReference? get currentUserRef => _currentUserRef;

  // Metòdes CRUD
  Future<User?> getCurrentUser() async {
    if (_currentUserRef == null) return null;
    final snap = await _currentUserRef!.get();
    if (!snap.exists) return null;
    log('Dades usuari rebudes: ${snap.data()}', name: 'FIREBASE_LOG');
    return User.fromMap(snap.data() as Map<String, dynamic>);
  }

  Future<void> updateUser(User user) async {
    if (_currentUserRef == null) return;
    try {
      // Actualitzem només els camps necessaris (excepte ID i email que solen ser fixos)
      await _currentUserRef!.update({
        'name': user.name,
        'bio': user.bio,
        'photoURL': user.photoURL,
        // No actualitzem createdAt
      });
    } catch (e) {
      print("Error actualitzant usuari: $e");
      rethrow; // Llancem l'error perquè la UI sàpiga que ha fallat
    }
  }

  // Altres Mètodes
  Future<void> followUser(String targetUserId) async {
    if (_currentUserRef == targetUserId) return;

    final batch = _firestore.batch();

    final myFollowingRef = _currentUserRef!
        .collection('following')
        .doc(targetUserId);

    final targetUserRef = _firestore
        .collection('users')
        .doc(targetUserId)
        .collection('followers')
        .doc(_currentUserId);

    final relation = UserFollower(userId: targetUserId);

    batch.set(myFollowingRef, relation.toMap());
    batch.set(targetUserRef, relation.toMap());

    await batch.commit();
  }

  Future<void> unfollowUser(String targetUserId) async {
    if (_currentUserRef == targetUserId || _currentUserRef == null) return;

    final batch = _firestore.batch();

    batch.delete(_currentUserRef!.collection('following').doc(targetUserId));
    batch.delete(
      _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('followers')
          .doc(_currentUserId)
          .collection('followers')
          .doc(_currentUserId),
    );

    await batch.commit();
  }
}