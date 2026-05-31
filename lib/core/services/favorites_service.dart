import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoritesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<List<String>> getFavoriteIds() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final doc = await _firestore.collection('favorites').doc(user.uid).get();
    if (!doc.exists) return [];

    return List<String>.from(doc.data()?['stationIds'] ?? []);
  }

Future<void> addToFavorites(
    String stationId) async {

  final user = _auth.currentUser;

  if (user == null) return;

  await _firestore
      .collection('favorites')
      .doc(user.uid)
      .set({
    'stationIds':
        FieldValue.arrayUnion(
            [stationId]),
    'updatedAt':
        FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}

Future<void> removeFromFavorites(
    String stationId) async {

  final user = _auth.currentUser;

  if (user == null) return;

  await _firestore
      .collection('favorites')
      .doc(user.uid)
      .set({
    'stationIds':
        FieldValue.arrayRemove(
            [stationId]),
    'updatedAt':
        FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}

  Future<bool> isFavorite(String stationId) async {
    final favorites = await getFavoriteIds();
    return favorites.contains(stationId);
  }

  Future<bool> toggleFavorite(String stationId) async {
    final isFav = await isFavorite(stationId);
    if (isFav) {
      await removeFromFavorites(stationId);
    } else {
      await addToFavorites(stationId);
    }
    return !isFav;
  }
}