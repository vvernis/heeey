import 'package:flutter/material.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_list_pick/country_list_pick.dart';
import 'profile_setup4_screen.dart';

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
        title: const Text('Where are you from?'),
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
                child: CountryListPick(
                  appBar: AppBar(
                    backgroundColor: Colors.pink,
                    title: Text('Select Your Country'),
                  ),
                  theme: CountryTheme(
                    isShowFlag: true,
                    isShowTitle: true,
                    isShowCode: false,
                    isDownIcon: true,
                    showEnglishName: true,
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
                  backgroundColor: const Color(0xFF911240),
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
