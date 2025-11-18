import 'package:flutter/material.dart';

class QuickQuestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const QuickQuestionChip({
    Key? key,
    required this.label,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(
          label,
          style: const TextStyle(fontSize: 13),
        ),
        onPressed: onTap,
        backgroundColor: Colors.white,
        side: BorderSide(color: Colors.grey.shade300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}