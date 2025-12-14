import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projecte_pm/models/artist/artist.dart';
import 'dart:developer';

class ArtistService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _currentArtistId; // ID de l'usuari loguejat
  DocumentReference? _currentArtistRef;

  ArtistService({required String artistId}) : _currentArtistId = artistId {
    _currentArtistRef = _firestore.collection('artists').doc(artistId);
  }

  String? get currentArtistId => _currentArtistId;
  DocumentReference? get currentArtistRef => _currentArtistRef;

  // Metòdes CRUD
  Future<Artist?> getCurrentArtist() async {
    if (_currentArtistRef == null) return null;
    final snap = await _currentArtistRef!.get();
    if (!snap.exists) return null;
    log('Dades artist rebudes: ${snap.data()}', name: 'FIREBASE_LOG');
    return Artist.fromMap(snap.data() as Map<String, dynamic>);
  }
}