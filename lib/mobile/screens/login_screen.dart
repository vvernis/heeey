import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Your color theme
const Color darkCharcoal = Color(0xFF29292B);
const Color offBlack = Color(0xFF343436);
const Color vividYellow = Color(0xFFd7ed73);
const Color lightGray = Color(0xFFF0F0E6);

class LoginPageWidget extends StatefulWidget {
  const LoginPageWidget({super.key});

  @override
  State<LoginPageWidget> createState() => _LoginPageWidgetState();
}

class _LoginPageWidgetState extends State<LoginPageWidget> {
  final _emailOrUsernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _passwordVisible = false;

  @override
  void dispose() {
    _emailOrUsernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Example function for "Forgot Password"
  void _forgotPassword() {
    Navigator.pushNamed(context, '/forgot-password');
  }

  Future<void> loginUser() async {
  try {
    final input = _emailOrUsernameController.text.trim();
    final password = _passwordController.text.trim();

    String email;
    if (input.contains('@')) {
      // Input is an email, so use it directly.
      email = input;
    } else {
      // Input is just the local part (e.g., "vaw002").
      // Query Firestore for a user whose email begins with that string.
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isGreaterThanOrEqualTo: input)
          .where('email', isLessThanOrEqualTo: input + '\uf8ff')
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final userData = querySnapshot.docs.first.data() as Map<String, dynamic>;
        email = userData['email'] as String? ?? '';
        if (email.isEmpty) {
          throw 'No email found for this username.';
        }
      } else {
        throw 'No user found with this username.';
      }
    }

    final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (userCredential.user != null) {
      final user = userCredential.user!;
      if (user.metadata.creationTime == user.metadata.lastSignInTime) {
        Navigator.pushNamed(context, '/reset-password');
      } else {
        Navigator.pushNamed(context, '/home');
      }
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Login failed: $e')),
    );
  }
}

  // Fetch email from Firestore by matching 'name' field
  Future<String?> _getEmailFromUsername(String name) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('name', isEqualTo: name)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first['email'] as String?;
      }
    } catch (e) {
      debugPrint('Error fetching email from username: $e');
    }
    return null;
  }

  bool _isValidEmail(String input) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(input);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkCharcoal,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Minimalistic logo area
              Image.asset(
                'lib/mobile/assets/images/LOGO.png',
                width: 500,
                height: 200,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                'Login',
                style: TextStyle(
                  fontFamily: 'Karla',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: lightGray,
                ),
              ),
              const SizedBox(height: 24),

              // Email or Username Field
              _buildTextField(
                controller: _emailOrUsernameController,
                hintText: 'Email or Username',
                obscureText: false,
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 16),

              // Password Field
              _buildTextField(
                controller: _passwordController,
                hintText: 'Password',
                obscureText: !_passwordVisible,
                icon: Icons.lock_outline,
                suffixIcon: IconButton(
                  icon: Icon(
                    _passwordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: lightGray,
                  ),
                  onPressed: () {
                    setState(() {
                      _passwordVisible = !_passwordVisible;
                    });
                  },
                ),
              ),
              const SizedBox(height: 8),

              // Forgot password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _forgotPassword,
                  child: Text(
                    'Forgot Password?',
                    style: TextStyle(
                      fontFamily: 'Karla',
                      color: vividYellow,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Sign In Button
              ElevatedButton(
                onPressed: loginUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: vividYellow,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Sign in',
                  style: TextStyle(
                    color: offBlack,
                    fontFamily: 'Karla',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Create Account
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/create-account');
                },
                child: Text(
                  'Create Account',
                  style: TextStyle(
                    color: lightGray,
                    fontFamily: 'Karla',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required bool obscureText,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: offBlack,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        cursorColor: lightGray,
        controller: controller,
        obscureText: obscureText,
        style: TextStyle(
          fontFamily: 'Karla',
          color: lightGray,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: lightGray),
          suffixIcon: suffixIcon,
          hintText: hintText,
          hintStyle: TextStyle(
            fontFamily: 'Karla',
            color: lightGray.withOpacity(0.6),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 16,
          ),
        ),
      ),
    );
  }
}
