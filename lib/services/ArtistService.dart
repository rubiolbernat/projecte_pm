import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projecte_pm/models/artist.dart';
import 'dart:developer';

class ArtistService {
  final FirebaseFirestore _firestore;
  final DocumentReference? _currentArtistRef;
  Artist _artist;

  ArtistService._({
    required FirebaseFirestore firestore,
    required DocumentReference currentArtistRef,
    required Artist artist,
  }) : _firestore = firestore,
       _currentArtistRef = currentArtistRef,
       _artist = artist;

  static Future<ArtistService> create({required String artistId}) async {
    final firestore = FirebaseFirestore.instance;
    final ref = firestore.collection('artists').doc(artistId);

    final snap = await ref.get();
    if (!snap.exists) {
      throw Exception('Artist no trobat');
    }

    final artist = Artist.fromMap(snap.data() as Map<String, dynamic>);

    return ArtistService._(
      firestore: firestore,
      currentArtistRef: ref,
      artist: artist,
    );
  }

  String? get currentArtistId => _artist.id;
  DocumentReference? get currentArtistRef => _currentArtistRef;

  // Getters de artist
  Artist get artist => _artist;

  // Metòdes CRUD
  Future<Artist?> getCurrentArtist() async {
    if (_currentArtistRef == null) return null;
    final snap = await _currentArtistRef!.get();
    if (!snap.exists) return null;
    log('Dades artist rebudes: ${snap.data()}', name: 'FIREBASE_LOG');
    return Artist.fromMap(snap.data() as Map<String, dynamic>);
  }

  Future<void> refreshArtist() async {
    final snap = await _currentArtistRef!.get();
    _artist = Artist.fromMap(snap.data() as Map<String, dynamic>);
  }

  Future<void> updateArtist(Artist artist) async {
    if (_currentArtistRef == null) return;
    try {
      // Actualitzem només els camps necessaris (excepte ID i email que solen ser fixos)
      await _currentArtistRef!.update(artist.toMap());
    } catch (e) {
      print("Error actualitzant usuari: $e");
      rethrow; // Llancem l'error perquè la UI sàpiga que ha fallat
    }
  }

  //////////////////////////////////////////////////////////////////////////////
  //**************************************************************************//

  static Future<Artist?> getArtist(String artistId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('artists')
          .doc(artistId)
          .get();

      if (!doc.exists) return null; //Id no valid, retorna null

      final data = doc.data();
      data!['id'] = doc.id; // añadimos el id del documento

      Artist artist = Artist.fromMap(data);

      return artist; //Id valid, retorna album
    } catch (e) {
      throw Exception('Error obtenint artist: $e');
    }
  }

  //**************************************************************************//
  //////////////////////////////////////////////////////////////////////////////
}
