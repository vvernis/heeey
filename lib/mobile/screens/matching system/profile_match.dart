import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:typed_data';

const Color darkCharcoal = Color(0xFF29292B);
const Color offBlack = Color(0xFF343436);
const Color vividYellow = Color(0xFFd7ed73);
const Color lightGray = Color(0xFFF0F0E6);


class ProfileMatchWidget extends StatefulWidget {
  final String uid;

  const ProfileMatchWidget({super.key, required this.uid});

  @override
  _ProfileMatchWidgetState createState() => _ProfileMatchWidgetState();
}

class _ProfileMatchWidgetState extends State<ProfileMatchWidget> {
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
        backgroundColor: darkCharcoal,
        titleTextStyle: TextStyle(fontSize: 17, fontFamily: 'Karla', fontWeight: FontWeight.bold),
        iconTheme: const IconThemeData(color: lightGray),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: lightGray, size: 21),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
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
          final uid = data['uid'] ?? 'Unknown user id';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                _buildHeader(data,uid),

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

   Future<int> fetchActiveChallenges(String uid) async {
  // Groups where the user is a member and status is pending or rejected.
  QuerySnapshot query = await FirebaseFirestore.instance
      .collection('groups')
      .where('members', arrayContains: uid)
      .where('status', whereIn: ['pending', 'rejected'])
      .get();
  return query.docs.length;
}

Future<int> fetchCompletedChallenges(String uid) async {
  // Groups where the user is a member and status is approved.
  QuerySnapshot query = await FirebaseFirestore.instance
      .collection('groups')
      .where('members', arrayContains: uid)
      .where('status', isEqualTo: 'approved')
      .get();
  return query.docs.length;
}

Future<int> fetchSuccessfulMatches(String uid) async {
  // Count accepted matchRequests where the user is sender or receiver.
  QuerySnapshot senderQuery = await FirebaseFirestore.instance
      .collection('matchRequests')
      .where('status', isEqualTo: 'accepted')
      .where('senderId', isEqualTo: uid)
      .get();

  QuerySnapshot receiverQuery = await FirebaseFirestore.instance
      .collection('matchRequests')
      .where('status', isEqualTo: 'accepted')
      .where('receiverId', isEqualTo: uid)
      .get();

  return senderQuery.docs.length + receiverQuery.docs.length;
}

Widget _buildHeader(Map<String, dynamic> data, String uid) {
  // Extract fields
  final profilePicBase64 = data['profilePic'] ?? '';
  final name = data['name'] ?? 'Unknown';
  final course = data['mastercourse'] ?? 'Master’s Y1 Student';
  final birthday = data['birthday'] ?? 'N/A';
  final aboutMe = data['aboutMe'] ?? '';


  // Decode profile picture
  Uint8List? profilePicBytes;
  if (profilePicBase64.isNotEmpty) {
    try {
      profilePicBytes = base64Decode(profilePicBase64);
    } catch (_) {}
  }

  return FutureBuilder<List<int>>(
    future: Future.wait([
      fetchActiveChallenges(uid),
      fetchCompletedChallenges(uid),
      fetchSuccessfulMatches(uid),
    ]),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final results = snapshot.data!;
      final active = results[0];
      final completed = results[1];
      final successful = results[2];


  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Use IntrinsicHeight so the left & right containers match in height
      IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left: Profile Picture container
            Expanded(
              flex: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[300],
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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: profilePicBytes != null
                      ? Image.memory(
                          profilePicBytes,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.person, color: Colors.grey),
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Right: Name, course, birthday, about me
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.all(12),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      name,
                      style: const TextStyle(
                        fontFamily: 'Karla',
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: lightGray,
                      ),
                    ),
                    // Course row with icon
                    Row(
                      children: [
                        Icon(Icons.school_outlined, size: 14, color: Colors.grey[300]),
                        const SizedBox(width: 4),
                        Text(
                          course,
                          style: TextStyle(
                            fontFamily: 'Karla',
                            fontSize: 12,
                            color: Colors.grey[300],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Birthday row
                    Row(
                      children: [
                        Icon(Icons.cake, size: 14, color: Colors.grey[300]),
                        const SizedBox(width: 4),
                        Text(
                          birthday,
                          style: TextStyle(
                            fontFamily: 'Karla',
                            fontSize: 12,
                            color: Colors.grey[300],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // About Me label
                    Text(
                      'About Me',
                      style: TextStyle(
                        fontFamily: 'Karla',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[300],
                      ),
                    ),
                    // About Me text
                    Text(
                      aboutMe,
                      style: TextStyle(
                        fontFamily: 'Karla',
                        fontSize: 12,
                        color: Colors.grey[300],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      const SizedBox(height: 16),

      // Achievements container
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF343436), // offBlack
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Achievements label
            Row(
              children: const [
                Text(
                  'Progress',
                  style: TextStyle(
                    fontFamily: 'Karla',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: lightGray,
                  ),
                ),
                SizedBox(width: 4),
                Text('🏆', style: TextStyle(fontSize: 14)),
              ],
            ),
            const SizedBox(height: 8),
            
            IntrinsicHeight(
              child: 
            // Row of achievements
            Row(
             
              children: [
                // Active Challenges
                Expanded(
  child: Container(
    height: 90,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: darkCharcoal,
      border: Border.all(color: darkCharcoal),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Stack(

      children: [
        // Top-left: label
        const Positioned(
          top: 0,
          left: 0,
          child: Text(
            'Active\nChallenges',
            style: TextStyle(
              fontFamily: 'Karla',
              fontSize: 12,
              color: lightGray,
            ),
          ),
        ),
        // Bottom-right: number
        Positioned(
          bottom: 0,
          right: 0,
          child: Text(
            '$active',
            style: const TextStyle(
              fontFamily: 'Karla',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: vividYellow,
            ),
          ),
        ),
      ],
    ),
  ),
),

                 const SizedBox(width: 10),
                // Completed Challenges
                Expanded(
  child: Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: darkCharcoal,
      border: Border.all(color: darkCharcoal),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Stack(
      children: [
        // Top-left: label
        const Positioned(
          top: 0,
          left: 0,
          child: Text(
            'Completed\nChallenges',
            style: TextStyle(
              fontFamily: 'Karla',
              fontSize: 12,
              color: lightGray,
            ),
          ),
        ),
        // Bottom-right: number
        Positioned(
          bottom: 0,
          right: 0,
          child: Text(
            '$completed',
            style: const TextStyle(
              fontFamily: 'Karla',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: vividYellow,
            ),
          ),
        ),
      ],
    ),
  ),
),

                 const SizedBox(width: 10),
                // Successful Matches
                  Expanded(
  child: Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: darkCharcoal,
      border: Border.all(color: darkCharcoal),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Stack(
      children: [
        // Top-left: label
        const Positioned(
          top: 0,
          left: 0,
          child: Text(
            'Successful\nMatches',
            style: TextStyle(
              fontFamily: 'Karla',
              fontSize: 12,
              color: lightGray,
            ),
          ),
        ),
        // Bottom-right: number
        Positioned(
          bottom: 0,
          right: 0,
          child: Text(
            '$successful',
            style: const TextStyle(
              fontFamily: 'Karla',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: vividYellow,
            ),
          ),
        ),
      ],
    ),
  ),
),
              ]
            ),
            ),
          ],
        ),
      ),
    ],
  );
    }
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
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profile Card',
          style: const TextStyle(
            fontFamily: 'Karla',
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: lightGray,
          ),
        ),
        const SizedBox(height: 16),
        IntrinsicHeight(
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.stretch, // Make children stretch to fill the row height
    children: [
      Expanded(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: darkCharcoal,
            border: Border.all(color: darkCharcoal),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const SizedBox(width: 13),
              Image.asset(
                imagePath,
                height: 36,
                width: 36,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
              ),
              const SizedBox(width: 5),
              Text(
                data['mbti'] ?? 'N/A',
                style: const TextStyle(
                  fontFamily: 'Karla',
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: lightGray,
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: darkCharcoal,
            border: Border.all(color: darkCharcoal),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              data['country'] ?? 'N/A',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Karla',
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: lightGray,
              ),
            ),
          ),
        ),
      ),
    ],
  ),
),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.only(top: 10, left: 10, right: 10),
          decoration: BoxDecoration(
              color: darkCharcoal,
              border: Border.all(color: darkCharcoal),
              borderRadius: BorderRadius.circular(8),
            ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "That's ME",
                style: const TextStyle(
                  fontFamily: 'Karla',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: lightGray,
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
                  childAspectRatio: 0.95,
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
                      const SizedBox(height: 1),
                      Text(
                        category,
                        style: const TextStyle(fontFamily: 'Karla', fontSize: 11, color: lightGray),
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
              color: darkCharcoal,
              border: Border.all(color: darkCharcoal),
              borderRadius: BorderRadius.circular(8),
            ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'My Interests',
        style: const TextStyle(
          fontFamily: 'Karla',
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: lightGray,
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
              color: offBlack,
              border: Border.all(color: darkCharcoal),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              interests[index],
              style: const TextStyle(fontFamily: 'Karla', fontSize: 12, color: lightGray),
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