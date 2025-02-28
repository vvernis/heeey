import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:heeey/mobile/screens/memory%20gallery/memory_gallery.dart';
import '../../../shared/memory_gallery_map.dart';
import 'location_photo_list_page.dart';

class CommunityGalleryPage extends StatelessWidget {
  const CommunityGalleryPage({super.key});

  Future<int> _getTotalParticipants() async {
  final currentYear = DateTime.now().year;
  QuerySnapshot snapshot = await FirebaseFirestore.instance
      .collection('joined_challenges')
      .get();

  // Use a Set to keep track of unique user_ids.
  Set<dynamic> uniqueParticipants = {};

  for (var doc in snapshot.docs) {
    final data = doc.data() as Map<String, dynamic>;
    // If your document stores the join time in a field named "timestamp"
    Timestamp? ts = data['joined_at'];
    if (ts != null) {
      DateTime joinDate = ts.toDate();
      if (joinDate.year == currentYear) {
        if (data['user_id'] != null) {
          uniqueParticipants.add(data['user_id']);
        }
      }
    }
  }
  return uniqueParticipants.length;
}


  /// Helper function to get the challenge title and decoded image for a group,
  /// querying submissions for any of the provided group members.
  Future<Map<String, dynamic>> _getGroupDisplayData(
      String challengeID, List<dynamic> members) async {
    // Fetch challenge document for its title.
    DocumentSnapshot challengeDoc = await FirebaseFirestore.instance
        .collection('challenges')
        .doc(challengeID)
        .get();
    String challengeTitle =
        (challengeDoc.data() as Map<String, dynamic>?)?['title'] ??
            'Unknown Challenge';

    Uint8List? imageBytes;
    if (members.isNotEmpty) {
      // Query user_submissions using challengeID and any of the group members.
      QuerySnapshot submissionSnapshot = await FirebaseFirestore.instance
          .collection('user_submissions')
          .where('challengeDocId', isEqualTo: challengeID)
          .where('user_id', whereIn: members)
          .where('status', isEqualTo: 'approved')
          .limit(1)
          .get();
      if (submissionSnapshot.docs.isNotEmpty) {
        final submissionData =
            submissionSnapshot.docs.first.data() as Map<String, dynamic>;
        if (submissionData['files'] is List &&
            (submissionData['files'] as List).isNotEmpty) {
          final String base64Str =
              (submissionData['files'] as List).first as String;
          try {
            imageBytes = base64Decode(base64Str);
          } catch (e) {
            debugPrint("Error decoding submission image: $e");
          }
        }
      }
    }
    return {
      'challengeTitle': challengeTitle,
      'imageBytes': imageBytes,
    };
  }

  // Example of a helper method to fetch submissions for a group.
Future<QuerySnapshot> _fetchSubmissionsForGroup(
  String challengeId,
  List<dynamic> members,
) {
  if (members.isEmpty) {
    return FirebaseFirestore.instance
        .collection('user_submissions')
        .where('user_id', isEqualTo: '__no_members__')
        .get();
  }
  return FirebaseFirestore.instance
      .collection('user_submissions')
      .where('challengeDocId', isEqualTo: challengeId)
      .where('allowVoting', isEqualTo: true)
      .where('user_id', whereIn: members)
      .get();
}


  @override
  Widget build(BuildContext context) {
    // Use the user_submissions stream only for displaying the map.
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance.collection('user_submissions').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final submissionDocs = snapshot.data!.docs;
          // Filter submissions with a location.
          final submissionsWithLocation = submissionDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['location'] != null;
          }).toList();
          
          // Add these lines to compute participant counts by location:
          final Map<String, Set<String>> locationToUserIds = {};
          for (var doc in submissionsWithLocation) {
            final data = doc.data() as Map<String, dynamic>;
            final location = data['location']; // assumed to be a GeoPoint
            if (location != null) {
              // Use a key based on latitude and longitude
              final key = '${(location as dynamic).latitude.toDouble()},${(location as dynamic).longitude.toDouble()}';
              final userId = data['user_id'] as String? ?? '';
              if (userId.isNotEmpty) {
                locationToUserIds.putIfAbsent(key, () => <String>{}).add(userId);
              }
            }
          }

          // Create a mapping from location key to participant count
          final Map<String, int> locationToParticipantCount = {};
          locationToUserIds.forEach((key, userIds) {
            locationToParticipantCount[key] = userIds.length;
          });

        final List<GalleryItem> mapItems = submissionsWithLocation.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final location = data['location']; // assumed to be a GeoPoint
        final key = '${(location as dynamic).latitude.toDouble()},${(location as dynamic).longitude.toDouble()}';
        final participantCount = locationToParticipantCount[key] ?? 0;
            
              
            return GalleryItem(
              lat: (location as dynamic).latitude.toDouble(),
              lng: (location as dynamic).longitude.toDouble(),
              image: data['files'] is List &&
                      (data['files'] as List).isNotEmpty
                  ? (data['files'] as List).first as String
                  : '',
               participantCount: participantCount,
            );
          }).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Map Display using MemoryGalleryMap.
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    height: 200,
                    child: MemoryGalleryMap(
                      items: mapItems,
                      onMarkerTap: (GalleryItem item) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                LocationPhotoListPage(location: item),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Total Participants Card.
                FutureBuilder<int>(
                  future: _getTotalParticipants(),
                  builder: (context, totalSnapshot) {
                    if (!totalSnapshot.hasData) {
                      return const CircularProgressIndicator();
                    }
                    final currentYear = DateTime.now().year;
                    return Container(
                      width: double.infinity, // This forces the container to fill the width of its parent.
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade900,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        "IN $currentYear: ${totalSnapshot.data} People Said HEEEY! \u{1F44B}",
                        textAlign: TextAlign.center, // Center the text
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                // Most Liked Group Photo Card.
                FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('groups')
                      .where('status', isEqualTo: 'approved')
                      .get(),
                  builder: (context, groupSnapshot) {
                    if (!groupSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final groupsDocs = groupSnapshot.data!.docs;
                    if (groupsDocs.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade900,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          "No approved groups available",
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    // Sort groups descending by likes.
                    groupsDocs.sort((a, b) {
                      final aLikes =
                          (a.data() as Map<String, dynamic>)['likes'] ?? 0;
                      final bLikes =
                          (b.data() as Map<String, dynamic>)['likes'] ?? 0;
                      return bLikes.compareTo(aLikes);
                    });
                    int maxLikes =
                        (groupsDocs.first.data() as Map<String, dynamic>)['likes'] ??
                            0;
                    // Filter for top groups.
                    final topGroups = groupsDocs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return (data['likes'] ?? 0) == maxLikes;
                    }).toList();

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade900,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            "MOST LIKED GROUP PHOTO \u{1F525}",
                            textAlign: TextAlign.center,
                            style:
                                TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 220,
                            width: double.infinity,
                            child: PageView.builder(
                              controller: PageController(viewportFraction: 0.8),
                              itemCount: topGroups.length,
                              itemBuilder: (context, index) {
                                final groupData =
                                    topGroups[index].data() as Map<String, dynamic>;
                                final groupName =
                                    groupData['groupName'] ?? 'Unknown Group';
                                final likes = groupData['likes'] ?? 0;
                                final challengeID = groupData['challengeID'] ?? '';
                                final List<dynamic> members =
                                    groupData['members'] ?? [];
                                // Pass the full members list for the query.
                                return FutureBuilder<DocumentSnapshot>(
                              // fetch the challenge doc to get official challenge title
                              future: FirebaseFirestore.instance
                                  .collection('challenges')
                                  .doc(challengeID)
                                  .get(),
                              builder: (context, challengeSnap) {
                                String challengeTitle = 'Unknown Challenge';
                                if (challengeSnap.hasData &&
                                    challengeSnap.data!.exists) {
                                  final chData =
                                      challengeSnap.data!.data() as Map<String, dynamic>;
                                  challengeTitle = chData['title'] ?? 'Untitled';
                                }

                                return FutureBuilder<QuerySnapshot>(
                                  // fetch group images if you have a method or logic
                                  future: _fetchSubmissionsForGroup(
                                    challengeID,
                                    members,
                                  ), // Or skip if you want placeholders
                                  builder: (context, subsSnap) {
                                    List<Uint8List> allImages = [];
                                    if (subsSnap.hasData) {
                                      for (var doc in subsSnap.data!.docs) {
                                        final subData =
                                            doc.data() as Map<String, dynamic>;
                                        final files =
                                            subData['files'] as List<dynamic>? ??
                                                [];
                                        for (var fileBase64 in files) {
                                          try {
                                            final imageBytes =
                                                base64Decode(fileBase64);
                                            allImages.add(imageBytes);
                                          } catch (e) {
                                            debugPrint("Error decoding image: $e");
                                          }
                                        }
                                      }
                                    }

                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          color: Colors.grey.shade800,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // If images exist, show a horizontal carousel,
                                              // otherwise a single placeholder container
                                             Expanded(
                                                child: SmartStackRotatingImages(
                                                  additionalImages: allImages.map((bytes) => base64Encode(bytes)).toList(),
                                                  imageHeight: 170,
                                                  imageWidth: 260,
                                                ),
                                              ),

                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                              // Group + Challenge Title
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8.0, vertical: 4.0),
                                                child: Text(
                                                  "By: $groupName\nFrom: $challengeTitle",
                                                  style: const TextStyle(
                                                    color: lightGray,
                                                    fontSize: 12,
                                                    
                                                  ),
                                                ),
                                              ),
                                              const Spacer(),
                                              // Likes row
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8.0),
                                                child: Row(
                                                  children: [
                                                    Text(
                                                      "$likes",
                                                      style: const TextStyle(
                                                        color: lightGray,
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 2),
                                                    const Icon(
                                                      Icons.favorite,
                                                      color: Colors.redAccent,
                                                      size: 12,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                                ]
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                              }
                          ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

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
              child:InkWell(
          onTap: () {
            _prevImage();
          },
          child: Container(
            width: 25,
            height: 25,
            decoration: BoxDecoration(
              color: darkCharcoal, // Background color of the circle
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Center(
              child: Padding(
      padding: const EdgeInsets.only(left: 2.0), // shift it slightly
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
              child:InkWell(
          onTap: () {
            _nextImage();
          },
          child: Container(
            width: 25,
            height: 25,
            decoration: BoxDecoration(
              color: darkCharcoal, // Background color of the circle
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.arrow_forward_ios,
                color: lightGray,
                size: 15,
              ),
            ),
          ),
        ),
            ),
          // Optional: dot indicators at the bottom
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
