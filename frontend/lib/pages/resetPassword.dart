import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/config/api_constants.dart';

class ResetPasswordPage extends StatefulWidget {
  final String email;

  const ResetPasswordPage({super.key, required this.email});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool obscurePass = true;
  bool obscureConfirm = true;
  bool loading = false;
  String statusMessage = "";
  Color statusColor = Colors.red;

  Future<void> updatePassword() async {
    String pass = passwordController.text.trim();
    String confirm = confirmPasswordController.text.trim();

    if (pass.isEmpty || confirm.isEmpty) {
      setState(() {
        statusMessage = "Please fill in both fields";
        statusColor = Colors.red;
      });
      return;
    }

    if (pass != confirm) {
      setState(() {
        statusMessage = "Passwords do not match!";
        statusColor = Colors.red;
      });
      return;
    }

    setState(() => loading = true);

    try {
      final response = await http.post(
        Uri.parse("${ApiConstants.baseUrl}/users/reset-password"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": widget.email,
          "newPassword": pass,
        }),
      );

      setState(() => loading = false);

      if (response.statusCode == 200) {
        setState(() {
          statusMessage = "Password updated successfully!";
          statusColor = Colors.green;
        });

        // Navigate back to login after success
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.popUntil(context, (route) => route.isFirst);
        });
      } else {
        final error = jsonDecode(response.body);
        setState(() {
          statusMessage = error["message"] ?? "Something went wrong";
          statusColor = Colors.red;
        });
      }
    } catch (e) {
      setState(() {
        loading = false;
        statusMessage = "Network error. Try again.";
        statusColor = Colors.red;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            const Text(
              "Set a new password",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Create a new password. Ensure it differs from previous ones for security",
              style: TextStyle(fontSize: 15, color: Colors.black54),
            ),

            const SizedBox(height: 25),

            const Text("Password",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),

            // Password Field
            TextField(
              controller: passwordController,
              obscureText: obscurePass,
              decoration: InputDecoration(
                hintText: "Enter your new password",
                filled: true,
                fillColor: Colors.grey.shade100,
                suffixIcon: IconButton(
                  icon: Icon(
                    obscurePass ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() => obscurePass = !obscurePass);
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text("Confirm Password",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),

            // Confirm Password Field
            TextField(
              controller: confirmPasswordController,
              obscureText: obscureConfirm,
              decoration: InputDecoration(
                hintText: "Re-enter password",
                filled: true,
                fillColor: Colors.grey.shade100,
                suffixIcon: IconButton(
                  icon: Icon(
                    obscureConfirm ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() => obscureConfirm = !obscureConfirm);
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Update Password Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: loading ? null : updatePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2970FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: loading
                    ? const CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2)
                    : const Text(
                        "Update Password",
                        style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w600),
                      ),
              ),
            ),

            const SizedBox(height: 20),

            if (statusMessage.isNotEmpty)
              Center(
                child: Text(
                  statusMessage,
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
