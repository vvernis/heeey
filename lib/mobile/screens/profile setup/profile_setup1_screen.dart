import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart'; // For formatting date
import 'profile_setup2_screen.dart';

// Your color constants
const Color darkCharcoal = Color(0xFF29292B);
const Color offBlack     = Color(0xFF343436);
const Color vividYellow  = Color(0xFFd7ed73);
const Color lightGray    = Color(0xFFF0F0E6);

class ProfileSetupStep1 extends StatefulWidget {
  final String uid;

  const ProfileSetupStep1({Key? key, required this.uid}) : super(key: key);

  @override
  _ProfileSetupStep1State createState() => _ProfileSetupStep1State();
}

class _ProfileSetupStep1State extends State<ProfileSetupStep1> {
  final ImagePicker _picker = ImagePicker();
  File? _profileImage;

  // Controllers
  final TextEditingController _aboutMeController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();

  // Compress & encode image to base64
  Future<String> compressAndConvertToBase64(File file) async {
    try {
      final originalBytes = await file.readAsBytes();
      final originalImage = img.decodeImage(originalBytes);
      if (originalImage == null) throw Exception("Failed to decode the image.");
      // Resize & compress
      final resizedImage = img.copyResize(originalImage, width: 300);
      final compressedBytes = img.encodeJpg(resizedImage, quality: 70);
      return base64Encode(compressedBytes);
    } catch (e) {
      debugPrint("Error compressing and encoding image: $e");
      rethrow;
    }
  }

  // Pick an image from gallery
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
    }
  }

  // Show a calendar picker for birthday
  Future<void> _pickBirthday() async {
  final DateTime? pickedDate = await showDatePicker(
    context: context,
    initialDate: DateTime(2000),   // Default to year 2000
    firstDate: DateTime(1900),     // Earliest allowed date
    lastDate: DateTime.now(),      // Latest allowed date (today)
    builder: (context, child) {
      return Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.dark(
            primary: vividYellow,      // header background color
            onPrimary: darkCharcoal,   // header text color
            surface: offBlack,         // background color of the picker
            onSurface: lightGray,      // body text (dates) color
          ),
          dialogBackgroundColor: darkCharcoal,
        ),
        child: child!,
      );
    },
  );
  if (pickedDate != null) {
    setState(() {
      _birthdayController.text = DateFormat('dd.MM.yyyy').format(pickedDate);
    });
  }
}


  // Save data to Firestore & navigate
  Future<void> _saveData() async {
    if (_profileImage == null ||
        _aboutMeController.text.isEmpty ||
        _birthdayController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields.')),
      );
      return;
    }

    try {
      final base64Image = await compressAndConvertToBase64(_profileImage!);

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .set({
        'profilePic': base64Image,
        'aboutMe': _aboutMeController.text,
        'birthday': _birthdayController.text, // Storing the birthday
        'uid': widget.uid,
        'role': 'user',
      }, SetOptions(merge: true));

      // Navigate to next step
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileSetupStep2(
            uid: widget.uid,
            aboutMe: _aboutMeController.text,
            profileImage: _profileImage,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save data: $e')),
      );
    }
  }

  @override
  void dispose() {
    _aboutMeController.dispose();
    _birthdayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Creation'),
        titleTextStyle: TextStyle(
          fontFamily: 'Karla',
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: lightGray,
        ),
        backgroundColor: darkCharcoal,
        iconTheme: const IconThemeData(color: lightGray),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: lightGray,
            size: 21,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: darkCharcoal,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 20, bottom: 20),
        child: Column(
          children: [
            const Text(
              'Step 1: Tell us more about yourself.',
              style: TextStyle(
                fontFamily: 'Karla',
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: lightGray,
              ),
            ),
            // Profile Image Section
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    backgroundColor: lightGray,
                    radius: 60,
                    backgroundImage: _profileImage != null
                        ? FileImage(_profileImage!)
                        : null,
                    child: _profileImage == null
                        ? const Icon(Icons.add_a_photo_outlined,
                            size: 40, color: offBlack)
                        : null,
                  ),
                ),
              ),
            ),
            // About Me Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              child: _buildInputContainer(
                child: TextField(
                  controller: _aboutMeController,
                  style: const TextStyle(color: lightGray, fontSize: 14),
                  decoration: const InputDecoration(
                    labelText: 'About Me',
                    hintText: 'E.g. "I love hiking, cooking, and discovering new music!"',
                    border: InputBorder.none,
                    labelStyle: TextStyle(
                      fontFamily: 'Karla',
                      color: lightGray,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    hintStyle: TextStyle(
                      fontFamily: 'Karla',
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                  maxLines: 3,
                ),
              ),
            ),
            // Birthday Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              child: _buildInputContainer(
                child: TextField(
                  controller: _birthdayController,
                  readOnly: true, // so the user taps to pick date
                  style: const TextStyle(color: lightGray, fontSize: 14),
                  decoration: const InputDecoration(
                    labelText: 'Birthday',
                    border: InputBorder.none,
                    labelStyle: TextStyle(
                      fontFamily: 'Karla',
                      color: lightGray,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  onTap: _pickBirthday, // Open the date picker
                ),
              ),
            ),
            // Next Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: vividYellow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: _saveData,
                child: const Text(
                  'Next',
                  style: TextStyle(
                    fontFamily: 'Karla',
                    color: offBlack,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: offBlack,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );
  }
}
