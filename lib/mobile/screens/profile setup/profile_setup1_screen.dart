import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image/image.dart' as img;
import 'profile_setup2_screen.dart';

class ProfileSetupStep1 extends StatefulWidget {
  final String uid;

  const ProfileSetupStep1({super.key, required this.uid});

  @override
  _ProfileSetupStep1State createState() => _ProfileSetupStep1State();
}

class _ProfileSetupStep1State extends State<ProfileSetupStep1> {
  final ImagePicker _picker = ImagePicker();
  File? _profileImage;
  final TextEditingController _aboutMeController = TextEditingController();
  String? _selectedCourse;

  final List<String> _masterCourses = [
    'MSc in Communications Engineering',
    'MSc in Computer Control & Automation',
    'MSc in Electronics',
    'MSc in Power Engineering',
    'MSc in Signal Processing and Machine Learning'
  ];

  Future<String> compressAndConvertToBase64(File file) async {
    try {
      final originalBytes = await file.readAsBytes();
      final originalImage = img.decodeImage(originalBytes);
      if (originalImage == null) throw Exception("Failed to decode the image.");
      final resizedImage = img.copyResize(originalImage, width: 300);
      final compressedBytes = img.encodeJpg(resizedImage, quality: 70);
      return base64Encode(compressedBytes);
    } catch (e) {
      print("Error compressing and encoding image: $e");
      rethrow;
    }
  }

  Future<void> _saveData() async {
    if (_profileImage == null || _aboutMeController.text.isEmpty || _selectedCourse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields.')),
      );
      return;
    }

    try {
      final base64Image = await compressAndConvertToBase64(_profileImage!);

      await FirebaseFirestore.instance.collection('users').doc(widget.uid).set({
        'profilePic': base64Image,
        'aboutMe': _aboutMeController.text,
        'masterCourse': _selectedCourse,
        'uid': widget.uid,
        'role': 'user',
      }, SetOptions(merge: true));

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileSetupStep2(
            uid: widget.uid,
            aboutMe: _aboutMeController.text,
            profileImage: _profileImage,
            selectedCourse: _selectedCourse,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save data: $e')),
      );
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       appBar: AppBar(
        title: const Text('Profile Creation'),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Image Section
            Padding(
              padding: const EdgeInsets.only(top: 20.0, bottom: 20.0),
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 60,
                    backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                    child: _profileImage == null
                        ? const Icon(Icons.add_a_photo, size: 50, color: Colors.black)
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
                  decoration: const InputDecoration(
                    labelText: 'About Me',
                    border: InputBorder.none, 
                    labelStyle: TextStyle(fontFamily: 'Karla', color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)
                  ),
                  maxLines: 3,
                ),
              ),
            ),
            // Dropdown Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: _buildInputContainer(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    labelText: 'Master\'s Course',
                    labelStyle: TextStyle(
                      fontFamily: 'Karla',
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                  isExpanded: true, // Ensures the dropdown expands fully to fit text
                  items: _masterCourses.map((course) {
                    return DropdownMenuItem(
                      value: course,
                      child: Text(
                        course,
                        style: const TextStyle(fontFamily: 'Karla', fontSize: 14),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCourse = value;
                    });
                  },
                ),
              ),
            ),

            // Next Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
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
                    color: Colors.black,
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
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
