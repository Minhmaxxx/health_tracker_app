import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../features/auth/widgets/quick_action.dart';

class GoalSummaryTile extends StatelessWidget {
  final VoidCallback onTap;
  const GoalSummaryTile({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final goalStream =
        FirebaseFirestore.instance.collection('goals').doc(uid).snapshots();
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: goalStream,
      builder: (context, snap) {
        String subtitle = 'Chưa đặt mục tiêu';
        if (snap.hasData && snap.data!.exists) {
          final d = snap.data!.data()!;
          final start = (d['startWeight'] as num?)?.toDouble();
          final target = (d['targetWeight'] as num?)?.toDouble();
          final dir = (d['direction'] as String?) ?? 'loss';

          return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            future: userRef.get(),
            builder: (context, u) {
              if (start != null && target != null) {
                double current = start;
                final doc = u.data;
                final w = (doc?.data()?['latest']?['weight'] as num?)
                    ?.toDouble();
                if (w != null) current = w;
                final need = (target - start).abs();
                final achieved = dir == 'loss'
                    ? (start - current).clamp(0, need)
                    : (current - start).clamp(0, need);
                final pct = need > 0 ? (achieved / need) : 1.0;
                subtitle =
                    '${start.toStringAsFixed(1)} → ${target.toStringAsFixed(1)} kg • ${(pct * 100).round()}%';
              }
              return QuickAction(
                colors: const [Color(0xFFFF5A8A), Color(0xFFFF7A59)],
                icon: Icons.flag_rounded,
                label: 'MỤC TIÊU',
                subtitle: subtitle,
                onTap: onTap,
              );
            },
          );
        }
        return QuickAction(
          colors: const [Color(0xFFFF5A8A), Color(0xFFFF7A59)],
          icon: Icons.flag_rounded,
          label: 'MỤC TIÊU',
          subtitle: subtitle,
          onTap: onTap,
        );
      },
    );
  }
}
