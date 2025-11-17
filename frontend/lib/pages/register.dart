import 'package:flutter/material.dart';
import 'package:frontend/config/api_constants.dart';
import 'package:frontend/config/google_oauth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

const Color primaryBlue = Color(0xFF4285F4);
const Color secondaryGray = Color(0xFFE0E0E0);
const double cardPadding = 24.0;
const String apiBaseUrl = ApiConstants.baseUrl;

// ---------------------------
// Labeled Input Field
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
            fontSize: 14,
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
              : (label == 'Email' ? TextInputType.emailAddress : TextInputType.text),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey[500]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide(color: secondaryGray, width: 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: const BorderSide(color: primaryBlue, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide(color: secondaryGray, width: 1.0),
            ),
            prefixIcon: Icon(
              prefixIcon,
              color: Colors.grey[500],
              size: 20,
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      isObscured ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                      size: 20,
                    ),
                    onPressed: onToggleVisibility,
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 10.0),
          ),
        ),
      ],
    );
  }
}

// ---------------------------
// Register Page
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

  // ---------------------------
  // VALIDATIONS
  // ---------------------------
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
  // SHARED PREFERENCES SAVE
  // ---------------------------
  Future<void> _saveUserData({
    required String token,
    required String fullName,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('fullName', fullName);
    await prefs.setString('email', email);
  }

  // ---------------------------
  // REGISTER API CALL
  // ---------------------------
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/users/register/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullName': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
          'authType': 'normal',
        }),
      );

      setState(() => _isLoading = false);

      final data = jsonDecode(response.body);

      print('STATUS: ${response.statusCode}');
      print('BODY: $data');

      if (response.statusCode == 201) {
        // Save token and user info
        await _saveUserData(
          token: data['accessToken'],
          fullName: data['user']['fullName'],
          email: data['user']['email'],
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful!'), backgroundColor: Colors.green),
        );

        // Clear form
        _nameController.clear();
        _emailController.clear();
        _passwordController.clear();
        _confirmPasswordController.clear();

        // Navigate to home after delay
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pushReplacementNamed(context, '/home');
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Registration failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ---------------------------
  // BUILD UI
  // ---------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
          child: Center(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 5,
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(cardPadding),
              constraints: const BoxConstraints(maxWidth: 450),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const Text(
                      'Create an account',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 30),

                    // Name
                    LabeledInputField(
                      label: 'Name',
                      hintText: 'Enter your full name',
                      prefixIcon: Icons.person_outline,
                      controller: _nameController,
                      validator: (value) => value!.isEmpty ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 20),

                    // Email
                    LabeledInputField(
                      label: 'Email',
                      hintText: 'example@vetau.com',
                      prefixIcon: Icons.email_outlined,
                      controller: _emailController,
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 20),

                    // Password
                    LabeledInputField(
                      label: 'Password',
                      hintText: '*********',
                      prefixIcon: Icons.lock_outline,
                      isPassword: true,
                      isObscured: _isPasswordObscured,
                      onToggleVisibility: () {
                        setState(() => _isPasswordObscured = !_isPasswordObscured);
                      },
                      controller: _passwordController,
                      validator: _validatePassword,
                    ),
                    const SizedBox(height: 20),

                    // Confirm Password
                    LabeledInputField(
                      label: 'Confirm Password',
                      hintText: '*********',
                      prefixIcon: Icons.lock_outline,
                      isPassword: true,
                      isObscured: _isConfirmPasswordObscured,
                      onToggleVisibility: () {
                        setState(() => _isConfirmPasswordObscured = !_isConfirmPasswordObscured);
                      },
                      controller: _confirmPasswordController,
                      validator: _validateConfirmPassword,
                    ),
                    const SizedBox(height: 30),

                    // Register Button
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          disabledBackgroundColor: Colors.grey[300],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                strokeWidth: 2,
                              )
                            : const Text(
                                'Register',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Center(child: Text('or', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500))),
                    const SizedBox(height: 20),

                    // Google Button (UI only, backend integration can be added later)
                    // Google Sign Up Button
                    SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () {
                          GoogleOAuthService.openGoogleLogin(context); // 🚀 Start Google Auth
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          side: BorderSide(color: secondaryGray, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'G',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryBlue.withOpacity(0.8)),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Sign Up with Google',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Login link
                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/login');
                        },
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                            children: const [
                              TextSpan(text: 'Already have an account? '),
                              TextSpan(text: 'Login', style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
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
