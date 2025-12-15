import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projecte_pm/models/user/user.dart';
import 'package:projecte_pm/models/user/user_follower.dart';
import 'dart:developer';

class UserService {
  final FirebaseFirestore _firestore;
  final DocumentReference? _currentUserRef;
  User _user;

  UserService._({
    required FirebaseFirestore firestore,
    required DocumentReference currentUserRef,
    required User user,
  }) : _firestore = firestore,
       _currentUserRef = currentUserRef,
       _user = user;

  static Future<UserService> create({required String userId}) async {
    final firestore = FirebaseFirestore.instance;
    final ref = firestore.collection('users').doc(userId);

    final snap = await ref.get();
    if (!snap.exists) {
      throw Exception('Usuari no trobat');
    }

    final user = User.fromMap(snap.data() as Map<String, dynamic>);

    return UserService._(firestore: firestore, currentUserRef: ref, user: user);
  }

  String? get currentUserId => _user.id;
  DocumentReference? get currentUserRef => _currentUserRef;

  // Getters de user
  User get user => _user;

  // Metòdes CRUD
  Future<User?> getCurrentUser() async {
    if (_currentUserRef == null) return null;
    final snap = await _currentUserRef!.get();
    if (!snap.exists) return null;
    log('Dades usuari rebudes: ${snap.data()}', name: 'FIREBASE_LOG');
    return User.fromMap(snap.data() as Map<String, dynamic>);
  }

  Future<void> refreshUser() async {
    final snap = await _currentUserRef!.get();
    _user = User.fromMap(snap.data() as Map<String, dynamic>);
  }

  Future<void> updateUser(User user) async {
    if (_currentUserRef == null) return;
    try {
      // Actualitzem només els camps necessaris (excepte ID i email que solen ser fixos)
      await _currentUserRef!.update(user.toMap());
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
        .doc(_user.id);

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
          .doc(_user.id),
    );

    await batch.commit();
  }
}
