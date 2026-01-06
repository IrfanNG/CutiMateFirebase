import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/trip_model.dart';

class TripService {
  static final _db = FirebaseFirestore.instance;

  static Future<void> saveTrip(Trip trip) async {
    final doc = await _db.collection('trips').add(trip.toJson());
    await doc.update({'id': doc.id});
  }

  static Stream<List<Trip>> loadUserTrips() {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Stream.empty();
    }

    return _db
        .collection('trips')
        .where('ownerUid', isEqualTo: uid)
        .snapshots()
        .map((snap) {
          return snap.docs.map((doc) {
            return Trip.fromJson(doc.id, doc.data());
          }).toList();
        });
  }
  static Stream<List<Trip>> loadGroupTrips() {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return const Stream.empty();

  return _db
      .collection('trips')
      .where('isGroup', isEqualTo: true)
      .snapshots()
      .map((snap) =>
          snap.docs.map((d) => Trip.fromJson(d.id, d.data())).toList());
}

}
