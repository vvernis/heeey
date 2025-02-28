import 'package:flutter/material.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_list_pick/country_list_pick.dart';
import 'profile_setup4_screen.dart';

const Color darkCharcoal = Color(0xFF29292B);
const Color offBlack = Color(0xFF343436);
const Color vividYellow = Color(0xFFd7ed73);
const Color lightGray = Color(0xFFF0F0E6);

class ProfileSetupStep3 extends StatefulWidget {
  final String uid;
  final String aboutMe;
  final File? profileImage;
  final String? selectedCourse;

  const ProfileSetupStep3({
    super.key,
    required this.uid,
    required this.aboutMe,
    this.profileImage,
    this.selectedCourse,
  });

  @override
  _ProfileSetupStep3State createState() => _ProfileSetupStep3State();
}

class _ProfileSetupStep3State extends State<ProfileSetupStep3> {
  String? _selectedCountry;

  Future<void> _saveData() async {
    if (_selectedCountry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a country.')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.uid).set({
        'country': _selectedCountry,
      }, SetOptions(merge: true));

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileSetupStep4(
            uid: widget.uid,
            aboutMe: widget.aboutMe,
            profileImage: widget.profileImage,
            selectedCourse: widget.selectedCourse,
            country: _selectedCountry,
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            Text(
              'Step 3: Where are you from?',
              style: const TextStyle(
                fontFamily: 'Karla',
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: lightGray,
              ),
        ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
              child: _buildInputContainer(
                child: CountryListPick(
                  appBar: AppBar(
                    backgroundColor: Colors.white,
                    title: Text('Select Your Country'),
                    titleTextStyle: TextStyle(color: offBlack, fontSize: 17, fontFamily: "Karla", fontWeight: FontWeight.bold),
                    iconTheme: const IconThemeData(color: offBlack, size: 21),
                  ),
                  theme: CountryTheme(
                    isShowFlag: true,
                    isShowTitle: true,
                    isShowCode: false,
                    isDownIcon: true,
                    showEnglishName: true,
                    
                  //  labelColor: Colors.black,     
                    alphabetSelectedBackgroundColor: offBlack
                  ),
                  initialSelection: '+1',
                  onChanged: (CountryCode? code) {
                    if (code != null) {
                      setState(() {
                        _selectedCountry = code.name;
                      });
                    }
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
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
                        offset: Offset(0, 1),
                      ),
                    ],
      ),
      child: child,
    );
  }
}
