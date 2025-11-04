import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'weight_service.dart';

enum _Range { all, d7, d30, y1 }

class WeightHistoryScreen extends StatefulWidget {
  const WeightHistoryScreen({super.key});

  @override
  State<WeightHistoryScreen> createState() => _WeightHistoryScreenState();
}

class _WeightHistoryScreenState extends State<WeightHistoryScreen> {
  final _svc = WeightService();
  final _searchCtrl = TextEditingController();
  _Range _range = _Range.all;
  bool _desc = true;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  DateTime? _fromDate() {
    final now = DateTime.now();
    switch (_range) {
      case _Range.d7:  return now.subtract(const Duration(days: 7));
      case _Range.d30: return now.subtract(const Duration(days: 30));
      case _Range.y1:  return DateTime(now.year - 1, now.month, now.day);
      case _Range.all: return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dfDay = DateFormat('d MMMM, yyyy', 'vi');
    final dfTime = DateFormat('HH:mm', 'vi');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch Sử Đo Lường'),
        actions: [
          IconButton(
            tooltip: _desc ? 'Mới nhất' : 'Cũ nhất',
            onPressed: () => setState(() => _desc = !_desc),
            icon: Icon(_desc ? Icons.south_rounded : Icons.north_rounded),
          ),
        ],
      ),
      body: StreamBuilder<List<WeightEntry>>(
        stream: _svc.streamAll(descending: _desc),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          var entries = snap.data ?? [];

          // Filter theo range
          final from = _fromDate();
          if (from != null) {
            entries = entries.where((e) => e.time.isAfter(from)).toList();
          }

          // Search
          final q = _searchCtrl.text.trim().toLowerCase();
          if (q.isNotEmpty) {
            entries = entries.where((e) {
              final w = e.weight.toStringAsFixed(1);
              final n = (e.note ?? '').toLowerCase();
              final d = DateFormat('dd/MM/yyyy').format(e.time);
              return w.contains(q) || n.contains(q) || d.contains(q);
            }).toList();
          }

          if (entries.isEmpty) {
            return _EmptyHistory(
              onGoHome: () => Navigator.pop(context),
              searchField: _SearchBar(ctrl: _searchCtrl, onChanged: (_) => setState(() {})),
              rangeBar: _RangeBar(range: _range, onChanged: (r) => setState(() => _range = r)),
            );
          }

          // Stats
          final weights = entries.map((e) => e.weight).toList()..sort();
          final minW = weights.first;
          final maxW = weights.last;
          final change = entries.last.weight - entries.first.weight; // theo thứ tự hiện tại

          // Group theo ngày
          final Map<DateTime, List<WeightEntry>> byDay = {};
          for (final e in entries) {
            final key = DateTime(e.time.year, e.time.month, e.time.day);
            byDay.putIfAbsent(key, () => []).add(e);
          }
          final days = byDay.keys.toList()
            ..sort((a, b) => _desc ? b.compareTo(a) : a.compareTo(b));

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            children: [
              _SearchBar(ctrl: _searchCtrl, onChanged: (_) => setState(() {})),
              const SizedBox(height: 12),
              _StatsRow(
                total: entries.length,
                changeText: '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}kg',
                minWeight: minW,
                maxWeight: maxW,
              ),
              const SizedBox(height: 12),
              _RangeBar(range: _range, onChanged: (r) => setState(() => _range = r)),
              const SizedBox(height: 6),
              Text('Hiển thị ${entries.length} lần đo',
                  style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 8),

              for (final day in days) ...[
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(.04),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(dfDay.format(day),
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    const Spacer(),
                    Text('${byDay[day]!.length} lần trong ngày',
                        style: const TextStyle(color: Colors.black54)),
                  ],
                ),
                const SizedBox(height: 8),

                for (int i = 0; i < byDay[day]!.length; i++) ...[
                  _EntryTile(
                    index: _desc ? i + 1 : byDay[day]!.length - i,
                    time: dfTime.format(byDay[day]![i].time),
                    weight: byDay[day]![i].weight,
                    note: byDay[day]![i].note,
                    onMore: () => _showEntryMenu(context, byDay[day]![i]),
                  ),
                  const SizedBox(height: 10),
                ],

                const SizedBox(height: 12),
              ],
            ],
          );
        },
      ),
    );
  }

  void _showEntryMenu(BuildContext context, WeightEntry e) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.edit_rounded), title: const Text('Sửa ghi chú'), onTap: () {
              Navigator.pop(context, 'edit');
            }),
            ListTile(leading: const Icon(Icons.delete_outline_rounded), title: const Text('Xoá lần đo này'), onTap: () {
              Navigator.pop(context, 'delete');
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (!mounted || action == null) return;

    final doc = FirebaseFirestore.instance
        .collection('weights').doc(_svc.uid) 
        .collection('entries').doc(e.id);

    if (action == 'delete') {
      await doc.delete();
    } else if (action == 'edit') {
      final controller = TextEditingController(text: e.note ?? '');
      final newNote = await showDialog<String>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Sửa ghi chú'),
          content: TextField(controller: controller, maxLines: 3, decoration: const InputDecoration(hintText: 'Ghi chú...')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
            FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Lưu')),
          ],
        ),
      );
      if (newNote != null) {
        await doc.update({'note': newNote});
      }
    }
  }
}

/// Widgets phụ

class _SearchBar extends StatelessWidget {
  final TextEditingController ctrl;
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.ctrl, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      onChanged: onChanged,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search_rounded),
        hintText: 'Tìm kiếm theo cân nặng, ghi chú, ngày...',
        filled: true,
        fillColor: const Color(0xFFF4F6FB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        isDense: true,
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int total;
  final String changeText;
  final double minWeight;
  final double maxWeight;
  const _StatsRow({
    required this.total,
    required this.changeText,
    required this.minWeight,
    required this.maxWeight,
  });

  @override
  Widget build(BuildContext context) {
    Widget card(String title, String value, {Color? bg}) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bg ?? Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 8)],
          ),
          child: Column(
            children: [
              Text(title, style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 6),
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        card('Tổng số lần đo', '$total'),
        const SizedBox(width: 10),
        card('Thay đổi', changeText, bg: const Color(0xFFEFFAF1)),
        const SizedBox(width: 10),
        card('Hôm nay', DateFormat('dd/MM', 'vi').format(DateTime.now())),
      ],
    );
  }
}

class _RangeBar extends StatelessWidget {
  final _Range range;
  final ValueChanged<_Range> onChanged;
  const _RangeBar({required this.range, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Chip chip(String text, _Range r) => Chip(
      label: Text(text),
      backgroundColor: range == r ? const Color(0xFFEDE8FF) : const Color(0xFFF6F7FB),
      side: BorderSide.none,
    );

    return Wrap(
      spacing: 8,
      children: [
        ChoiceChip(label: const Text('Tất cả'), selected: range == _Range.all, onSelected: (_) => onChanged(_Range.all)),
        ChoiceChip(label: const Text('7 ngày'), selected: range == _Range.d7, onSelected: (_) => onChanged(_Range.d7)),
        ChoiceChip(label: const Text('30 ngày'), selected: range == _Range.d30, onSelected: (_) => onChanged(_Range.d30)),
        ChoiceChip(label: const Text('1 năm'), selected: range == _Range.y1, onSelected: (_) => onChanged(_Range.y1)),
      ],
    );
  }
}

class _EntryTile extends StatelessWidget {
  final int index;
  final String time;
  final double weight;
  final String? note;
  final VoidCallback onMore;

  const _EntryTile({
    required this.index,
    required this.time,
    required this.weight,
    required this.note,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 6)],
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 14, child: Text('$index')),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$weight kg', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                if ((note ?? '').isNotEmpty)
                  Text(note!, style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(time, style: const TextStyle(color: Colors.black54)),
          IconButton(icon: const Icon(Icons.more_vert_rounded), onPressed: onMore),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  final VoidCallback onGoHome;
  final Widget searchField;
  final Widget rangeBar;
  const _EmptyHistory({required this.onGoHome, required this.searchField, required this.rangeBar});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      children: [
        searchField,
        const SizedBox(height: 12),
        rangeBar,
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 8)],
          ),
          child: Column(
            children: [
              const Icon(Icons.bar_chart_rounded, size: 56, color: Colors.black26),
              const SizedBox(height: 8),
              const Text('Chưa Có Lịch Sử', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 4),
              const Text('Bắt đầu thêm cân nặng để theo dõi tiến độ của bạn',
                  textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
              const SizedBox(height: 12),
              FilledButton(onPressed: onGoHome, child: const Text('Về Trang Chủ')),
            ],
          ),
        ),
      ],
    );
  }
}
