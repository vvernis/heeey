import 'dart:convert';
import 'dart:typed_data';
import 'package:intl/intl.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';


/// Replace these with your own color/style constants.
const Color darkCharcoal = Color(0xFF29292B);
const Color offBlack = Color(0xFF343436);
const Color vividYellow = Color(0xFFd7ed73);
const Color lightGray = Color(0xFFF0F0E6);

/// A SmartStackRotatingImages widget (from your snippet).
class SmartStackRotatingImages extends StatefulWidget {
  final List<String> additionalImages; // list of base64-encoded images
  final double imageHeight;
  final double imageWidth;

  const SmartStackRotatingImages({
    Key? key,
    required this.additionalImages,
    this.imageHeight = 170,
    this.imageWidth = 260,
  }) : super(key: key);

  @override
  _SmartStackRotatingImagesState createState() => _SmartStackRotatingImagesState();
}

class _SmartStackRotatingImagesState extends State<SmartStackRotatingImages> {
  int _currentIndex = 0;

  Widget _buildImage(String base64Str) {
    Uint8List? bytes;
    try {
      bytes = base64Decode(base64Str);
    } catch (e) {
      debugPrint("Error decoding image: $e");
    }
    return bytes != null
        ? ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              bytes,
              fit: BoxFit.cover,
              width: widget.imageWidth,
              height: widget.imageHeight,
            ),
          )
        : Container(
            width: widget.imageWidth,
            height: widget.imageHeight,
            color: Colors.black12,
            child: const Icon(Icons.image, size: 50, color: Colors.white),
          );
  }

  void _nextImage() {
    if (_currentIndex < widget.additionalImages.length - 1) {
      setState(() {
        _currentIndex++;
      });
    }
  }

  void _prevImage() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.additionalImages.isEmpty) {
      return Container(
        width: widget.imageWidth,
        height: widget.imageHeight,
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Icon(Icons.image, size: 50, color: Colors.white),
        ),
      );
    }
    return SizedBox(
      height: widget.imageHeight,
      width: widget.imageWidth,
      child: Stack(
        children: [
          // Display the current image
          Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildImage(widget.additionalImages[_currentIndex]),
              transitionBuilder: (child, animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              switchInCurve: Curves.easeIn,
              switchOutCurve: Curves.easeOut,
            ),
          ),
          // Back Button
          if (_currentIndex > 0)
            Positioned(
              left: 5,
              top: 0,
              bottom: 0,
              child: InkWell(
                onTap: _prevImage,
                child: Container(
                  width: 25,
                  height: 25,
                  decoration: BoxDecoration(
                    color: darkCharcoal,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Padding(
                      padding: EdgeInsets.only(left: 2.0),
                      child: Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                        size: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          // Next Button
          if (_currentIndex < widget.additionalImages.length - 1)
            Positioned(
              right: 5,
              top: 0,
              bottom: 0,
              child: InkWell(
                onTap: _nextImage,
                child: Container(
                  width: 25,
                  height: 25,
                  decoration: BoxDecoration(
                    color: darkCharcoal,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.arrow_forward_ios,
                      color: lightGray,
                      size: 15,
                    ),
                  ),
                ),
              ),
            ),
          // Dot indicators
          Positioned(
            bottom: 4,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.additionalImages.length, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: _currentIndex == index ? 12 : 8,
                  height: _currentIndex == index ? 4 : 4,
                  decoration: BoxDecoration(
                    color: _currentIndex == index ? Colors.white : Colors.white54,
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

/// The main ChallengeDetailPage
class ChallengeDetailPage extends StatelessWidget {
  final String challengeId;
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  ChallengeDetailPage({Key? key, required this.challengeId}) : super(key: key);


  /// Helper to fetch the Challenge doc
  Stream<DocumentSnapshot> _challengeStream() {
    return FirebaseFirestore.instance
        .collection('challenges')
        .doc(challengeId)
        .snapshots();
  }

  /// Helper to fetch groups for this challenge
  Stream<QuerySnapshot> _groupsStream() {
    return FirebaseFirestore.instance
        .collection('groups')
        .where('members', arrayContains: userId)
        .where('challengeID', isEqualTo: challengeId)
        .snapshots();
  }
  
  /// Helper function to fetch challenge details in batches.
  /// Firestore 'whereIn' queries support at most 10 elements, so if there are more,
  /// we split them into batches.
  Future<List<DocumentSnapshot>> fetchChallengeDetails(
      List<String> challengeIds) async {
    final List<DocumentSnapshot> results = [];
    const int batchSize = 10;
    for (int i = 0; i < challengeIds.length; i += batchSize) {
      final int end =
          (i + batchSize > challengeIds.length) ? challengeIds.length : i + batchSize;
      final batch = challengeIds.sublist(i, end);
      final querySnapshot = await FirebaseFirestore.instance
          .collection('challenges')
          .where(FieldPath.documentId, whereIn: batch)
          .get();
      results.addAll(querySnapshot.docs);
    }
    return results;
  }

  /// Build the Challenge Passport by fetching all joined challenges and then
  /// querying for challenge details in batches.
 Widget _buildChallengePassport() {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('joined_challenges')
        .where('user_id', isEqualTo: userId)
        .where('challenge_id', isEqualTo: challengeId)
        .snapshots(),
    builder: (context, joinedSnapshot) {
      if (!joinedSnapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final joinedDocs = joinedSnapshot.data!.docs;
      if (joinedDocs.isEmpty) {
        return const Text("No challenges completed yet.");
      }

      // Extract challenge IDs
      final challengeIds = joinedDocs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['challenge_id'] as String;
      }).toList();

      // Now fetch challenge details in batches
      return FutureBuilder<List<DocumentSnapshot>>(
        future: fetchChallengeDetails(challengeIds),
        builder: (context, challengeDetailsSnapshot) {
          if (!challengeDetailsSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final challengeDocs = challengeDetailsSnapshot.data!;
          final Map<String, Map<String, dynamic>> challengesMap = {};
          for (var doc in challengeDocs) {
            challengesMap[doc.id] = doc.data() as Map<String, dynamic>;
          }

          // Show only the 2 most recent joined challenges.
          final recentJoinedDocs = joinedDocs.take(1).toList();

// Inside your ListView.builder in _buildChallengePassport():
return ListView.builder(
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  itemCount: recentJoinedDocs.length,
  itemBuilder: (context, index) {
    final joinedData = recentJoinedDocs[index].data() as Map<String, dynamic>;
    final challengeId = joinedData['challenge_id'];
    final challengeData = challengesMap[challengeId];
    final title = challengeData?['title'] ?? 'Unnamed Challenge';
    final type  = challengeData?['type'] ?? 'Unknown Type';

    final startTs = challengeData?['start_date'] as Timestamp?;
    final endTs   = challengeData?['end_date']   as Timestamp?;
    final startDate = startTs?.toDate();
    final endDate   = endTs?.toDate();

    return FutureBuilder<QuerySnapshot>(
      // This fetches the group doc(s) that match this user & challenge
      future: FirebaseFirestore.instance
          .collection('groups')
          .where('challengeID', isEqualTo: challengeId)
          .where('members', arrayContains: userId)
          .limit(1)
          .get(),
      builder: (context, groupSnap) {
        String completedDateStr = "--";
        if (groupSnap.hasData && groupSnap.data!.docs.isNotEmpty) {
          final groupDoc = groupSnap.data!.docs.first;
          final groupData = groupDoc.data() as Map<String, dynamic>;
          final approvedAt = groupData['approvedAt'] as Timestamp?;
          if (approvedAt != null) {
            final dt = approvedAt.toDate();
            completedDateStr = DateFormat('EEE, MMM d yyyy').format(dt);
          }
        }

        return InkWell(
          
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: lightGray,         // Light background
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            // "Boarding Pass" style row:
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1) Left vertical label "HEEEY!"
                //    We'll rotate it 90° (quarterTurns=3).
                RotatedBox(
                  quarterTurns: 3,
                  child: Text(
                    "HEEEY!",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // 2) Middle content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row: Challenge name & type
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          // "type" chip on the right
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: vividYellow,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              type,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Middle row: Start date -> End date
                      if (startDate != null && endDate != null) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('dd.MM').format(startDate),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Expanded(
                            child: Center(
                              child: Container(
                                height: 1,
                                width: double.infinity,
                                color: Colors.grey[500],
                                margin: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                            ),
                          ),
                            // A small icon or separator in the center
                            Row(
                              children: [
                                const SizedBox(width: 8),
                                const Icon(Icons.flight, size: 16, color: Colors.orange),
                                const SizedBox(width: 8),
                              ],
                            ),
                            Expanded(
                            child: Center(
                              child: Container(
                                height: 1,
                                width: double.infinity,
                                color: Colors.grey[500],
                                margin: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                            ),
                          ),
                            Text(
                              DateFormat('dd.MM').format(endDate),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        // Show the actual day/month in smaller text
                        Row(children: [
                         Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            "${DateFormat('yyyy').format(startDate)}",
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                        const Spacer(),
                         Align(
                          alignment: Alignment.topRight,
                          child: Text(
                            "${DateFormat('yyyy').format(endDate)}",
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                        ]
                        ),
                      ],

                      const SizedBox(height: 8),

                      // Bottom row: "Completed: Wed, Sep 11 2024" or so
                      Text(
                        "Completed: $completedDateStr",
                        style: const TextStyle(
                          fontSize: 12,
                         // fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
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
);
        },
      );
    },
  );
}


  /// Helper to fetch user_submissions for a group
  Future<List<Uint8List>> _fetchGroupImages(List<dynamic> members) async {
    if (members.isEmpty) return [];
    // Find all submissions from these members for this challenge
    final subsSnap = await FirebaseFirestore.instance
        .collection('user_submissions')
        .where('challengeDocId', isEqualTo: challengeId)
        .where('user_id', whereIn: members)
        .where('status', isEqualTo: 'approved')
        .get();

    // Gather all images from each submission
    final List<Uint8List> allImages = [];
    for (var doc in subsSnap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final files = data['files'] as List<dynamic>? ?? [];
      for (var fileBase64 in files) {
        try {
          final imageBytes = base64Decode(fileBase64);
          allImages.add(imageBytes);
        } catch (e) {
          debugPrint("Error decoding image: $e");
        }
      }
    }
    return allImages;
  }

  /// Helper to fetch user names for a group’s member IDs
  Future<List<String>> _fetchMemberNames(List<dynamic> members) async {
    if (members.isEmpty) return [];
    // Limit to 10 if you have more than 10, or do it in batches
    final int batchSize = 10;
    List<String> allNames = [];
    for (int i = 0; i < members.length; i += batchSize) {
      final sublist = members.sublist(i, i + batchSize > members.length ? members.length : i + batchSize);
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: sublist)
          .get();
      for (var doc in snap.docs) {
        final data = doc.data();
        final name = data['name'] ?? doc.id;
        allNames.add(name);
      }
    }
    return allNames;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkCharcoal,
      appBar: AppBar(
        title: const Text(
          'My Challenges',
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1) Top area: "boarding pass" style for the Challenge
            StreamBuilder<DocumentSnapshot>(
              stream: _challengeStream(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  );
                }
                if (!snap.hasData || !snap.data!.exists) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text("Challenge not found"),
                  );
                }
                final data = snap.data!.data() as Map<String, dynamic>;
                final title = data['title'] ?? 'Untitled Challenge';
                final type  = data['type'] ?? 'Unknown Type';
                final about = data['about'] ?? 'Unknown about';
                final startTs = data['start_date'] as Timestamp?;
                final endTs   = data['end_date'] as Timestamp?;
                final startDate = startTs?.toDate();
                final endDate   = endTs?.toDate();

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0,2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Center(
                        child: Text(
                          "The Challenge",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: lightGray,
                          ),
                        ),
                      ),
                     
                     _buildChallengePassport(),
                      // Some dummy description
                      Text(
                          "Description",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: lightGray,
                          ),
                        ),
                     Text(
                              about,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[100],
                              ),
                            ),
                    ],
                  ),
                );
              },
            ),
            // 2) Groups & Photos
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0,2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      "Photos Submitted",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: lightGray
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Now we list all groups for this challenge
                  StreamBuilder<QuerySnapshot>(
                    stream: _groupsStream(),
                    builder: (context, groupSnap) {
                      if (groupSnap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!groupSnap.hasData || groupSnap.data!.docs.isEmpty) {
                        return const Text("No groups found for this challenge.");
                      }
                      final groupDocs = groupSnap.data!.docs;
                      return Column(
                        children: groupDocs.map((doc) {
                          final groupData = doc.data() as Map<String, dynamic>;
                          final groupName = groupData['groupName'] ?? 'Unnamed Group';
                          final members   = groupData['members'] as List<dynamic>? ?? [];

                          return FutureBuilder<List<Uint8List>>(
                            future: _fetchGroupImages(members),
                            builder: (context, imagesSnap) {
                              if (imagesSnap.connectionState == ConnectionState.waiting) {
                                return const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: CircularProgressIndicator(),
                                );
                              }
                              final allImages = imagesSnap.data ?? [];

                              return FutureBuilder<List<String>>(
                                future: _fetchMemberNames(members),
                                builder: (context, namesSnap) {
                                  if (namesSnap.connectionState == ConnectionState.waiting) {
                                    return const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: CircularProgressIndicator(),
                                    );
                                  }
                                  final friendNames = namesSnap.data ?? [];

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: offBlack,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                         SmartStackRotatingImages(
                                          additionalImages: allImages
                                              .map((bytes) => base64Encode(bytes))
                                              .toList(),
                                          imageHeight: 160,
                                          imageWidth: 500,
                                        ),
                                          const SizedBox(height: 8),
                                        // Group name
                                        Row(
                                          children: [
                                            const Icon(Icons.group, size: 16, color: lightGray),
                                             const SizedBox(width: 2),
                                            // The rotating images
                                            Text(
                                              groupName,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: lightGray
                                              ),
                                            ),
                                            const Spacer(),
                                            // Number of images
                                            Text(
                                              "${allImages.length} photo(s)",
                                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        // Member names
                                        Text(
                                          "Members: ${friendNames.join(', ')}",
                                          style: const TextStyle(fontSize: 12, color: lightGray),
                                        ),
                                  
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
