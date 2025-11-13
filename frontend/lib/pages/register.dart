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
        // Label (e.g., Name, Email, Password)
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
              : (label == 'Email' ? TextInputType.emailAddress : TextInputType.text),
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
      title: 'Registration Form',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFF4F4F4), // Light gray background
      ),
      home: const RegisterPage(), // Use the RegisterPage as the home screen
    );
  }
}

// --- RegisterPage Implementation ---

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // State variables for password visibility
  bool _isPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordObscured = !_isPasswordObscured;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _isConfirmPasswordObscured = !_isConfirmPasswordObscured;
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
              // The white card-like container
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
                  // Title: Create an account
                  const Text(
                    'Create an account',
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // 1. Name Input
                  const LabeledInputField(
                    label: 'Name',
                    hintText: 'Enter your full name',
                    prefixIcon: Icons.person_outline,
                  ),
                  const SizedBox(height: 20),

                  // 2. Email Input
                  const LabeledInputField(
                    label: 'Email',
                    hintText: 'example@vetau.com',
                    prefixIcon: Icons.email_outlined,
                  ),
                  const SizedBox(height: 20),

                  // 3. Password Input
                  LabeledInputField(
                    label: 'Password',
                    hintText: '*********',
                    prefixIcon: Icons.lock_outline,
                    isPassword: true,
                    isObscured: _isPasswordObscured,
                    onToggleVisibility: _togglePasswordVisibility,
                  ),
                  const SizedBox(height: 20),

                  // 4. Confirm Password Input
                  LabeledInputField(
                    label: 'Confirm Password',
                    hintText: '*********',
                    prefixIcon: Icons.lock_outline,
                    isPassword: true,
                    isObscured: _isConfirmPasswordObscured,
                    onToggleVisibility: _toggleConfirmPasswordVisibility,
                  ),
                  const SizedBox(height: 30),

                  // 5. Register Button (Blue)
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        // Registration logic here
                        print('Register Button Pressed');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        elevation: 0, // Removes button shadow for a flat look
                      ),
                      child: const Text(
                        'Register',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 6. Separator 'or'
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

                  // 7. Sign Up with Google Button
                  SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () {
                        // Google Sign-up logic here
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
                          // Using a simple Text icon for the Google logo as assets are unavailable
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
                  const SizedBox(height: 20),

                  // 8. Login link
                  Center(
                    child: TextButton(
                      onPressed: () {
                        // Navigate to login screen
                        Navigator.pushNamed(context, '/login');
                      },
                      child: RichText(                       
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                          children: const [
                            TextSpan(text: 'Already have an account? '),
                            TextSpan(
                              text: 'Login',
                              style: TextStyle(
                                color: primaryBlue, // Highlight the 'Login' text
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