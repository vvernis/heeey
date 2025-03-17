import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';


// Define your color constants
const Color darkCharcoal = Color(0xFF29292B);
const Color offBlack = Color(0xFF343436);
const Color vividYellow = Color(0xFFd7ed73);
const Color lightGray = Color(0xFFF0F0E6);


// Updated password regex: 8+ chars, at least one uppercase, one digit, and one special character
final RegExp _passwordRegex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$');

class VerificationWidget extends StatefulWidget {
  const VerificationWidget({super.key});

  @override
  State<VerificationWidget> createState() => _VerificationWidgetState();
}

class _VerificationWidgetState extends State<VerificationWidget> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _newPasswordVisible = false;
  bool _confirmPasswordVisible = false;

  Future<void> setNewPassword() async {
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // Check if passwords match.
    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match.')),
      );
      return;
    }

    // Validate the new password using regex.
    if (!_passwordRegex.hasMatch(newPassword)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Password must be at least 8 characters long and include at least one uppercase letter, one digit, and one special character.',
          ),
        ),
      );
      return;
    }

    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        await user.updatePassword(newPassword);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated successfully.')),
        );

        Navigator.pushNamed(
          context,
          '/profile-setup',
          arguments: {'uid': user.uid},
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No user is signed in.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update password: $e')),
      );
    }
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkCharcoal,
       body: SafeArea(
        child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 26.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 50),
            InkWell(
              onTap: () => Navigator.pop(context),
              child: const Icon(
                Icons.arrow_back,
                color: lightGray,
                size: 21,
              ),
            ),
            const SizedBox(height: 21),
            const Text(
              'Set your password',
              style: TextStyle(
                fontFamily: 'Karla',
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: lightGray,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Account found with your email. Please set up your password.',
              style: TextStyle(
                fontFamily: 'Karla',
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              cursorColor: lightGray,
              controller: _newPasswordController,
              obscureText: !_newPasswordVisible,
              style: TextStyle(color: lightGray),
              decoration: InputDecoration(
                hintText: 'Enter password',
                hintStyle: const TextStyle(
                  fontFamily: 'Karla',
                  color: Color(0xFF747688),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black),
                ),
                focusedBorder:OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: lightGray),
                ), 
                filled: true,
                fillColor: offBlack,
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 20, horizontal: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    color: const Color(0xFF747688),
                    _newPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _newPasswordVisible = !_newPasswordVisible;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              cursorColor: lightGray,
              controller: _confirmPasswordController,
              obscureText: !_confirmPasswordVisible,
              style: TextStyle(color: lightGray),
              decoration: InputDecoration(
                hintText: 'Repeat password',
                hintStyle: const TextStyle(
                  fontFamily: 'Karla',
                  color: Color(0xFF747688),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black),
                ),
                focusedBorder:OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: lightGray),
                ), 
                filled: true,
                fillColor: offBlack,
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 20, horizontal: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    color: const Color(0xFF747688),
                    _confirmPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _confirmPasswordVisible = !_confirmPasswordVisible;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: setNewPassword,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: vividYellow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Sign up',
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
       ),
    );
  }
}
