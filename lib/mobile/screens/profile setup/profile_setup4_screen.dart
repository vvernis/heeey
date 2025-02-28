import 'package:flutter/material.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_setup5_screen.dart';

const Color darkCharcoal = Color(0xFF29292B);
const Color offBlack = Color(0xFF343436);
const Color vividYellow = Color(0xFFd7ed73);
const Color lightGray = Color(0xFFF0F0E6);

class ProfileSetupStep4 extends StatefulWidget {
  final String uid;
  final String aboutMe;
  final File? profileImage;
  final String? selectedCourse;
  final String? country;

  const ProfileSetupStep4({
    super.key,
    required this.uid,
    required this.aboutMe,
    this.profileImage,
    this.selectedCourse,
    this.country,
  });

  @override
  _ProfileSetupStep4State createState() => _ProfileSetupStep4State();
}

class _ProfileSetupStep4State extends State<ProfileSetupStep4> {
  final List<String> _interests = [
    'Travel',
    'Music',
    'Food',
    'Games',
    'Sports',
    'Movies',
    'Adventure',
    'Nature',
    'Art',
    'Photography',
    'Books',
    'Technology',
    'Fitness',
    'Cooking',
    'Fashion',
    'Finance',
    'Science',
  ];

  final Map<String, IconData> interestIcons = {
  'Travel': Icons.flight,
  'Music': Icons.music_note,
  'Food': Icons.restaurant,
  'Games': Icons.videogame_asset,
  'Sports': Icons.sports_soccer,
  'Movies': Icons.movie,
  'Adventure': Icons.explore,
  'Nature': Icons.nature_people,
  'Art': Icons.brush,
  'Photography': Icons.camera_alt,
  'Books': Icons.book,
  'Technology': Icons.computer,
  'Fitness': Icons.fitness_center,
  'Cooking': Icons.kitchen,
  'Fashion': Icons.checkroom,
  'Finance': Icons.attach_money,
  'Science': Icons.science,
};

  final List<String> _selectedInterests = [];

  Future<void> _saveData() async {
    if (_selectedInterests.length < 3 || _selectedInterests.length > 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select between 3 and 6 interests.'),
        ),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.uid).set({
        'interests': _selectedInterests,
      }, SetOptions(merge: true));

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileSetupStep5(
            uid: widget.uid,
            aboutMe: widget.aboutMe,
            profileImage: widget.profileImage,
            selectedCourse: widget.selectedCourse,
            country: widget.country,
            interests: _selectedInterests,
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 20.0, bottom: 10.0),
            child: Column(
              children: const [
                 Text(
                    'Step 4: Select your interests.',
                    style: TextStyle(
                      fontFamily: 'Karla',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: lightGray,
                    ),
              ),
                SizedBox(height: 5),
                Text(
                  "Please select min. of 3 and max. of 6 to proceed.",
                  style: TextStyle(
                    fontFamily: 'Karla',
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _interests.map((interest) {
                  return ChoiceChip(
                    avatar: Icon(
                      interestIcons[interest],
                      color: _selectedInterests.contains(interest) ? Colors.white : lightGray,
                    ),
                    label: Text(interest),
                    selected: _selectedInterests.contains(interest),
                    onSelected: (isSelected) {
                      setState(() {
                        if (isSelected && _selectedInterests.length < 6) {
                          _selectedInterests.add(interest);
                        } else {
                          _selectedInterests.remove(interest);
                        }
                      });
                    },
                    selectedColor: vividYellow,
                    backgroundColor: offBlack,
                    labelStyle: TextStyle(
                      fontFamily: 'Karla',
                      color: _selectedInterests.contains(interest)
                          ? offBlack
                          : lightGray,
                    ),
                    side: BorderSide.none,
                  );
                }).toList(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
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
                'Continue',
                style: TextStyle(
                  fontFamily: 'Karla',
                  color: darkCharcoal,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
