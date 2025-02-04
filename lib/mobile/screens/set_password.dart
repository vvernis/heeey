import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    if (_newPasswordController.text.trim() !=
        _confirmPasswordController.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match.')),
      );
      return;
    }

    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        await user.updatePassword(_newPasswordController.text.trim());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated successfully.')),
        );

        Navigator.pushNamed(context, '/profile-setup', arguments: {'uid': user.uid}, );
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
              'Set your password',
              style: TextStyle(
                fontFamily: 'Karla',
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Account found with your email. Please set up your password.',
              style: TextStyle(
                fontFamily: 'Karla',
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _newPasswordController,
              obscureText: !_newPasswordVisible,
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
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                suffixIcon: IconButton(
                  icon: Icon(
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
              controller: _confirmPasswordController,
              obscureText: !_confirmPasswordVisible,
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
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                suffixIcon: IconButton(
                  icon: Icon(
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
                backgroundColor: const Color(0xFF6A0DAD),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Sign up',
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
