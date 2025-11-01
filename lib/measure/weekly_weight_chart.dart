import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class WeeklyWeightChart extends StatelessWidget {
  final int days; // 7, 14, 30
  const WeeklyWeightChart({super.key, this.days = 7});

  Stream<List<_WeightPoint>> _stream() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final start = DateTime.now().subtract(Duration(days: days - 1));
    final startMidnight = DateTime(start.year, start.month, start.day);

    return FirebaseFirestore.instance
        .collection('weights')
        .doc(uid)
        .collection('entries')
        .where('timestamp', isGreaterThanOrEqualTo: startMidnight)
        .orderBy('timestamp')
        .snapshots()
        .map((snap) {
      return snap.docs.map((d) {
        final ts = (d['timestamp'] as Timestamp?)?.toDate();
        final w  = (d['weight'] as num?)?.toDouble();
        if (ts == null || w == null) return null;
        final day = DateTime(ts.year, ts.month, ts.day);
        return _WeightPoint(day: day, weight: w);
      }).whereType<_WeightPoint>().toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<_WeightPoint>>(
      stream: _stream(),
      builder: (context, snap) {
        // build date buckets for last N days
        final today = DateTime.now();
        final dates = List.generate(days, (i) {
          final d = today.subtract(Duration(days: days - 1 - i));
          return DateTime(d.year, d.month, d.day);
        });

        // map firestore -> by day (nếu 1 ngày có nhiều bản ghi lấy bản mới nhất)
        final byDay = <DateTime, double>{};
        for (final p in (snap.data ?? [])) {
          byDay[p.day] = p.weight;
        }

        // chuyển thành mảng (có thể chứa null nếu thiếu)
        final series = dates.map((d) => byDay[d]).toList();

        final hasAny = series.any((e) => e != null);
        if (!hasAny) {
          // vẫn dùng placeholder cũ nếu chưa có gì
          return const _EmptyChart();
        }

        // xác định min/max
        final weights = series.whereType<double>().toList();
        double minW = weights.reduce(math.min);
        double maxW = weights.reduce(math.max);
        if (minW == maxW) {
          minW -= 0.5; maxW += 0.5; // tránh trùng
        } else {
          final pad = (maxW - minW) * 0.1;
          minW -= pad; maxW += pad;
        }

        return SizedBox(
          height: 160,
          child: CustomPaint(
            painter: _ChartPainter(
              series: series,
              minW: minW,
              maxW: maxW,
              days: dates,
            ),
            child: Container(),
          ),
        );
      },
    );
  }
}

class _WeightPoint {
  final DateTime day;
  final double weight;
  _WeightPoint({required this.day, required this.weight});
}

class _ChartPainter extends CustomPainter {
  final List<double?> series;   // length = N days, null = missing
  final double minW;
  final double maxW;
  final List<DateTime> days;

  _ChartPainter({
    required this.series,
    required this.minW,
    required this.maxW,
    required this.days,
  });

  final axis = Paint()..color = const Color(0xFFDBE2F2)..strokeWidth = 1;
  final line = Paint()..color = const Color(0xFF5A68FF)..strokeWidth = 2..style = PaintingStyle.stroke;
  final pointFill = Paint()..color = const Color(0xFF5A68FF);
  final missing = Paint()..color = Colors.redAccent..strokeWidth = 2;

  @override
  void paint(Canvas c, Size s) {
    const left = 36.0, right = 12.0, top = 12.0, bottom = 28.0;
    final chartW = s.width - left - right;
    final chartH = s.height - top - bottom;

    // grid ngang (4 vạch)
    for (int i = 0; i <= 4; i++) {
      final y = top + chartH * (i / 4);
      c.drawLine(Offset(left, y), Offset(left + chartW, y), axis);
    }

    // helper to map value -> y
    double vy(double w) => top + chartH * (1 - (w - minW) / (maxW - minW));

    // vẽ line nối các điểm liên tiếp nếu cả hai đều có dữ liệu
    final path = Path();
    for (int i = 0; i < series.length; i++) {
      final x = left + chartW * (i / (series.length - 1).clamp(1, double.infinity));
      final w = series[i];
      if (w != null) {
        final y = vy(w);
        if (!path.contains(Offset.zero)) {
          path.moveTo(x, y);
        } else {
          // nếu điểm trước null thì nhấc bút
          if (series[i - 1] == null) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
      }
    }
    c.drawPath(path, line);

    // vẽ chấm hoặc X
    for (int i = 0; i < series.length; i++) {
      final x = left + chartW * (i / (series.length - 1).clamp(1, double.infinity));
      if (series[i] != null) {
        final y = vy(series[i]!);
        c.drawCircle(Offset(x, y), 3, pointFill);
      } else {
        // X
        const r = 5.0;
        final y = top + chartH * (i / (series.length - 1).clamp(1, double.infinity));
        c.drawLine(Offset(x - r, y - r), Offset(x + r, y + r), missing);
        c.drawLine(Offset(x - r, y + r), Offset(x + r, y - r), missing);
      }
    }

    // nhãn trục X (ngày): chỉ vẽ 3 mốc: đầu, giữa, cuối
    final tp = TextPainter(textDirection: TextDirection.ltr, textAlign: TextAlign.center);
    List<int> idx = [0, (series.length - 1) ~/ 2, series.length - 1];
    for (final i in idx.toSet()) {
      final d = days[i].day;
      final text = TextSpan(style: const TextStyle(fontSize: 10, color: Colors.black54), text: '$d');
      tp.text = text; tp.layout();
      final x = left + chartW * (i / (series.length - 1).clamp(1, double.infinity));
      tp.paint(c, Offset(x - tp.width / 2, s.height - bottom + 8));
    }

    // nhãn min/max bên trái
    final minT = TextPainter(
      text: TextSpan(style: const TextStyle(fontSize: 10, color: Colors.black54), text: minW.toStringAsFixed(1)),
      textDirection: TextDirection.ltr,
    )..layout();
    final maxT = TextPainter(
      text: TextSpan(style: const TextStyle(fontSize: 10, color: Colors.black54), text: maxW.toStringAsFixed(1)),
      textDirection: TextDirection.ltr,
    )..layout();

    minT.paint(c, Offset(4, top + chartH - minT.height / 2));
    maxT.paint(c, Offset(4, top - maxT.height / 2));
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) {
    return old.series != series || old.minW != minW || old.maxW != maxW || old.days != days;
    }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F3FA),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart_rounded, size: 44, color: Colors.black26),
            SizedBox(height: 6),
            Text('Chưa có dữ liệu', style: TextStyle(fontWeight: FontWeight.w600)),
            SizedBox(height: 2),
            Text('Thêm cân nặng để xem biểu đồ', style: TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}
