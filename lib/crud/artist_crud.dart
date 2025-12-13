import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:projecte_pm/models/artist/artist.dart';

//Clase ArtistCrud
class ArtistCrud {
  static Future<void> newArtist({
    required String artistId,
    required String artistEmail,
  }) async {
    final artist = Artist(id: artistId, email: artistEmail);
    await FirebaseFirestore.instance
        .collection('artist')
        .doc(artist.id)
        .set(artist.toMap());
  }
}
