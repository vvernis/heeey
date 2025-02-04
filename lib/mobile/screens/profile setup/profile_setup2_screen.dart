import 'package:flutter/material.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_setup3_screen.dart';

class ProfileSetupStep2 extends StatefulWidget {
  final String uid;
  final String aboutMe;
  final File? profileImage;
  final String? selectedCourse;

  const ProfileSetupStep2({
    super.key,
    required this.uid,
    required this.aboutMe,
    this.profileImage,
    this.selectedCourse,
  });

  @override
  _ProfileSetupStep2State createState() => _ProfileSetupStep2State();
}

class _ProfileSetupStep2State extends State<ProfileSetupStep2> {
  String? selectedMbti;
  String? mbtiDescription;
  String? mbtiImage;

  final Map<String, Map<String, String>> mbtiDetails = {
  'INTJ': {
    'description': 'Imaginative and strategic thinkers, with a plan for everything.',
    'image': 'lib/mobile/assets/images/mbti/INTJ.png'
  },
  'INTP': {
    'description': 'Innovative inventors with an unquenchable thirst for knowledge.',
    'image': 'lib/mobile/assets/images/mbti/INTP.png'
  },
  'ENTJ': {
    'description': 'Bold, imaginative and strong-willed leaders, always finding a way - or making one.',
    'image': 'lib/mobile/assets/images/mbti/ENTJ.png'
  },
  'ENTP': {
    'description': 'Smart and curious thinkers who cannot resist an intellectual challenge.',
    'image': 'lib/mobile/assets/images/mbti/ENTP.png'
  },
  'INFJ': {
    'description': 'Quiet and mystical, yet very inspiring and tireless idealists.',
    'image': 'lib/mobile/assets/images/mbti/INFJ.png'
  },
  'INFP': {
    'description': 'Poetic, kind and altruistic people, always eager to help a good cause.',
    'image': 'lib/mobile/assets/images/mbti/INFP.png'
  },
  'ENFJ': {
    'description': 'Charismatic and inspiring leaders, able to mesmerize their listeners.',
    'image': 'lib/mobile/assets/images/mbti/ENFJ.png'
  },
  'ENFP': {
    'description': 'Enthusiastic, creative and sociable free spirits, who can always find a reason to smile.',
    'image': 'lib/mobile/assets/images/mbti/ENFP.png'
  },
  'ISTJ': {
    'description': 'Practical and fact-minded individuals, whose reliability cannot be doubted.',
    'image': 'lib/mobile/assets/images/mbti/ISTJ.png'
  },
  'ISFJ': {
    'description': 'Very dedicated and warm protectors, always ready to defend their loved ones.',
    'image': 'lib/mobile/assets/images/mbti/ISFJ.png'
  },
  'ESTJ': {
    'description': 'Excellent administrators, unsurpassed at managing things – or people.',
    'image': 'lib/mobile/assets/images/mbti/ESTJ.png'
  },
  'ESFJ': {
    'description': 'Extraordinarily caring, social and popular people, always eager to help.',
    'image': 'lib/mobile/assets/images/mbti/ESFJ.png'
  },
  'ISTP': {
    'description': 'Bold and practical experimenters, masters of all kinds of tools.',
    'image': 'lib/mobile/assets/images/mbti/ISTP.png'
  },
  'ISFP': {
    'description': 'Flexible and charming artists, always ready to explore and experience something new.',
    'image': 'lib/mobile/assets/images/mbti/ISFP.png'
  },
  'ESTP': {
    'description': 'Smart, energetic and very perceptive people, who truly enjoy living on the edge.',
    'image': 'lib/mobile/assets/images/mbti/ESTP.png'
  },
  'ESFP': {
    'description': 'Spontaneous, energetic and enthusiastic people – life is never boring around them.',
    'image': 'lib/mobile/assets/images/mbti/ESFP.png'
  }
};


  final List<String> mbtiTypes = [
    'INTJ', 'INTP', 'ENTJ', 'ENTP',
    'INFJ', 'INFP', 'ENFJ', 'ENFP',
    'ISTJ', 'ISFJ', 'ESTJ', 'ESFJ',
    'ISTP', 'ISFP', 'ESTP', 'ESFP',
    'I don\'t know',
  ];

  Future<void> saveData() async {
    if (selectedMbti == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your MBTI.')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.uid).set({
        'mbti': selectedMbti,
      }, SetOptions(merge: true));

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileSetupStep3(
            uid: widget.uid,
            aboutMe: widget.aboutMe,
            profileImage: widget.profileImage,
            selectedCourse: widget.selectedCourse,
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
        title: const Text('What is your MBTI?'),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
              child: _buildInputContainer(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Select Your MBTI',
                    labelStyle: TextStyle(
                      fontFamily: 'Karla',
                      color: Color(0xFF911240),
                      fontWeight: FontWeight.bold,
                      fontSize: 14
                    ),
                    border: InputBorder.none,
                  ),
                  isExpanded: true,
                  items: mbtiTypes.map((mbti) {
                    return DropdownMenuItem(
                      value: mbti,
                      child: Text(
                        mbti,
                        style: const TextStyle(fontFamily: 'Karla', fontSize: 14),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedMbti = value;
                      mbtiDescription = mbtiDetails[selectedMbti]?['description'];
                      mbtiImage = mbtiDetails[selectedMbti]?['image'];
                    });
                  },
                ),
              ),
            ),
            if (mbtiImage != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Image.asset(mbtiImage!),
                    if (mbtiDescription != null)
                      Text(mbtiDescription!, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Karla')),
                      Text('(Taken from 16personalities.com)', style: const TextStyle(fontFamily: 'Karla', fontSize: 10, fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF911240),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: saveData,
                child: const Text(
                  'Next',
                  style: TextStyle(
                    fontFamily: 'Karla',
                    color: Colors.white,
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
        color: Colors.white,
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
