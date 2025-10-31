import 'package:flutter/material.dart';
import '../widgets/custom_input.dart';
import '../widgets/primary_button.dart';
import '../data/auth_service.dart';
import 'register_page.dart';
import 'forgot_password_page.dart';
import '../utils/validators.dart';
import '../../home/screens/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;

  // Add error states
  String? _emailError;
  String? _passError;
  String? _generalError;

  Future<bool> _checkEmailVerified() async {
    final user = FirebaseAuth.instance.currentUser;
    await user?.reload();
    return FirebaseAuth.instance.currentUser?.emailVerified ?? false;
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size
    final size = MediaQuery.of(context).size;

    return Scaffold(
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
                  const SizedBox(height: 55),
                  const Text("Health Tracker",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      )),
                  const SizedBox(height: 32),

                  // Email input + error
                  CustomInput(label: "Email", controller: _emailCtrl),
                  if (_emailError != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _emailError!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Password input + error
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

                  // General error
                  if (_generalError != null) ...[
                    Text(
                      _generalError!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                  ],

                  PrimaryButton(
                    text: _loading ? "Loading..." : "Login",
                    onTap: _loading
                        ? () {}
                        : () async {
                            // Clear previous errors
                            setState(() {
                              _emailError = null;
                              _passError = null;
                              _generalError = null;
                            });

                            final email = _emailCtrl.text.trim();
                            final pass = _passCtrl.text;

                            // Validate before setting loading
                            if (!Validators.isValidEmail(email)) {
                              setState(
                                  () => _emailError = "Email không hợp lệ");
                              return;
                            }

                            if (pass.isEmpty) {
                              setState(
                                  () => _passError = "Vui lòng nhập mật khẩu");
                              return;
                            }

                            setState(() => _loading = true);

                            try {
                              await AuthService().signIn(email, pass);
                              if (!mounted) return;

                              // Chuyển thẳng đến HomePage, bỏ phần check email verified
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const HomePage()),
                              );
                            } catch (e) {
                              setState(() => _generalError = e.toString());
                            } finally {
                              if (mounted) setState(() => _loading = false);
                            }
                          },
                  ),

                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterPage()),
                      );
                    },
                    style: TextButton.styleFrom(
                        foregroundColor: const Color.fromARGB(179, 21, 21, 21)),
                    child: const Text("Đăng ký tài khoản mới"),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ForgotPasswordPage()),
                      );
                    },
                    style: TextButton.styleFrom(
                        foregroundColor: const Color.fromARGB(179, 21, 21, 21)),
                    child: const Text("Quên mật khẩu?"),
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
