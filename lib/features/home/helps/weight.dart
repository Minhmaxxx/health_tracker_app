import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../features/auth/widgets/quick_action.dart';

DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
DateTime _tomorrow(DateTime d) => _startOfDay(d).add(const Duration(days: 1));

class TodayWeightTile extends StatelessWidget {
  final VoidCallback onTap;
  const TodayWeightTile({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final stream = FirebaseFirestore.instance
        .collection('weights')
        .doc(uid)
        .collection('entries')
        .orderBy('timestamp')
        .startAt([_startOfDay(DateTime.now())])
        .endBefore([_tomorrow(DateTime.now())])
        .limit(1)
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snap) {
        var subtitle = 'Cập nhật hôm nay';
        if (snap.hasData && snap.data!.docs.isNotEmpty) {
          final w =
              (snap.data!.docs.first.data()['weight'] as num?)?.toDouble();
          if (w != null) subtitle = '${w.toStringAsFixed(1)} kg hôm nay';
        }
        return QuickAction(
          colors: const [Color(0xFF2FD3C7), Color(0xFF38BDF8)],
          icon: Icons.monitor_weight_rounded,
          label: 'CÂN NẶNG',
          subtitle: subtitle,
          onTap: onTap,
        );
      },
    );
  }
}
