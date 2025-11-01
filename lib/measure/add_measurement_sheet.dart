import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddMeasurementSheet extends StatefulWidget {
  const AddMeasurementSheet({super.key});

  @override
  State<AddMeasurementSheet> createState() => _AddMeasurementSheetState();
}

class _AddMeasurementSheetState extends State<AddMeasurementSheet> {
  final _formKey = GlobalKey<FormState>();
  final _wCtrl = TextEditingController();
  final _hCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _wCtrl.dispose();
    _hCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  double _calcBMI(double wKg, double hCm) {
    final hM = hCm / 100.0;
    if (hM <= 0) return 0;
    return double.parse((wKg / (hM * hM)).toStringAsFixed(1));
  }

  String _bmiCategory(double bmi) {
    if (bmi == 0) return '—';
    if (bmi < 18.5) return 'Thiếu cân';
    if (bmi < 23) return 'Bình thường';
    if (bmi < 25) return 'Thừa cân';
    return 'Béo phì';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final weight = double.parse(_wCtrl.text.trim().replaceAll(',', '.'));
      final height = double.parse(_hCtrl.text.trim().replaceAll(',', '.'));
      final bmi = _calcBMI(weight, height);
      final category = _bmiCategory(bmi);

      final db = FirebaseFirestore.instance;

      // 1) Ghi lịch sử
      await db.collection('weights').doc(uid).collection('entries').add({
        'weight': weight,
        'height': height,
        'bmi': bmi,
        'note': _noteCtrl.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 2) Cập nhật nhanh để Home hiển thị hiện trạng
      await db.collection('users').doc(uid).set({
        'latest': {
          'weight': weight,
          'height': height,
          'bmi': bmi,
          'category': category,
          'updatedAt': FieldValue.serverTimestamp(),
        }
      }, SetOptions(merge: true));

      if (mounted) Navigator.of(context).pop(); // đóng sheet
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi lưu số đo: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final radius = const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    );
    return Material(
      shape: radius,
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 4, width: 44,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                    color: Colors.black12, borderRadius: BorderRadius.circular(2)),
              ),
              Row(
                children: [
                  const Expanded(
                    child: Text('Cập Nhật Số Đo',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
              const SizedBox(height: 6),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _wCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Cân nặng (kg) *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final x = double.tryParse((v ?? '').replaceAll(',', '.'));
                        if (x == null || x <= 0) return 'Nhập cân nặng hợp lệ';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _hCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Chiều cao (cm)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final x = double.tryParse((v ?? '').replaceAll(',', '.'));
                        if (x == null || x < 80 || x > 250) return 'Nhập chiều cao hợp lệ';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _noteCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Ghi chú (tuỳ chọn)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _saving ? null : _save,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _saving
                            ? const SizedBox(
                                height: 20, width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Lưu Số Đo'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
