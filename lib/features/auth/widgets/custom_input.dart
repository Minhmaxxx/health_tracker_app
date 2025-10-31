import 'package:flutter/material.dart';

class CustomInput extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final bool obscure;
  final bool isPassword;

  const CustomInput({
    super.key,
    required this.label,
    required this.controller,
    this.obscure = false,
    this.isPassword = false,
  });

  @override
  State<CustomInput> createState() => _CustomInputState();
}

class _CustomInputState extends State<CustomInput> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscure;
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _obscureText,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: const TextStyle(color: Colors.black54),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.black54),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.black54),
        ),
        // Add toggle password visibility button
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off : Icons.visibility,
                  color: Colors.black54,
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              )
            : null,
      ),
    );
  }
}
