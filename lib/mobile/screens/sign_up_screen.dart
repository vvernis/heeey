import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:heeey/mobile/screens/profile%20setup/profile_setup5_screen.dart';
import 'set_password.dart';

const Color darkCharcoal = Color(0xFF29292B);
const Color offBlack = Color(0xFF343436);
const Color vividYellow = Color(0xFFd7ed73);
const Color lightGray = Color(0xFFF0F0E6);

class SignUpWidget extends StatefulWidget {
  const SignUpWidget({super.key});

  @override
  State<SignUpWidget> createState() => _SignUpWidgetState();
}

class _SignUpWidgetState extends State<SignUpWidget> {
  final _emailController = TextEditingController();
  final _tempPasswordController = TextEditingController();
  bool _tempPasswordVisible = false;

  Future<void> signInWithTemporaryCredentials() async {
    try {
      // Authenticate user with email and temporary password
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _tempPasswordController.text.trim(),
      );

      // Navigate to VerificationWidget
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const VerificationWidget()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sign in failed: $e'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _tempPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkCharcoal,
      body: Padding(
        padding: const EdgeInsets.all(26.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 50),
            InkWell(
              onTap: () => Navigator.pop(context),
              child: const Icon(
                Icons.arrow_back,
                color: lightGray,
                size: 24,
              ),
            ),
            const SizedBox(height: 21),
            const Text(
              'Sign up',
              style: TextStyle(
                fontFamily: 'Karla',
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: lightGray
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Please use the email and temporary password provided by your admin to sign up.',
              style: TextStyle(
                fontFamily: 'Karla',
                color: Color.fromARGB(255, 121, 123, 137),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              cursorColor: lightGray,
              controller: _emailController,
              style: TextStyle(color: lightGray),
              decoration: InputDecoration(
                hintText: 'Email',
                hintStyle: const TextStyle(
                  fontFamily: 'Karla',
                  color: Color(0xFF747688),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE4DFDF)),
                ),
                focusedBorder:OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: lightGray),
                ), 
                filled: true,
                fillColor: offBlack,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              cursorColor: lightGray,
              controller: _tempPasswordController,
              obscureText: !_tempPasswordVisible,
              style: TextStyle(color: lightGray),
              decoration: InputDecoration(
                hintText: 'Temporary Password',
                hintStyle: const TextStyle(
                  fontFamily: 'Karla',
                  color: Color(0xFF747688),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color.fromARGB(255, 255, 255, 255)),
                ),
                focusedBorder:OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: lightGray),
                ), 
                filled: true,
                fillColor: offBlack,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    color: Color(0xFF747688),
                    _tempPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _tempPasswordVisible = !_tempPasswordVisible;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: signInWithTemporaryCredentials,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: vividYellow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(
                  fontFamily: 'Karla',
                  color: darkCharcoal,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
