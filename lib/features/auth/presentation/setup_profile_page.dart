import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import '../widgets/primary_button.dart';

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
  final _picker = ImagePicker();
  bool _uploading = false;

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

  Future<void> _pickImage(ImageSource source) async {
    try {
      if (kIsWeb) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tính năng chưa hỗ trợ trên web')),
        );
        return;
      }

      final image = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (image == null) return;

      setState(() => _uploading = true);

      // Upload ảnh lên Firebase Storage
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final ref = FirebaseStorage.instance
          .ref()
          .child('avatars')
          .child('${user.uid}.jpg');

      await ref.putFile(File(image.path));
      final url = await ref.getDownloadURL();

      // Cập nhật photoURL trong Auth và Firestore
      await user.updatePhotoURL(url);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'photoUrl': url});

      setState(() {
        _photoUrl = url;
        _uploading = false;
      });
    } catch (e) {
      setState(() => _uploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    }
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Chụp ảnh mới'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Chọn từ thư viện'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
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
                    icon: _uploading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                    onPressed: _uploading ? null : _showImagePicker,
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

  Future<void> _updateAvatar() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    try {
      setState(() => _loading = true);

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not found');

      // Delete old avatar if exists
      try {
        await FirebaseStorage.instance.ref('users/$userId/avatar.jpg').delete();
      } catch (e) {
        // Ignore if old file doesn't exist
      }

      // Upload new avatar
      final ref = FirebaseStorage.instance.ref('users/$userId/avatar.jpg');
      await ref.putFile(File(image.path));

      // Get download URL
      final url = await ref.getDownloadURL();

      // Update user profile
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'avatar': url});

      setState(() => _photoUrl = url);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật ảnh đại diện thành công')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
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
