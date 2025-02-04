import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'set_password.dart';

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
      backgroundColor: Colors.white,
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
                color: Colors.black,
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
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Please use the email and temporary password provided by your admin to sign up.',
              style: TextStyle(
                fontFamily: 'Karla',
                color: Color(0xFF747688),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                hintText: 'Email',
                hintStyle: const TextStyle(
                  fontFamily: 'Karla',
                  color: Color(0x9A747688),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE4DFDF)),
                ),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tempPasswordController,
              obscureText: !_tempPasswordVisible,
              decoration: InputDecoration(
                hintText: 'Temporary Password',
                hintStyle: const TextStyle(
                  fontFamily: 'Karla',
                  color: Color(0x9A747688),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
                ),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                suffixIcon: IconButton(
                  icon: Icon(
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
                backgroundColor: Color(0xFF911240),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(
                  fontFamily: 'Karla',
                  color: Colors.white,
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
