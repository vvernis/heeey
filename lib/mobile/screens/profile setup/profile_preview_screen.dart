import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

class ProfilePreview extends StatelessWidget {
  final String uid;

  const ProfilePreview({super.key, required this.uid});

  Future<Map<String, dynamic>> _fetchProfileData() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
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
        title: const Text('Profile Preview'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
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
          final aboutMe = data['aboutMe'] ?? '';
          final masterCourse = data['masterCourse'] ?? '';
          final mbti = data['mbti'] ?? '';
          final country = data['country'] ?? '';
          final interests = (data['interests'] as List<dynamic>?)
                  ?.map((interest) => interest.toString())
                  .toList() ??
              [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSectionContainer(
                  title: 'Profile Details',
                  children: [
                    _buildDetailRow('About Me:', aboutMe),
                    _buildDetailRow('Master\'s Course:', masterCourse),
                    _buildDetailRow('MBTI:', mbti),
                    _buildDetailRow('Country:', country),
                    _buildDetailRow('Interests:', interests.join(', ')),
                  ],
                ),
                const SizedBox(height: 20),
                _buildSectionContainer(
                  title: 'That\'s Me!',
                  children: [
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
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
                              style: const TextStyle(fontFamily: 'Karla', fontSize: 12),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF911240),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, '/home');
                  },
                  child: const Text(
                    'Go to Home',
                    style: TextStyle(
                      fontFamily: 'Karla',
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionContainer({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Karla',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontFamily: 'Karla', fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'Karla', color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}
