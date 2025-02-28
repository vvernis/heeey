import 'package:flutter/material.dart';
import 'community_gallery.dart';
import 'personal_gallery.dart';

const Color darkCharcoal = Color(0xFF29292B);
const Color offBlack = Color(0xFF343436);
const Color vividYellow = Color(0xFFd7ed73);
const Color lightGray = Color(0xFFF0F0E6);



class MemoryGalleryPage extends StatefulWidget {
  const MemoryGalleryPage({super.key});

  @override
  State<MemoryGalleryPage> createState() => _MemoryGalleryPageState();
}

class _MemoryGalleryPageState extends State<MemoryGalleryPage> {
  bool isCommunitySelected = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Memory Gallery',
          style: TextStyle(
            fontFamily: 'Karla',
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: lightGray,
          ),
        ),
        centerTitle: true,
        backgroundColor: darkCharcoal,
        elevation: 0,
        foregroundColor: lightGray,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: lightGray, size: 21),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
           _buildToggleButtons(),
           Expanded(
            child: isCommunitySelected
                ? CommunityGalleryPage()
                : PersonalGalleryPage(),
          )
        ],
      ),
    );
  }

  Widget _buildToggleButtons() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.0),
    child: Container(
      margin: EdgeInsets.symmetric(vertical: 16.0),
      padding: EdgeInsets.all(4), // Padding for the toggle button background
      decoration: BoxDecoration(
        color: offBlack, // Dark background for the toggle section
        borderRadius: BorderRadius.circular(30), // Rounded corners for toggle buttons
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          // Matches Chats Button
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isCommunitySelected ? vividYellow : Colors.transparent, // Highlight color
                foregroundColor: isCommunitySelected ? darkCharcoal: lightGray, // Text color when selected
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                elevation: 0, // Removes shadow
              ),
              onPressed: () {
                setState(() {
                  isCommunitySelected = true;
                });
              },
              child: Text('Community'),
            ),
          ),
          // Challenge Chats Button
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: !isCommunitySelected ? vividYellow: Colors.transparent,
                foregroundColor: isCommunitySelected ? lightGray: darkCharcoal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                elevation: 0,
              ),
              onPressed: () {
                setState(() {
                  isCommunitySelected = false;
                });
              },
              child: Text('Personal'),
            ),
          ),
        ],
      ),
    ),
    );

  }
}