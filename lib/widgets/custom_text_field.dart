//ignore_for_file: prefer_const_constructors, avoid_print, use_build_context_synchronously,deprecated_member_use, prefer_const_literals_to_create_immutables, unnecessary_null_comparison, avoid_unnecessary_containers, prefer_interpolation_to_compose_strings, unused_local_variable, prefer_final_fields, prefer_typing_uninitialized_variables, avoid_print, unnecessary_new, prefer_const_constructors_in_immutables

import 'package:flutter/material.dart';
// Assuming you have a custom theme

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final bool obscureText;
  final String? Function(String?)? validator;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.hintText,
    this.obscureText = false,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      validator: validator,
    );
  }
}
