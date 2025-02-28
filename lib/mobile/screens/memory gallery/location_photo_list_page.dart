import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:heeey/mobile/screens/memory%20gallery/personal_gallery.dart';
import 'dart:convert';
import 'dart:typed_data';

import '../../../shared/memory_gallery_map.dart'; // For the GalleryItem model

class LocationPhotoListPage extends StatelessWidget {
  final GalleryItem location;
  const LocationPhotoListPage({Key? key, required this.location}) : super(key: key);

  static const double tolerance = 0.001;

  // Reverse-geocoding method to get place name from lat/lng
  Future<String> _getPlaceName(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return place.name ?? 'Unknown Place';
      }
    } catch (e) {
      debugPrint("Error in reverse geocoding: $e");
    }
    return 'Unknown Place';
  }

  /// Fetch challenge name, group name, user name, and decode the first image from the doc.
  Future<Map<String, dynamic>> _fetchSubmissionDetails(Map<String, dynamic> docData) async {
    String challengeName = 'Unknown Challenge';
    String groupName = 'Unknown Group';
    String userName = 'Unknown User';
    Uint8List? imageBytes;

    // 1) Challenge name
    final challengeDocId = docData['challengeDocId'] as String?;
    if (challengeDocId != null) {
      final challengeSnap = await FirebaseFirestore.instance
          .collection('challenges')
          .doc(challengeDocId)
          .get();
      if (challengeSnap.exists) {
        final cData = challengeSnap.data()!;
        challengeName = cData['title'] ?? 'Unknown Challenge';
      }
      final groupQuery = await FirebaseFirestore.instance
      .collection('groups')
      .where('challengeID', isEqualTo: challengeDocId)
      .limit(1)
      .get();
      if (groupQuery.docs.isNotEmpty) {
        final gData = groupQuery.docs.first.data() as Map<String, dynamic>;
        groupName = gData['groupName'] ?? 'Unknown Group';
  }
    }


    // 3) User name
    final userId = docData['user_id'] as String?;
    if (userId != null) {
      final userSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (userSnap.exists) {
        final uData = userSnap.data()!;
        userName = uData['name'] ?? 'Unknown User';
      }
    }

    final files = docData['files'] as List<dynamic>? ?? [];
print("Files field for document: $files"); // Debug print before condition
if (files.isNotEmpty) {
  final rawBase64 = files.first as String;
  final base64Str = rawBase64.contains(",") ? rawBase64.split(",").last : rawBase64;
  print("Base64 string: $base64Str");
  try {
    imageBytes = base64Decode(base64Str); // Assign to the outer variable
    print("Decoded image length: ${imageBytes!.length}");
  } catch (e) {
    debugPrint("Error decoding image: $e");
  }
} else {
  print("No files found in this document.");
}


return {
  'challengeName': challengeName,
  'groupName': groupName,
  'userName': userName,
  'imageBytes': imageBytes,
};

  }

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
      backgroundColor: darkCharcoal,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('user_submissions')
            .where('location', isEqualTo: GeoPoint(location.lat, location.lng))
             .where('allowVoting', isEqualTo: true)
            .snapshots(),

        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          print("Total documents: ${docs.length}");


          // Participant count: unique user_ids
          final Set<String> uniqueUsers = {};
          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final userId = data['user_id'] as String?;
            if (userId != null) {
              uniqueUsers.add(userId);
            }
          }
          final participantCount = uniqueUsers.length;

          // Build a FutureBuilder for the place name
          return FutureBuilder<String>(
            future: _getPlaceName(location.lat, location.lng),
            builder: (context, placeSnap) {
              if (placeSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final placeName = placeSnap.data ?? 'Unknown Place';

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top banner: "XX Said HEEEY! 👋 @ placeName"
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: offBlack,
                        borderRadius: BorderRadius.circular(12)
                      ),
                      child: Text(
                        "$participantCount Said HEEEY! \u{1F44B} \n @ $placeName",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: lightGray,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Grid of images
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: docs.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 0.8,
                        ),
                        itemBuilder: (context, index) {
                          final docData = docs[index].data() as Map<String, dynamic>;

                          // We do a FutureBuilder for each doc to get challengeName, groupName, userName, image
                          return FutureBuilder<Map<String, dynamic>>(
                            future: _fetchSubmissionDetails(docData),
                            builder: (context, detailsSnap) {
                              if (!detailsSnap.hasData) {
                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade800,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              final details = detailsSnap.data!;
                              final challengeName = details['challengeName'] as String;
                              final groupName = details['groupName'] as String;
                              final userName = details['userName'] as String;
                              final imageBytes = details['imageBytes'] as Uint8List?;

                              return GestureDetector(
                                onTap: () {
                                  // Possibly navigate to a detail screen
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF343436),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      // Top image
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(8),
                                            topRight: Radius.circular(8),
                                          ),
                                          child: imageBytes != null
                                              ? Image.memory(
                                                  imageBytes,
                                                  fit: BoxFit.cover,
                                                )
                                              : Container(
                                                  color: Colors.black26,
                                                  child: const Icon(
                                                    Icons.image,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                        ),
                                      ),
                                      // Text info
                                      Padding(
                                        padding: const EdgeInsets.all(6),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              challengeName,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              groupName,
                                              style: const TextStyle(
                                                fontSize: 9,
                                                color: Colors.white70,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              "By: $userName",
                                              style: const TextStyle(
                                                fontSize: 9,
                                                color: Colors.white70,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
