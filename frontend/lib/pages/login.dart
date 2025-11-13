import 'package:flutter/material.dart';

// --- Constants and Custom Widgets (Moved here for clean organization) ---

// Define the primary blue color used for the button
const Color primaryBlue = Color(0xFF4285F4);
const Color secondaryGray = Color(0xFFE0E0E0);
const double cardPadding = 24.0;

// Custom TextField that includes a label and a prefix icon
class LabeledInputField extends StatelessWidget {
  final String label;
  final String hintText;
  final IconData prefixIcon;
  final bool isPassword;
  final bool isObscured;
  final VoidCallback? onToggleVisibility;

  const LabeledInputField({
    super.key,
    required this.label,
    required this.hintText,
    required this.prefixIcon,
    this.isPassword = false,
    this.isObscured = false,
    this.onToggleVisibility,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label (e.g., Email or Username, Password)
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        // Input Field
        TextFormField(
          obscureText: isObscured,
          keyboardType: isPassword
              ? TextInputType.visiblePassword
              : (label.contains('Email') ? TextInputType.emailAddress : TextInputType.text),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey[500]),
            // Rounded border for the whole field
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide(color: secondaryGray, width: 1.0),
            ),
            // Focused border
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: const BorderSide(color: primaryBlue, width: 1.5),
            ),
            // Enabled border
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide(color: secondaryGray, width: 1.0),
            ),
            // Prefix Icon
            prefixIcon: Icon(
              prefixIcon,
              color: Colors.grey[500],
              size: 20,
            ),
            // Suffix Icon (for password visibility toggle)
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
            // Add slight padding inside the field
            contentPadding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 10.0),
          ),
        ),
      ],
    );
  }
}

// --- Main App Setup ---

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login Form',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFF4F4F4), // Light gray background
      ),
      home: const LoginPage(), // Use the LoginPage as the home screen
    );
  }
}

// --- LoginPage Implementation (based on user request) ---

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // State variable for password visibility
  bool _isPasswordObscured = true;

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordObscured = !_isPasswordObscured;
    });
  }

  @override
  Widget build(BuildContext context) {
    // We use a safe area and a scrollable view to handle different screen sizes
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
          child: Center(
            child: Container(
              // The white card-like container (similar to the image background)
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
              constraints: const BoxConstraints(maxWidth: 450), // Limit max width on large screens
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // Logo and App Name ("Vetau")
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Placeholder for a simple logo icon (e.g., a stylized "V" or similar)
                      Icon(Icons.widgets, color: primaryBlue, size: 40),
                      const SizedBox(width: 8),
                      const Text(
                        'Vetau',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // Title: Welcome Back!
                  const Text(
                    'Welcome Back!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // 1. Email or Username Input
                  const LabeledInputField(
                    label: 'Email or Username',
                    hintText: 'Enter your email or username',
                    prefixIcon: Icons.email_outlined,
                  ),
                  const SizedBox(height: 20),

                  // 2. Password Input
                  LabeledInputField(
                    label: 'Password',
                    hintText: 'Enter your password',
                    prefixIcon: Icons.lock_outline,
                    isPassword: true,
                    isObscured: _isPasswordObscured,
                    onToggleVisibility: _togglePasswordVisibility,
                  ),
                  const SizedBox(height: 30),

                  // 3. Login Button (Blue)
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        // Login logic here
                        print('Login Button Pressed');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        elevation: 0, // Removes button shadow for a flat look
                      ),
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 4. Separator 'or'
                  const Center(
                    child: Text(
                      'or',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 5. Sign Up with Google Button
                  SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () {
                        // Google Sign-in logic here
                        print('Google Sign Up Button Pressed');
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        side: BorderSide(color: secondaryGray, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Using a simple Text icon for the Google logo
                          Text(
                            'G',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: primaryBlue.withOpacity(0.8)),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Sign Up with Google',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // 6. Sign Up link
                  Center(
                    child: TextButton(
                      onPressed: () {
                        // Navigate to registration screen
                        Navigator.pushNamed(context, '/');
                      },
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                          children: const [
                            TextSpan(text: "Don't have an account? "),
                            TextSpan(
                              text: 'Sign Up',
                              style: TextStyle(
                                color: primaryBlue, // Highlight the 'Sign Up' text
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
    );
  }
}