import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../auth/presentation/setup_profile_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _range = '7 Ngày';
  final _ranges = const ['7 Ngày', '14 Ngày', '30 Ngày'];
  final String displayName = '';

  @override
  Widget build(BuildContext context) {
    final displayName = FirebaseAuth.instance.currentUser?.displayName ?? 'Bạn';
    final now = TimeOfDay.now();
    final isMorning = now.hour < 12;
    final isAfternoon = now.hour >= 12 && now.hour < 18;
    final greeting = isMorning
        ? 'Chào buổi sáng, $displayName'
        : (isAfternoon
            ? 'Chào buổi chiều, $displayName'
            : 'Chào buổi tối, $displayName');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser?.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      final photoUrl = snapshot.data?['photoUrl'] as String?;
                      final displayName =
                          snapshot.data?['displayName'] as String? ?? 'Bạn';
                      final initial = displayName.isNotEmpty
                          ? displayName[0].toUpperCase()
                          : 'B';

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SetupProfilePage()),
                          );
                        },
                        child: photoUrl != null && photoUrl.isNotEmpty
                            ? CircleAvatar(
                                radius: 18,
                                backgroundImage: NetworkImage(photoUrl),
                              )
                            : Container(
                                width: 36,
                                height: 36,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF7F3DFF),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  initial,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(greeting,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            )),
                        const SizedBox(height: 2),
                        const Text('Hôm nay bạn thế nào?',
                            style: TextStyle(color: Colors.black54)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.notifications_active_rounded),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SetupProfilePage()),
                      );
                    },
                    icon: const Icon(Icons.settings_rounded),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // BMI card
              _GradientCard(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7F3DFF), Color(0xFF5A81F7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CHỈ SỐ BMI CỦA BẠN',
                        style: TextStyle(
                          color: Colors.white,
                          letterSpacing: 1.1,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        )),
                    const SizedBox(height: 14),
                    const Text(
                      'Nhập chiều cao & cân nặng để tính BMI',
                      style: TextStyle(color: Colors.white, fontSize: 15),
                    ),
                    const SizedBox(height: 14),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF5A68FF),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      onPressed: () {
                        // TODO: Navigator.pushNamed(context, '/bmi_calculator');
                      },
                      child: const Text('Bắt Đầu'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Weekly weight & dropdown
              _SectionCard(
                title: 'Cân Nặng Tuần Này',
                trailing: _RangeDropdown(
                  value: _range,
                  items: _ranges,
                  onChanged: (v) => setState(() => _range = v),
                ),
                child: _EmptyChart(
                  onAddWeight: () {
                    // TODO: Navigator.pushNamed(context, '/weight_add');
                  },
                ),
              ),

              const SizedBox(height: 14),

              // Quick actions grid
              GridView(
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.85,
                ),
                children: [
                  _QuickAction(
                    colors: const [Color(0xFF2FD3C7), Color(0xFF38BDF8)],
                    icon: Icons.monitor_weight_rounded,
                    label: 'CÂN NẶNG',
                    subtitle: 'Cập nhật hôm nay',
                    onTap: () {
                      // TODO: Navigator.pushNamed(context, '/weight_add');
                    },
                  ),
                  _QuickAction(
                    colors: const [Color(0xFFFF5A8A), Color(0xFFFF7A59)],
                    icon: Icons.flag_rounded,
                    label: 'MỤC TIÊU',
                    subtitle: 'Chưa đặt mục tiêu',
                    onTap: () {
                      // TODO: Navigator.pushNamed(context, '/goals');
                    },
                  ),
                  _QuickAction(
                    colors: const [Color(0xFF7C3AED), Color(0xFF5B21B6)],
                    icon: Icons.support_agent_rounded,
                    label: 'TƯ VẤN',
                    subtitle: 'Hỏi về dinh dưỡng, luyện tập',
                    onTap: () {
                      // TODO: Navigator.pushNamed(context, '/coach');
                    },
                  ),
                  _QuickAction(
                    colors: const [Color(0xFFFFA000), Color(0xFFFF6F00)],
                    icon: Icons.receipt_long_rounded,
                    label: 'LỊCH SỬ',
                    subtitle: 'Xem tất cả lần đo trước',
                    onTap: () {
                      // TODO: Navigator.pushNamed(context, '/history');
                    },
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Health tip
              const _GradientCard(
                gradient: LinearGradient(
                  colors: [Color(0xFF7F3DFF), Color(0xFF5A81F7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_rounded,
                        color: Colors.white, size: 28),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Mẹo Sức Khỏe Hôm Nay\n'
                        'Uống 6–8 cốc nước mỗi ngày, thêm 20–30 phút đi bộ nhẹ để tăng chuyển hoá.',
                        style: TextStyle(color: Colors.white, height: 1.35),
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

  Widget _avatarCircle() {
    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF7F3DFF),
      ),
      alignment: Alignment.center,
      child: const Text('B',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }
}

/// Simple gradient card
class _GradientCard extends StatelessWidget {
  final Gradient gradient;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _GradientCard({
    required this.gradient,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: padding,
      child: child,
    );
  }
}

/// Section wrapper with title + trailing widget (dropdown)
class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      child: Column(
        children: [
          Row(
            children: [
              Text(title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  )),
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

/// Empty chart placeholder like screenshot
class _EmptyChart extends StatelessWidget {
  final VoidCallback onAddWeight;

  const _EmptyChart({required this.onAddWeight});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F3FA),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bar_chart_rounded,
                size: 44, color: Colors.black26),
            const SizedBox(height: 6),
            const Text('Chưa có dữ liệu',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            const Text('Thêm cân nặng để xem biểu đồ',
                style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: onAddWeight,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Thêm cân nặng'),
            )
          ],
        ),
      ),
    );
  }
}

/// Dropdown used in header of "Cân nặng tuần này"
class _RangeDropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  const _RangeDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        borderRadius: BorderRadius.circular(12),
        items: items
            .map((e) => DropdownMenuItem<String>(
                  value: e,
                  child: Text(e),
                ))
            .toList(),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
        icon: const Icon(Icons.keyboard_arrow_down_rounded),
      ),
    );
  }
}

/// Quick action card (2x2 grid)
class _QuickAction extends StatelessWidget {
  final List<Color> colors;
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickAction({
    required this.colors,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Colors.white24,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(8),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .2)),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, height: 1.2),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
