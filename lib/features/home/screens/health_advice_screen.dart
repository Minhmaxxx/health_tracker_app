import 'package:flutter/material.dart';
import '../../../gemini_service.dart';

class HealthAdviceScreen extends StatefulWidget {
  const HealthAdviceScreen({super.key});

  @override
  State<HealthAdviceScreen> createState() => _HealthAdviceScreenState();
}

class _HealthAdviceScreenState extends State<HealthAdviceScreen> {
  final _controller = TextEditingController();
  String _response = '';
  final service = GeminiService("AIzaSyBlSdsBW8yo8-CU-hUDyELcAnlYhvjETgs");

  final userProfile = {
    "age": 25,
    "weight": 58,
    "height": 165,
    "activity": "vừa phải",
  };

  void _getAdvice() async {
    setState(() => _response = "Đang tư vấn...");
    final res = await service.advise(userProfile, _controller.text);
    setState(() => _response = res);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tư vấn sức khỏe")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: "Nhập câu hỏi của bạn...",
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _getAdvice,
              child: const Text("Nhận tư vấn"),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(child: Text(_response)),
            ),
          ],
        ),
      ),
    );
  }
}
