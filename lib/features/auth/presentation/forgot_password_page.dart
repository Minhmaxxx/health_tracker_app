import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_input.dart';
import '../widgets/primary_button.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _success;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quên mật khẩu'),
        backgroundColor: const Color.fromARGB(255, 241, 92, 142),
      ),
      body: Stack(
        children: [
          // Background image
          Container(
            width: size.width,
            height: size.height,
            child: Opacity(
              opacity: 0.4,
              child: Image.asset(
                'assets/images/background_auth.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Content
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 350), // Add some top spacing
                  CustomInput(
                    label: "Email",
                    controller: _emailCtrl,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                  if (_success != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _success!,
                      style: const TextStyle(color: Colors.green),
                    ),
                  ],
                  const SizedBox(height: 24),
                  PrimaryButton(
                    text: _loading ? "Đang gửi..." : "Gửi email khôi phục",
                    onTap: _loading
                        ? () {}
                        : () async {
                            setState(() {
                              _loading = true;
                              _error = null;
                              _success = null;
                            });

                            try {
                              await FirebaseAuth.instance
                                  .sendPasswordResetEmail(
                                      email: _emailCtrl.text.trim());
                              setState(() {
                                _success = "Email khôi phục đã được gửi!";
                              });
                            } catch (e) {
                              setState(() => _error = e.toString());
                            } finally {
                              setState(() => _loading = false);
                            }
                          },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
