import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/primary_button.dart';
import '../../home/screens/home_screen.dart';

class SetupProfilePage extends StatefulWidget {
  const SetupProfilePage({super.key});

  @override
  State<SetupProfilePage> createState() => _SetupProfilePageState();
}

class _SetupProfilePageState extends State<SetupProfilePage> {
  final _nameCtrl = TextEditingController();
  String? _gender;
  bool _loading = false;
  String? _photoUrl;
  DateTime? _createdAt;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (doc.exists) {
      setState(() {
        _nameCtrl.text = doc.get('displayName') ?? '';
        _gender = doc.get('gender');
        _photoUrl = doc.get('photoUrl');
        _createdAt = (doc.get('createdAt') as Timestamp?)?.toDate();
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_nameCtrl.text.trim().isEmpty || _gender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Cập nhật displayName
      await user.updateDisplayName(_nameCtrl.text.trim());

      // Lưu thông tin vào Firestore
      final data = {
        'displayName': _nameCtrl.text.trim(),
        'gender': _gender,
        'setupCompleted': true,
        'email': user.email,
        'photoUrl': _photoUrl,
      };

      // Chỉ thêm createdAt nếu chưa có
      if (_createdAt == null) {
        data['createdAt'] = FieldValue.serverTimestamp();
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(data, SetOptions(merge: true));

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildAvatarSection() {
    final hasAvatar = _photoUrl != null && _photoUrl!.isNotEmpty;
    final displayName = _nameCtrl.text.trim();
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '';

    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF7F3DFF),
                  image: hasAvatar
                      ? DecorationImage(
                          image: NetworkImage(_photoUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: !hasAvatar && initial.isNotEmpty
                    ? Center(
                        child: Text(
                          initial,
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : null,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFF7F3DFF),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () {
                      // TODO: Implement image picker
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Tính năng đang phát triển'),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              setState(() => _photoUrl = null);
            },
            child: Text(
              hasAvatar ? 'Xóa ảnh' : 'Thêm ảnh đại diện',
              style: TextStyle(
                color: hasAvatar ? Colors.red : Theme.of(context).primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin cá nhân'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // Thêm dòng này
            children: [
              if (_createdAt != null) ...[
                Text(
                  'Ngày tạo: ${_createdAt!.toLocal().toString().split('.')[0]}',
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 24),
              ],
              // Thêm avatar section vào đây
              _buildAvatarSection(),
              const SizedBox(height: 32),
              const Text(
                'Thiết lập hồ sơ',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Vui lòng điền thông tin cơ bản để tiếp tục',
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tên của bạn',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Giới tính',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Nam'),
                      value: 'male',
                      groupValue: _gender,
                      onChanged: (value) => setState(() => _gender = value),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Nữ'),
                      value: 'female',
                      groupValue: _gender,
                      onChanged: (value) => setState(() => _gender = value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32), // Thay Spacer() bằng SizedBox
              PrimaryButton(
                text: _loading ? 'Đang lưu...' : 'Lưu thay đổi',
                onTap: _loading ? () {} : _saveProfile, // Sửa onTap
              ),
              const SizedBox(height: 16), // Thêm padding dưới cùng
            ],
          ),
        ),
      ),
    );
  }
}
