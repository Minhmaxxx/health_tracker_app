import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/custom_input.dart';
import '../widgets/primary_button.dart';
import '../data/auth_service.dart';
import '../utils/validators.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;

  String? _emailError;
  String? _passError;
  String? _generalError;

  @override
  Widget build(BuildContext context) {
    // Get screen size
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng ký tài khoản'),
        backgroundColor: const Color.fromARGB(255, 241, 92, 142),
      ),
      body: Stack(
        children: [
          // Background image with opacity
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
          // Content with scrolling
          SingleChildScrollView(
            child: Container(
              width: size.width,
              height: size.height,
              padding: const EdgeInsets.all(36),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Email input + inline error
                  CustomInput(label: "Email", controller: _emailCtrl),
                  if (_emailError != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _emailError!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Password input + inline error
                  CustomInput(
                    label: "Password",
                    controller: _passCtrl,
                    obscure: true,
                    isPassword: true,
                  ),
                  if (_passError != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _passError!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // General error (optional)
                  if (_generalError != null) ...[
                    Text(
                      _generalError!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                  ],

                  PrimaryButton(
                    text: _loading ? "Loading..." : "Register",
                    onTap: _loading
                        ? () {}
                        : () async {
                            // Clear previous errors
                            setState(() {
                              _emailError = null;
                              _passError = null;
                              _generalError = null;
                            });

                            // Validate BEFORE setting loading to true
                            final email = _emailCtrl.text.trim();
                            final pass = _passCtrl.text;

                            if (!Validators.isValidEmail(email)) {
                              setState(
                                  () => _emailError = "Email không hợp lệ");
                              return; // do NOT set loading
                            }

                            if (!Validators.isValidPassword(pass)) {
                              setState(() => _passError =
                                  "Mật khẩu phải ≥6 ký tự, gồm chữ hoa, chữ thường, số và ký tự đặc biệt");
                              return; // do NOT set loading
                            }

                            // All validation passed -> show loading and call auth
                            setState(() => _loading = true);
                            try {
                              await AuthService().register(email, pass);
                              if (!mounted) return;

                              // Thêm SnackBar thông báo thành công
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text("Đăng ký tài khoản thành công!"),
                                  backgroundColor: Colors.green,
                                  duration: Duration(seconds: 2),
                                ),
                              );

                              // Đợi 1 chút để người dùng thấy thông báo rồi mới pop
                              await Future.delayed(const Duration(seconds: 2));
                              if (!mounted) return;
                              Navigator.pop(context);
                            } catch (e) {
                              setState(() => _generalError = e.toString());
                            } finally {
                              if (mounted) setState(() => _loading = false);
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

  Future<void> _createUserProfile(String uid, String email) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
      'displayName': '',
      'photoUrl': null,
    });
  }

  Future<void> _sendVerificationEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }
}
