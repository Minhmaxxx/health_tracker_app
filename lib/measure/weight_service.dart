import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WeightEntry {
  final String id;
  final double weight;
  final String? note;
  final DateTime time;

  WeightEntry({required this.id, required this.weight, this.note, required this.time});

  factory WeightEntry.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data()!;
    return WeightEntry(
      id: d.id,
      weight: (m['weight'] as num).toDouble(),
      note: m['note'] as String?,
      time: (m['timestamp'] as Timestamp).toDate(),
    );
  }
}

class WeightService {
  final _db = FirebaseFirestore.instance;
  // Change from private to public getter
  String get uid => FirebaseAuth.instance.currentUser!.uid;

  Stream<List<WeightEntry>> streamAll({bool descending = true}) {
    return _db
        .collection('weights').doc(uid).collection('entries')
        .orderBy('timestamp', descending: descending)
        .snapshots()
        .map((s) => s.docs.map((d) => WeightEntry.fromDoc(d)).toList());
  }
}
