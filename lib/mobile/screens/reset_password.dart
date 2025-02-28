import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Define your color palette
const Color darkCharcoal = Color(0xFF29292B);
const Color offBlack = Color(0xFF343436);
const Color vividYellow = Color(0xFFd7ed73);
const Color lightGray = Color(0xFFF0F0E6);

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email.')),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent.')),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.message}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong.')),
      );
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkCharcoal,
      appBar: AppBar(
        backgroundColor: darkCharcoal,
        elevation: 0,
        title: const Text(
          'Forgot Password',
          style: TextStyle(
            fontFamily: 'Karla',
            color: lightGray,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: lightGray, size: 21),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Optionally add a logo or an image
              Image.asset(
                'lib/mobile/assets/images/LOGO.png',
                width: 500,
                height: 200,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 24),
              const Text(
                'Enter your email to receive a password reset link.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Karla',
                  fontSize: 16,
                  color: lightGray,
                ),
              ),
              const SizedBox(height: 24),
              // Email Field
              Container(
                decoration: BoxDecoration(
                  color: offBlack,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(
                    fontFamily: 'Karla',
                    color: lightGray,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.email_outlined, color: lightGray),
                    hintText: 'Email',
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
              ),
              const SizedBox(height: 24),
              // Send Reset Email Button
              ElevatedButton(
                onPressed: _isSending ? null : _sendResetEmail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: vividYellow,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isSending
                    ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(offBlack),
                      )
                    : Text(
                        'Send Reset Email',
                        style: TextStyle(
                          color: offBlack,
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
}
