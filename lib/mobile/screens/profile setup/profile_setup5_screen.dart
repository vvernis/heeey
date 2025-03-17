import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:image/image.dart' as img;

const Color darkCharcoal = Color(0xFF29292B);
const Color offBlack = Color(0xFF343436);
const Color vividYellow = Color(0xFFd7ed73);
const Color lightGray = Color(0xFFF0F0E6);


class ProfileSetupStep5 extends StatefulWidget {
  final String uid;
  final String aboutMe;
  final File? profileImage;
  final String? selectedCourse;
  final String? country;
  final List<String> interests;

  const ProfileSetupStep5({
    super.key,
    required this.uid,
    required this.aboutMe,
    this.profileImage,
    this.selectedCourse,
    this.country,
    required this.interests,
  });

  @override
  _ProfileSetupStep5State createState() => _ProfileSetupStep5State();
}

class _ProfileSetupStep5State extends State<ProfileSetupStep5> {
  final ImagePicker _picker = ImagePicker();
  final List<File?> _images = List.generate(9, (_) => null);

  final List<String> _imageFieldNames = [
    'animal',
    'place',
    'color',
    'character',
    'season',
    'sport',
    'food',
    'movie',
    'timeOfDay',
  ];

  final List<String> _captions = [
    'Your favorite animal',
    'A place you love',
    'Your favorite color',
    'A character you relate to',
    'Your favorite season',
    'A sport you enjoy',
    'Your favorite food',
    'Your favorite movie',
    'Your favorite time of day',
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

  Future<void> _pickImage(int index) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _images[index] = File(image.path);
      });
    }
  }

  Future<void> _saveData() async {
    if (_images.any((element) => element == null)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please select all pictures before proceeding.'),
      ),
    );
    return; // Stop further execution if validation fails.
  }
  
    try {
      Map<String, String> base64Images = {};

      for (int i = 0; i < _images.length; i++) {
        if (_images[i] != null) {
          final base64Image = await compressAndConvertToBase64(_images[i]!);
          base64Images[_imageFieldNames[i]] = base64Image;
        } else {
          base64Images[_imageFieldNames[i]] = '';
        }
      }

      await FirebaseFirestore.instance.collection('users').doc(widget.uid).set({
        'images': base64Images,
      }, SetOptions(merge: true));

      Navigator.pushNamed(context, '/home');
      /*
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfilePreview(uid: widget.uid),
        ),
      );*/
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save data: $e')),
      );
    }
  }

  @override
  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Profile Creation'),
        backgroundColor: darkCharcoal,
        iconTheme: const IconThemeData(color: lightGray),
        titleTextStyle: TextStyle(fontFamily: 'Karla', fontSize: 17, fontWeight: FontWeight.bold, color: lightGray),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: lightGray, size: 21,),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
    ),
    body: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
             Text(
                    'Step 5: What defines you?',
                    style: const TextStyle(
                      fontFamily: 'Karla',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: lightGray,
                    ),
              textAlign: TextAlign.center,
            ),
             SizedBox(height: 5),
                Text(
                  "Choose 9 pictures that describes you according to the prompt.",
                  style: TextStyle(
                    fontFamily: 'Karla',
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
            const SizedBox(height: 15),
            GridView.builder(
              physics: const NeverScrollableScrollPhysics(), // Prevent inner scrolling
              shrinkWrap: true, // Ensures GridView takes only necessary space
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.7,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _images.length,
              itemBuilder: (context, index) {
                return Column(
                  children: [
                    GestureDetector(
                      onTap: () => _pickImage(index),
                      child: Container(
                        height: 110,
                        width: 110,
                        decoration: BoxDecoration(
                          color: lightGray,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              spreadRadius: 1,
                              blurRadius: 3,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: _images[index] != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  _images[index]!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Icon(
                                Icons.add_a_photo_outlined,
                                size: 50,
                                color: offBlack,
                              ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _captions[index],
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontFamily: 'Karla', fontSize: 12, color: lightGray),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
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
                'Complete Profile',
                style: TextStyle(
                  fontFamily: 'Karla',
                  color: offBlack,
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