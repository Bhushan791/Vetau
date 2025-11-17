import 'package:flutter/material.dart';
import 'package:frontend/config/api_constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// --- Constants ---
const Color primaryBlue = Color(0xFF4285F4);
const Color secondaryGray = Color(0xFFE0E0E0);
const double cardPadding = 24.0;
// API Endpoints based on user request
const String apiBaseUrl = ApiConstants.baseUrl;



// --- Custom TextField Widget (Adapted for simplicity and consistency) ---
class LabeledInputField extends StatelessWidget {
  final String label;
  final String hintText;
  final IconData prefixIcon;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final bool obscureText;

  const LabeledInputField({
    super.key,
    required this.label,
    required this.hintText,
    required this.prefixIcon,
    this.controller,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
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
          validator: validator,
          keyboardType: keyboardType,
          obscureText: obscureText,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16),
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
            contentPadding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 10.0),
          ),
        ),
      ],
    );
  }
}

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;
  bool _otpSent = false;
  String? _statusMessage;
  Color _statusColor = primaryBlue;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validateOtp(String? value) {
    if (value == null || value.isEmpty) {
      return 'OTP is required';
    }
    if (value.length != 6 || !RegExp(r'^\d+$').hasMatch(value)) {
      return 'OTP must be a 6-digit number';
    }
    return null;
  }

  Future<void> _sendOtp() async {
    // Only validate email here
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSendingOtp = true;
      _statusMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/forgot-password/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': _emailController.text.trim(),
        }),
      );

      if (!mounted) return;

      setState(() {
        _isSendingOtp = false;
      });

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        setState(() {
          _otpSent = true;
          _statusMessage = responseData['message'] ?? 'OTP sent successfully to your email.';
          _statusColor = Colors.green;
        });
      } else {
        final errorData = jsonDecode(response.body);
        setState(() {
          _statusMessage = errorData['message'] ?? 'Failed to send OTP. Please try again.';
          _statusColor = Colors.red;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSendingOtp = false;
        _statusMessage = 'Network error. Please check your connection and server status.';
        _statusColor = Colors.red;
      });
    }
  }

  Future<void> _verifyOtp() async {
    // Validate both email and OTP
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isVerifyingOtp = true;
      _statusMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/verify-reset-otp/'),
        headers: {
          'Content-Type': 'application/json',
        },
        // The user provided a sample body for the request.
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'otp': _otpController.text.trim(),
        }),
      );

      if (!mounted) return;

      setState(() {
        _isVerifyingOtp = false;
      });

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        setState(() {
          _statusMessage = responseData['message'] ?? 'OTP verified. You can now reset your password.';
          _statusColor = Colors.green;
        });

        // NOTE: In a real app, successful verification would navigate the user
        // to a new screen where they can enter their new password.
        // Navigator.of(context).pushReplacementNamed('/reset-password');
      } else {
        final errorData = jsonDecode(response.body);
        setState(() {
          _statusMessage = errorData['message'] ?? 'OTP verification failed. Please check your OTP.';
          _statusColor = Colors.red;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isVerifyingOtp = false;
        _statusMessage = 'Network error. Please check your connection and server status.';
        _statusColor = Colors.red;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Matches the back button and title style from the screenshot
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Forgot Password',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(cardPadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Instruction Text
                const Text(
                  'Enter your email and the OTP verification code to reset your password.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 30),

                // Email Input
                LabeledInputField(
                  label: 'Email Address',
                  hintText: 'example@vetau.com',
                  prefixIcon: Icons.email_outlined,
                  controller: _emailController,
                  validator: _validateEmail,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),

                // Send OTP Button
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSendingOtp ? null : _sendOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      disabledBackgroundColor: Colors.grey[300],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      elevation: 0,
                    ),
                    child: _isSendingOtp
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _otpSent ? 'Resend OTP' : 'Send OTP',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 30),
                
                // OTP Input
                LabeledInputField(
                  label: 'OTP Verification Code',
                  hintText: 'Enter 6-digit OTP',
                  prefixIcon: Icons.vpn_key_outlined,
                  controller: _otpController,
                  validator: _validateOtp,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),

                // Verify OTP Button
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isVerifyingOtp ? null : _verifyOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      disabledBackgroundColor: Colors.grey[300],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      elevation: 0,
                    ),
                    child: _isVerifyingOtp
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Verify OTP',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                // Info Box (Matching screenshot's visual style)
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(color: Colors.orange.shade200, width: 1.0),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange.shade700,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'If you don\'t receive OTP in your email please click on send OTP after few seconds.',
                          style: TextStyle(
                            color: Color(0xFFC04F00), // Darker orange/brown for contrast
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Display Status Message
                if (_statusMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Text(
                      _statusMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}