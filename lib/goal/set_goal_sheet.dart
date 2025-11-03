import 'package:flutter/material.dart';
import 'goal_service.dart';

class SetGoalSheet extends StatefulWidget {
  const SetGoalSheet({super.key});

  @override
  State<SetGoalSheet> createState() => _SetGoalSheetState();
}

class _SetGoalSheetState extends State<SetGoalSheet> {
  final _svc = GoalService();
  final _targetCtrl = TextEditingController();
  double? _current;
  int _weeks = 8;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _svc.latestWeight().then((w){ setState(()=>_current = w); });
  }
  @override
  void dispose(){ _targetCtrl.dispose(); super.dispose(); }

  double? get _target => double.tryParse(_targetCtrl.text.replaceAll(',', '.'));

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16, right: 16, top: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(height: 4, width: 44, margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2))),
          Row(
            children: [
              const Expanded(child: Text('Đặt Mục Tiêu Mới', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
              IconButton(onPressed: ()=>Navigator.pop(context), icon: const Icon(Icons.close_rounded))
            ],
          ),
          const SizedBox(height: 6),
          _infoTile('Cân nặng hiện tại', _current != null ? '${_current!.toStringAsFixed(1)} kg' : '—'),
          const SizedBox(height: 10),
          TextField(
            controller: _targetCtrl, keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Cân nặng mục tiêu (kg)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Thời hạn (tuần)'),
              Expanded(
                child: Slider(
                  value: _weeks.toDouble(), min: 1, max: 52, divisions: 51,
                  label: '$_weeks', onChanged: (v)=>setState(()=>_weeks = v.round()),
                ),
              ),
              Text('$_weeks'),
            ],
          ),
          const SizedBox(height: 4),
          if (_current != null && _target != null)
            _hintBox(current: _current!, target: _target!, weeks: _weeks),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: (_current==null || _target==null || _saving)
                  ? null
                  : () async {
                      setState(()=>_saving = true);
                      await _svc.setGoal(
                        currentWeight: _current!, targetWeight: _target!, durationWeeks: _weeks);
                      if (mounted) Navigator.pop(context);
                    },
              child: _saving ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Lưu Mục Tiêu'),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _infoTile(String t, String v) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFF3F5FF),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [ Text(t), Text(v, style: const TextStyle(fontWeight: FontWeight.w700)) ],
    ),
  );

  Widget _hintBox({required double current, required double target, required int weeks}) {
    final need = (target - current); // âm: cần giảm
    final perWeek = (need / weeks);
    final safe = need < 0 ? 'Giảm an toàn: 0.5–1.0 kg/tuần' : 'Tăng an toàn: ~0.25–0.5 kg/tuần';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE8FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(need < 0 ? 'Bạn cần giảm ${need.abs().toStringAsFixed(1)} kg'
                         : 'Bạn cần tăng ${need.abs().toStringAsFixed(1)} kg'),
          const SizedBox(height: 4),
          Text('Tốc độ: ${perWeek.abs().toStringAsFixed(2)} kg/tuần'),
          Text('💡 $safe'),
        ],
      ),
    );
  }
}
