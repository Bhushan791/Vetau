import 'package:flutter/material.dart';
import 'package:frontend/config/api_constants.dart';
import 'package:frontend/config/google_oauth_service.dart';
import 'package:frontend/pages/login.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

const Color primaryBlue = Color(0xFF4285F4);
const Color secondaryGray = Color(0xFFE0E0E0);
const double cardPadding = 26.0;
const String apiBaseUrl = ApiConstants.baseUrl;

// ---------------------------
// REUSABLE INPUT FIELD
// ---------------------------
class LabeledInputField extends StatelessWidget {
  final String label;
  final String hintText;
  final IconData prefixIcon;
  final bool isPassword;
  final bool isObscured;
  final VoidCallback? onToggleVisibility;
  final TextEditingController? controller;
  final String? Function(String?)? validator;

  const LabeledInputField({
    super.key,
    required this.label,
    required this.hintText,
    required this.prefixIcon,
    this.isPassword = false,
    this.isObscured = false,
    this.onToggleVisibility,
    this.controller,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isObscured,
          validator: validator,
          keyboardType: isPassword
              ? TextInputType.visiblePassword
              : (label == 'Email'
                  ? TextInputType.emailAddress
                  : TextInputType.text),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: secondaryGray, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: primaryBlue, width: 1.6),
            ),
            prefixIcon: Icon(prefixIcon, size: 21, color: Colors.grey[600]),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      isObscured ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey[600],
                      size: 20,
                    ),
                    onPressed: onToggleVisibility,
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(
                vertical: 16, horizontal: 12),
          ),
        ),
      ],
    );
  }
}

// ---------------------------
// REGISTER PAGE
// ---------------------------
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // VALIDATIONS
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(value)) return 'Please enter a valid email';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  // ---------------------------
  // REGISTER API CALL
  // ---------------------------
  Future<void> registerUser() async {
    var request = http.MultipartRequest("POST", Uri.parse('$apiBaseUrl/users/register/'),);

    request.fields["fullName"] = _nameController.text.trim();
    request.fields["email"] = _emailController.text.trim();
    request.fields["password"] = _passwordController.text.trim();
    request.fields["authType"] = "normal";

    print("Sending fields: ${request.fields}");

    try {
      var response = await request.send();
      String body = await response.stream.bytesToString();

      print("STATUS: ${response.statusCode}");
      print("BODY: $body");

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Registration Successful!")),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => LoginPage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Registration failed: $body")),
        );
      }
    } catch (e) {
      print("Exception: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Something went wrong: $e")),
      );
    }
  }

  // ---------------------------
  // BUTTON HANDLER
  // ---------------------------
  void _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      await registerUser();

      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ---------------------------
  // UI
  // ---------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 34),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(cardPadding),
              constraints: const BoxConstraints(maxWidth: 460),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 18,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Create Your Account",
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 26),

                    LabeledInputField(
                      label: "Full Name",
                      hintText: "Enter your full name",
                      prefixIcon: Icons.person_outline,
                      controller: _nameController,
                      validator: (v) =>
                          v!.isEmpty ? "Name is required" : null,
                    ),
                    const SizedBox(height: 22),

                    LabeledInputField(
                      label: "Email Address",
                      hintText: "example@mail.com",
                      prefixIcon: Icons.email_outlined,
                      controller: _emailController,
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 22),

                    LabeledInputField(
                      label: "Password",
                      hintText: "Enter password",
                      prefixIcon: Icons.lock_outline,
                      isPassword: true,
                      isObscured: _isPasswordObscured,
                      onToggleVisibility: () {
                        setState(() =>
                            _isPasswordObscured = !_isPasswordObscured);
                      },
                      controller: _passwordController,
                      validator: _validatePassword,
                    ),
                    const SizedBox(height: 22),

                    LabeledInputField(
                      label: "Confirm Password",
                      hintText: "Re-enter password",
                      prefixIcon: Icons.lock_outline,
                      isPassword: true,
                      isObscured: _isConfirmPasswordObscured,
                      onToggleVisibility: () {
                        setState(() =>
                            _isConfirmPasswordObscured = !_isConfirmPasswordObscured);
                      },
                      controller: _confirmPasswordController,
                      validator: _validateConfirmPassword,
                    ),
                    const SizedBox(height: 32),

                    // Register Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white))
                            : const Text(
                                "Register",
                                style: TextStyle(
                                    fontSize: 17, fontWeight: FontWeight.w700),
                              ),
                      ),
                    ),
                    const SizedBox(height: 25),

                    const Center(
                      child: Text(
                        "or",
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Google Signup
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () {
                          GoogleOAuthService.openGoogleLogin(context);
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade300, width: 1.4),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "G",
                              style: TextStyle(
                                color: primaryBlue,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              "Sign Up with Google",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => LoginPage()),
                          );
                        },
                        child: const Text(
                          "Already have an account? Login",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: primaryBlue,
                            fontSize: 14.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
