import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginPageWidget extends StatefulWidget {
  const LoginPageWidget({super.key});

  @override
  State<LoginPageWidget> createState() => _LoginPageWidgetState();
}

class _LoginPageWidgetState extends State<LoginPageWidget> {
  final _emailOrUsernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _passwordVisible = false;

  Future<void> loginUser() async {
    try {
      String emailOrUsername = _emailOrUsernameController.text.trim();
      String password = _passwordController.text.trim();

      String? email;
      if (isValidEmail(emailOrUsername)) {
        // If it's an email, use it directly
        email = emailOrUsername;
      } else {
        // If it's a username (from the 'name' field), fetch the corresponding email
        email = await getEmailFromUsername(emailOrUsername);
        if (email == null) {
          throw 'No user found with this username.';
        }
      }

      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        if (userCredential.user!.metadata.creationTime ==
            userCredential.user!.metadata.lastSignInTime) {
          // First login - Prompt password reset
          Navigator.pushNamed(context, '/reset-password');
        } else {
          // Proceed to profile setup or home
          Navigator.pushNamed(context, '/home');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
      );
    }
  }

  Future<String?> getEmailFromUsername(String name) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('name', isEqualTo: name) // Query the 'name' field
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first['email'] as String?;
      }
    } catch (e) {
      debugPrint('Error fetching email from name: $e');
    }
    return null;
  }

  bool isValidEmail(String input) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(input);
  }

  @override
  void dispose() {
    _emailOrUsernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 50.0), // Adjust the value to move it down
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'lib/mobile/assets/images/LOGO.png',
                    width: 300, // Adjust as needed
                    height: 300, // Adjust as needed
                    fit: BoxFit.contain,
                  ),
                ]
              )
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.6, // Adjust the height as needed
              decoration: BoxDecoration(
                color: Color(0xFFF3D9EE),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(50),
                  topRight: Radius.circular(50),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 45.0, vertical: 75.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Center(
                      child: Text(
                        "Login",
                        style: TextStyle(
                          fontFamily: 'Karla',
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF911240),
                        ),
                      ),
                    ),
                    // Email or Username Input
                    _buildTextField(
                      controller: _emailOrUsernameController,
                      hintText: 'Email or Username',
                      obscureText: false,
                      icon: Icons.person_outline,
                    ),
                    // Password Input
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
                        ),
                        onPressed: () {
                          setState(() {
                            _passwordVisible = !_passwordVisible;
                          });
                        },
                      ),
                    ),
                    // Buttons
                    Column(
                      children: [
                        ElevatedButton(
                          onPressed: loginUser,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            backgroundColor: Color(0xFF911240),
                          ),
                          child: const Text(
                            'Sign in',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Karla',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/create-account');
                          },
                          child: const Text(
                            'Create Account',
                            style: TextStyle(color: Colors.blueAccent, fontFamily: 'Karla'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
      width: 350,
      height: 50,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 255, 255, 255),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 25,
                    spreadRadius: 10,
                  ),
        ]
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        textAlign: TextAlign.left,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.grey),
          suffixIcon: suffixIcon,
          hintText: hintText,
          contentPadding: EdgeInsets.fromLTRB(0, 10, 0, 10),
          hintStyle: TextStyle(
            fontFamily: 'Karla',
            color: Colors.grey.shade700,
          ),
          
          border: InputBorder.none,
          
        ),
      ),
    );
  }
}
