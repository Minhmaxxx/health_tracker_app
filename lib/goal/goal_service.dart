import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'goal_model.dart';

class GoalService {
  final _db = FirebaseFirestore.instance;
  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  // current goal doc
  DocumentReference<Map<String, dynamic>> get _currentRef =>
      _db.collection('goals').doc(_uid);

  // history collection
  CollectionReference<Map<String, dynamic>> get _historyCol =>
      _db.collection('goals').doc(_uid).collection('history');

  Stream<Goal?> watchCurrent() => _currentRef.snapshots().map((d) {
        if (!d.exists) return null;
        return Goal.fromMap(d.data()!);
      });

  Future<void> setGoal({
    required double currentWeight,
    required double targetWeight,
    required int durationWeeks,
  }) async {
    final now = DateTime.now();
    final end = now.add(Duration(days: 7 * durationWeeks));
    final dir = targetWeight < currentWeight ? 'loss' : 'gain';

    await _currentRef.set({
      'startWeight': currentWeight,
      'targetWeight': targetWeight,
      'startDate': now,
      'durationWeeks': durationWeeks,
      'endDate': end,
      'direction': dir,
      'status': 'current',
    });
  }

  // Lưu bản hiện tại sang history rồi tạo bản mới
  Future<void> archiveCurrentAndSetNew({
    required Map<String, dynamic> currentSnapshot,
    required double resultWeight,
    required double newTarget,
    required int newWeeks,
  }) async {
    final now = DateTime.now();
    final batch = _db.batch();

    final hist = Map<String, dynamic>.from(currentSnapshot)
      ..addAll({'finishedAt': now, 'resultWeight': resultWeight, 'status': 'done'});
    batch.set(_historyCol.doc(), hist);

    final end = now.add(Duration(days: 7 * newWeeks));
    final dir = newTarget < resultWeight ? 'loss' : 'gain';
    batch.set(_currentRef, {
      'startWeight': resultWeight,
      'targetWeight': newTarget,
      'startDate': now,
      'durationWeeks': newWeeks,
      'endDate': end,
      'direction': dir,
      'status': 'current',
    });

    await batch.commit();
  }

  Future<void> resetGoal() => _currentRef.delete();

  Future<double?> latestWeight() async {
    final d = await _db.collection('users').doc(_uid).get();
    return (d.data()?['latest']?['weight'] as num?)?.toDouble();
  }

  Future<double?> weeklyRateSince(DateTime since) async {
    final qs = await _db.collection('weights').doc(_uid)
        .collection('entries')
        .where('timestamp', isGreaterThanOrEqualTo: since)
        .orderBy('timestamp')
        .get();
    if (qs.docs.isEmpty) return null;
    final first = (qs.docs.first['weight'] as num).toDouble();
    final last  = (qs.docs.last['weight'] as num).toDouble();
    final days  = qs.docs.last['timestamp'].toDate().difference(since).inDays.clamp(1, 100000);
    return ((last - first) / days) * 7.0; // kg/tuần
  }
}
