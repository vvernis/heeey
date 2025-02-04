import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

class ProfileWidget extends StatefulWidget {
  final String uid;

  const ProfileWidget({super.key, required this.uid});

  @override
  _ProfileWidgetState createState() => _ProfileWidgetState();
}

class _ProfileWidgetState extends State<ProfileWidget> {
  Future<Map<String, dynamic>> _fetchProfileData() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('users').doc(widget.uid).get();
    if (snapshot.exists) {
      return snapshot.data()!;
    } else {
      throw Exception('Profile not found');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchProfileData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final data = snapshot.data!;
          final images = (data['images'] as Map).cast<String, String>();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                _buildHeader(data),

                const SizedBox(height: 16),

                // Profile Card Section
                _buildProfileCard(data, images)
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),  // Shadow color with transparency
                  spreadRadius: 1,  // Extend the shadow outward
                  blurRadius: 10,   // Blur radius to soften the shadow
                  offset: Offset(0, 4),  // Offset in x, y direction to give an elevated effect
                ),
              ],
        ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: MemoryImage(base64Decode(data['profilePic'])),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['name']?.toUpperCase() ?? 'Unknown',
                  style: TextStyle(
                    fontFamily: 'Karla',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  )
                ),
                Text(
                  data['masterCourse'] ?? '',
                  style: TextStyle(fontFamily: 'Karla', fontSize: 11, color: Colors.black),
                ),
                const SizedBox(height: 8),
                Text('About Me', style: TextStyle(fontFamily: 'Karla', fontSize: 12, fontWeight: FontWeight.bold),),
                Text(
                  data['aboutMe'] ?? '',
                  style: TextStyle(fontFamily: 'Karla', fontSize: 12, color: Colors.black),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.black),
            onPressed: () {
              Navigator.pushNamed(context, '/profile-setup');
            },
          ),
        ],
      ),
    );
  }
Widget _buildProfileCard(Map<String, dynamic> data, Map<String, String> images) {
  final interests = (data['interests'] as List).cast<String>();
  String? mbti = data['mbti']; 
  String imagePath = 'lib/mobile/assets/images/mbti/$mbti.png'; 
  print(imagePath);

  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.5),
          spreadRadius: 1,
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profile Card',
          style: const TextStyle(
            fontFamily: 'Karla',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 13),
                     Image.asset(
                        imagePath,
                        height: 36,
                        width: 36,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(Icons.error)
                      ),
                      const SizedBox(width: 5),
                    Text(
                      data['mbti'] ?? 'N/A',
                      style: const TextStyle(
                        fontFamily: 'Karla',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 5),
                    const Icon(Icons.flag, size: 25, color: Colors.black),
                    const SizedBox(height: 5),
                    Text(
                      data['country'] ?? 'N/A',
                      style: const TextStyle(
                        fontFamily: 'Karla',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.only(top: 10, left: 10, right: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "That's ME",
                style: const TextStyle(
                  fontFamily: 'Karla',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 5),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 15),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 2,
                  mainAxisSpacing: 2,
                ),
                itemCount: images.keys.length,
                itemBuilder: (context, index) {
                  final category = images.keys.elementAt(index);
                  final base64Image = images[category]!;
                  final imageBytes = base64Decode(base64Image);

                  return Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(
                          imageBytes,
                          height: 80,
                          width: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        category,
                        style: const TextStyle(fontFamily: 'Karla', fontSize: 12, color: Colors.black),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
       Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.grey.withOpacity(0.5),
        spreadRadius: 1,
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'My Interests',
        style: const TextStyle(
          fontFamily: 'Karla',
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      const SizedBox(height: 16),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, // 3 items per row
          crossAxisSpacing: 8, // Space between columns
          mainAxisSpacing: 8, // Space between rows
          childAspectRatio: 2.5, // Controls width-to-height ratio
        ),
        itemCount: interests.length,
        itemBuilder: (context, index) {
          return Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              interests[index],
              style: const TextStyle(fontFamily: 'Karla', fontSize: 12, color: Colors.black),
            ),
          );
        },
      ),
    ],
  ),
)
      ],
    ),
  );
}

}