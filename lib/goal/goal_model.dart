
import 'package:cloud_firestore/cloud_firestore.dart';

class Goal {
  final double startWeight;
  final double targetWeight;
  final DateTime startDate;
  final int durationWeeks;
  final DateTime endDate;
  final String direction; // "loss" or "gain"

  Goal({
    required this.startWeight,
    required this.targetWeight,
    required this.startDate,
    required this.durationWeeks,
    required this.endDate,
    required this.direction,
  });

  double get delta => (targetWeight - startWeight); // âm nếu giảm cân
  double get needAbs => delta.abs();

  factory Goal.fromMap(Map<String, dynamic> m) => Goal(
    startWeight: (m['startWeight'] as num).toDouble(),
    targetWeight: (m['targetWeight'] as num).toDouble(),
    startDate: (m['startDate'] as Timestamp).toDate(),
    durationWeeks: (m['durationWeeks'] as num).toInt(),
    endDate: (m['endDate'] as Timestamp).toDate(),
    direction: m['direction'] as String,
  );

  Map<String, dynamic> toMap() => {
    'startWeight': startWeight,
    'targetWeight': targetWeight,
    'startDate': startDate,
    'durationWeeks': durationWeeks,
    'endDate': endDate,
    'direction': direction,
  };
}
