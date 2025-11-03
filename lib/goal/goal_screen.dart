import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'goal_model.dart';
import 'goal_service.dart';
import '../measure/weekly_weight_chart.dart';
import 'set_goal_sheet.dart';

class GoalScreen extends StatelessWidget {
  const GoalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final svc = GoalService();

    return Scaffold(
      appBar: AppBar(title: const Text('Mục Tiêu Của Bạn')),
      body: StreamBuilder<Goal?>(
        stream: svc.watchCurrent(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final goal = snap.data;
          if (goal == null) {
            // chưa có mục tiêu
            return _EmptyGoal(onSet: () => _openSet(context));
          }
          return _GoalDetail(goal: goal, onReset: svc.resetGoal, onSetAgain: () => _openSet(context));
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openSet(context),
        label: const Text('Đặt mục tiêu'),
        icon: const Icon(Icons.flag_rounded),
      ),
    );
  }

  void _openSet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const SetGoalSheet(),
    );
  }
}

class _EmptyGoal extends StatelessWidget {
  final VoidCallback onSet;
  const _EmptyGoal({required this.onSet});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Icon(Icons.center_focus_strong_rounded, size: 56, color: Color(0xFF7F3DFF)),
                const SizedBox(height: 12),
                const Text('Chưa Có Mục Tiêu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                const Text('Đặt mục tiêu cân nặng để theo dõi tiến độ và nhận động viên mỗi ngày!',
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onSet, child: const Text('ĐẶT MỤC TIÊU NGAY'),
                  ),
                ),
                const SizedBox(height: 16),
                _bullet('Theo dõi tiến độ trực quan'),
                _bullet('Dự đoán thời gian hoàn thành'),
                _bullet('Nhận lời động viên mỗi ngày'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bullet(String t) => Row(
    children: [const Icon(Icons.check_circle_rounded, color: Colors.green), const SizedBox(width: 8), Text(t)],
  );
}

class _GoalDetail extends StatelessWidget {
  final Goal goal;
  final Future<void> Function() onReset;
  final VoidCallback onSetAgain;

  const _GoalDetail({required this.goal, required this.onReset, required this.onSetAgain});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<double?>(
      future: GoalService().latestWeight(),
      builder: (context, wSnap) {
        final current = wSnap.data ?? goal.startWeight;
        final progress = (current - goal.startWeight);             // dương: tăng
        final achieved = goal.direction == 'loss' ? -progress : progress; // kg đạt được theo hướng mục tiêu
        final double percent = (achieved / goal.needAbs).clamp(0, 1);
        final remainKg = (goal.targetWeight - current);
        final remainAbs = remainKg.abs();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _bigCard(percent, current),
            const SizedBox(height: 10),
            Row(
              children: [
                _chip('${goal.needAbs.toStringAsFixed(1)}kg', 'Cần ${goal.direction == 'loss' ? 'giảm' : 'tăng'}'),
                const SizedBox(width: 8),
                _chip('${goal.durationWeeks * 7} ngày', 'Thời hạn'),
                const SizedBox(width: 8),
                _chip('${(goal.needAbs / (goal.durationWeeks)).abs().toStringAsFixed(2)}kg', 'Mỗi tuần'),
              ],
            ),
            const SizedBox(height: 16),
            _forecast(goal: goal, current: current, remainAbs: remainAbs),
            const SizedBox(height: 16),
            const Text('Tiến độ theo tuần', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const WeeklyWeightChart(days: 14),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () async { await onReset(); },
              child: const Text('ĐẶT LẠI MỤC TIÊU'),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: onSetAgain, child: const Text('Đặt mục tiêu khác')),
          ],
        );
      },
    );
  }

  Widget _bigCard(double percent, double current) {
    final pctText = (percent * 100).toStringAsFixed(0);
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7F3DFF), Color(0xFFFF5E7E)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Column(
        children: [
          Text('$pctText%', style: const TextStyle(fontSize: 44, color: Colors.white, fontWeight: FontWeight.w800)),
          const Text('Hoàn thành', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 12),
          Text(
            'Đã ${goal.direction == 'loss' ? 'giảm' : 'tăng'} '
            '${((percent * goal.needAbs)).toStringAsFixed(1)}kg / ${goal.needAbs.toStringAsFixed(1)}kg',
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _mini('Hiện tại', '${current.toStringAsFixed(1)}kg'),
              _mini('Mục tiêu', '${goal.targetWeight.toStringAsFixed(1)}kg'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mini(String t, String v) => Column(
    children: [
      Text(t, style: const TextStyle(color: Colors.white70)),
      const SizedBox(height: 4),
      Text(v, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
    ],
  );

  Widget _chip(String big, String small) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 8)],
      ),
      child: Column(
        children: [
          Text(big, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(small, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    ),
  );

  Widget _forecast({required Goal goal, required double current, required double remainAbs}) {
    return FutureBuilder<double?>(
      future: GoalService().weeklyRateSince(goal.startDate),
      builder: (context, s) {
        final rate = s.data; // kg/tuần (dương: tăng, âm: giảm)
        final dirSign = goal.direction == 'loss' ? -1.0 : 1.0;
        final effective = (rate ?? 0) * dirSign;  // >0 nghĩa là đang đi đúng hướng

        String dateStr = '—';
        String left = '—';
        double progressWeeks = 0;

        if (effective > 0) {
          final weeksNeed = remainAbs / effective;
          final eta = DateTime.now().add(Duration(days: (weeksNeed * 7).ceil()));
          dateStr = 'Khoảng ${_fmt(eta)}';
          left = 'Còn ~${weeksNeed.toStringAsFixed(1)} tuần nữa';
          final total = goal.durationWeeks.toDouble();
          final passed = DateTime.now().difference(goal.startDate).inDays / 7.0;
          progressWeeks = (passed / total).clamp(0.0, 1.0);
        }

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 8)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Dự Đoán Hoàn Thành', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              _rowIcon(Icons.event_available_rounded, 'Ngày hoàn thành', dateStr),
              _rowIcon(Icons.bolt_rounded, 'Thời gian còn lại', left),
              _rowIcon(Icons.show_chart_rounded, 'Tốc độ trung bình',
                  rate == null ? 'Đang theo dõi' : '${rate.abs().toStringAsFixed(2)}kg/tuần'),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: progressWeeks == 0 ? null : progressWeeks, minHeight: 8),
            ],
          ),
        );
      },
    );
  }

  String _fmt(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Widget _rowIcon(IconData ic, String t, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(children: [
      Icon(ic, color: const Color(0xFF7F3DFF)),
      const SizedBox(width: 8),
      Expanded(child: Text(t)),
      Text(v, style: const TextStyle(fontWeight: FontWeight.w600)),
    ]),
  );
}
