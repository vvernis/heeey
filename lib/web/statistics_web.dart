// admin_statistics_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:heeey/mobile/screens/memory%20gallery/memory_gallery.dart';
import 'package:heeey/web/user_data_web.dart';
import '../shared/memory_gallery_map.dart'; // Ensure this import is correct
import 'dart:convert';
import 'dart:typed_data';

// REVISED THEME / COLORS
// Light pastel background for the entire screen
const Color dashboardBgColor = Colors.transparent;
// Card background (white)
const Color dashboardCardColor = Colors.white;
// A subtle accent color for top challenge row highlight
const Color highlightRowColor = Color(0xFFE1DFFA);
// Text colors & styles
const Color headingTextColor = Color(0xFF333333);
const Color bodyTextColor = Color(0xFF555555);

const Color kChipBlueBg    = Color(0xFFeef7ff);
const Color kChipBlueText  = Color(0xFF4775a6);
const Color kChipGreenBg   = Color(0xFFedfdf4);
const Color kChipGreenText = Color(0xFF256a45);

const double cardRadius = 16.0;
const double outerPadding = 8.0;
const double innerPadding = 8.0;

/// Basic heading style used for section titles
const TextStyle kSectionTitleStyle = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.bold,
  color: headingTextColor,
  // You can specify fontFamily, letterSpacing, etc., if needed.
);

/// Style for smaller subheadings or row labels
const TextStyle kSubHeadingStyle = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w600,
  color: bodyTextColor,
);

/// Style for large numeric stats
const TextStyle kStatValueStyle = TextStyle(
  fontSize: 20,
  fontWeight: FontWeight.bold,
  color: headingTextColor,
);

/// Style for normal body text
const TextStyle kBodyTextStyle = TextStyle(
  fontSize: 14,
  color: bodyTextColor,
);

class AdminStatisticsPage extends StatefulWidget {
  const AdminStatisticsPage({super.key});

  @override
  _AdminStatisticsPageState createState() => _AdminStatisticsPageState();
}

class _AdminStatisticsPageState extends State<AdminStatisticsPage> {
  // ------------------------------------------------
  // Outer helper to wrap any content in a rounded Card.
  // ------------------------------------------------
  Widget _buildRoundedCard({required Widget child}) {
    return Card(
      color: dashboardCardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardRadius),
      ),
      elevation: 2, // Light shadow
      margin: const EdgeInsets.all(outerPadding),
      child: Padding(
        padding: const EdgeInsets.all(innerPadding),
        child: child,
      ),
    );
  }

  // ------------------------------------------------
  // Challenge Statistics Card
  // ------------------------------------------------
  Widget _buildChallengeStatisticsCard() {
  return FutureBuilder<List<dynamic>>(
    future: Future.wait([
      // 1) All challenges
      FirebaseFirestore.instance.collection('challenges').get(),
      // 2) joined_challenges
      FirebaseFirestore.instance.collection('joined_challenges').get(),
      // 3) groups (for most liked)
      FirebaseFirestore.instance.collection('groups').get(),
    ]),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return _buildRoundedCard(
          child: SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          ),
        );
      }

      final QuerySnapshot challengesSnap = snapshot.data![0] as QuerySnapshot;
      final QuerySnapshot joinedSnap = snapshot.data![1] as QuerySnapshot;
      final QuerySnapshot groupsSnap = snapshot.data![2] as QuerySnapshot;

      // 1) Total challenges
      final int totalChallenges = challengesSnap.docs.length;

      // 2) Total unique participants from joined_challenges
      final Set<dynamic> uniqueParticipants = {};
      for (var doc in joinedSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['user_id'] != null) {
          uniqueParticipants.add(data['user_id']);
        }
      }
      final int totalParticipants = uniqueParticipants.length;

      // 3) Determine the group(s) with the most likes
      final List<DocumentSnapshot> allGroups = groupsSnap.docs.toList();
      int maxLikes = 0;
      for (var doc in allGroups) {
        final data = doc.data() as Map<String, dynamic>;
        final int groupLikes = data['likes'] ?? 0;
        if (groupLikes > maxLikes) {
          maxLikes = groupLikes;
        }
      }
      // Filter for groups that share that maxLikes
      final List<DocumentSnapshot> topGroups = allGroups.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final int groupLikes = data['likes'] ?? 0;
        return groupLikes == maxLikes && maxLikes > 0;
      }).toList();

      return _buildRoundedCard(
        child: SizedBox(
          height: 200,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // LEFT COLUMN: 2 stat tiles
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      "Challenge Statistics",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildNumberStatCard(
                      label: "Total Challenges",
                      number: totalChallenges,
                      icon: Icons.flash_on,
                      iconColor: kChipGreenText,
                    ),
                    const SizedBox(height: 8),
                    _buildNumberStatCard(
                      label: "Total Participants",
                      number: totalParticipants,
                      icon: Icons.people,
                      iconColor: kChipBlueText,
                    ),
                  ],
                ),
              ),

              // RIGHT COLUMN: "Most Liked Photo" section
              Expanded(
                flex: 1,
                child: Column(
                  children: [ 
                  const SizedBox(height: 20),
                  Container(
                  height: 180,
                  padding: const EdgeInsets.only(top: 8, bottom: 8, right: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: (topGroups.isEmpty)
                      ? // If no groups have likes
                      Center(
                          child: Text(
                            "No liked photos",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        )
                      : PageView.builder(
                          controller: PageController(viewportFraction: 0.8),
                          itemCount: topGroups.length,
                          itemBuilder: (context, index) {
                            final groupDoc = topGroups[index];
                            final groupData =
                                groupDoc.data() as Map<String, dynamic>;
                            final groupName =
                                groupData['groupName'] ?? 'Unknown Group';
                            final int likes = groupData['likes'] ?? 0;
                            final String challengeId =
                                groupData['challengeID'] ?? '';
                            final List<dynamic> members =
                                groupData['members'] ?? [];

                            return FutureBuilder<DocumentSnapshot>(
                              // fetch the challenge doc to get official challenge title
                              future: FirebaseFirestore.instance
                                  .collection('challenges')
                                  .doc(challengeId)
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
                                    challengeId,
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
                                          color: Colors.grey[100],
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
                                                        horizontal: 8.0),
                                                child: Text(
                                                  "By: $groupName\nFrom: $challengeTitle",
                                                  style: const TextStyle(
                                                    color: offBlack,
                                                    fontSize: 10,
                                                    
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
                                                        color: Colors.black,
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 2),
                                                    const Icon(
                                                      Icons.favorite,
                                                      color: Colors.redAccent,
                                                      size: 10,
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
                          },
                        ),
                ),
                  ]
              ),
              ),
            ],
          ),
        ),
      );
    },
  );
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

/// Decreased font-size version of your number stat card
Widget _buildNumberStatCard({
  required String label,
  required int number,
  required IconData icon,
  required Color iconColor,
}) {
  return Container(
    height: 80,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(cardRadius),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card title
        Text(
          label,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        // Big number + icon row
        Row(
          children: [
            // Big number
            Text(
              "$number",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            // Icon in a circle
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 16,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}


  
  // ------------------------------------------------
  // Challenge List Card
  // ------------------------------------------------
  Widget _buildChallengeListCard() {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance.collection('challenges').snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return _buildRoundedCard(
          child: SizedBox(
            height: 200,
            child: Center(
              child: Text("No challenges found", style: kBodyTextStyle.copyWith(fontSize: 10)),
            ),
          ),
        );
      }

      List<DocumentSnapshot> docs = snapshot.data!.docs;
      int maxCount = 0;
      for (var doc in docs) {
        final data = doc.data() as Map<String, dynamic>;
        final dynamic participants = data['participants'];
        int count = 0;
        if (participants is List) {
          count = participants.length;
        } else if (participants is int) {
          count = participants;
        }
        if (count > maxCount) {
          maxCount = count;
        }
      }

      // Build rows for DataTable.
      List<DataRow> rows = docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        String title = data['title'] ?? 'N/A';
        final dynamic participants = data['participants'];
        int count = 0;
        if (participants is List) {
          count = participants.length;
        } else if (participants is int) {
          count = participants;
        }
        bool isTop = (count == maxCount && maxCount > 0);

        return DataRow(
          color: MaterialStateProperty.resolveWith<Color?>((states) {
            return isTop ? highlightRowColor : Colors.transparent;
          }),
          cells: [
            DataCell(
              Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isTop ? FontWeight.bold : FontWeight.normal,
                  color: bodyTextColor,
                ),
              ),
            ),
            DataCell(SizedBox(width: 40)),
            DataCell(
              Text(
                "$count",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isTop ? FontWeight.bold : FontWeight.normal,
                  color: bodyTextColor,
                ),
              ),
            ),
          ],
        );
      }).toList();

      // Wrap the DataTable in a container with a border and rounded corners.
      return _buildRoundedCard(
  child: Container(
    // Force a fixed height of 200
    height: 200,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(cardRadius),
    ),
    //padding: const EdgeInsets.all(8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          "Challenge Participation",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: offBlack,
          ),
        ),
        const SizedBox(height: 4),
        // This Flexible ensures the DataTable can scroll within the fixed 200 height.
        Flexible(
          fit: FlexFit.loose,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 32,
              dataRowHeight: 28,
              horizontalMargin: 8,
              columnSpacing: 16,
              headingRowColor: MaterialStateProperty.resolveWith<Color?>(
                (states) => Colors.grey.shade200,
              ),
              columns: const [
                DataColumn(
                  label: Text(
                    "Challenge",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: bodyTextColor,
                    ),
                  ),
                ),
                DataColumn(label: Text("")),
                DataColumn(
                  label: Text(
                    "Participants",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: bodyTextColor,
                    ),
                  ),
                ),
              ],
              rows: rows,
            ),
          ),
        ),
      ],
    ),
  ),
);

    },
  );
}

  // ------------------------------------------------
  // Submission Statistics Card
  // ------------------------------------------------
  Widget _buildSubmissionStatsCard() {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance.collection('user_submissions').snapshots(),
    builder: (context, snapshot) {
      int total = 0, approved = 0;
      if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
        total = snapshot.data!.docs.length;
        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['status'] == 'approved') {
            approved++;
          }
        }
      }
      return _buildRoundedCard(
        child: SizedBox(
          height: 120,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            const Text(
              "Submission Statistics",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          const SizedBox(height: 8),
           Row(
            children: [
              Expanded(
                child: _buildSubmissionStatCard(
                  label: "Total Submissions",
                  number: total,
                  icon: Icons.assignment,
                  iconColor: kChipBlueText,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSubmissionStatCard(
                  label: "Approved Submissions",
                  number: approved,
                  icon: Icons.check_circle,
                  iconColor: kChipGreenText,
                ),
              ),
            ],
          ),
            ]
          ),
        ),
      );
    },
  );
}

Widget _buildSubmissionStatCard({
  required String label,
  required int number,
  required IconData icon,
  required Color iconColor,
}) {
  return Container(
    height: 80,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(cardRadius),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card title
        Text(
          label,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        // Big number + icon row
        Row(
          children: [
            // Big number
            Text(
              "$number",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            // Icon in a circle
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 16,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

  // ------------------------------------------------
  // Required Action Card
  // ------------------------------------------------
 Widget _buildRequiredActionCard() {
  return FutureBuilder<List<dynamic>>(
    future: Future.wait([
      // 1) All challenges
      FirebaseFirestore.instance.collection('challenges').get(),
      // 2) All pending user_submissions
      FirebaseFirestore.instance
          .collection('user_submissions')
          .where('status', isEqualTo: 'pending')
          .get(),
    ]),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return _buildRoundedCard(
          child: SizedBox(
            height: 167,
            child: const Center(child: CircularProgressIndicator()),
          ),
        );
      }

      final QuerySnapshot challengesSnap = snapshot.data![0] as QuerySnapshot;
      final QuerySnapshot submissionsSnap = snapshot.data![1] as QuerySnapshot;

      // If no pending submissions
      if (submissionsSnap.docs.isEmpty) {
        return _buildRoundedCard(
          child: SizedBox(
            height: 167,
            child: Center(
              child: Text(
                "No pending actions",
                style: kBodyTextStyle.copyWith(fontSize: 10),
              ),
            ),
          ),
        );
      }

      // Build a map: challengeDocId -> challengeTitle
      final Map<String, String> challengeTitleMap = {};
      for (var doc in challengesSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final String title = data['title'] ?? 'Untitled';
        challengeTitleMap[doc.id] = title;
      }

      // Aggregate pending counts by official challenge title
      final Map<String, int> pendingCounts = {};
      for (var doc in submissionsSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final String? challengeDocId = data['challengeDocId'] as String?;
        String actualTitle = 'Unknown Challenge';

        if (challengeDocId != null &&
            challengeTitleMap.containsKey(challengeDocId)) {
          actualTitle = challengeTitleMap[challengeDocId]!;
        }

        pendingCounts[actualTitle] = (pendingCounts[actualTitle] ?? 0) + 1;
      }

      // Build a list of row widgets for each pending challenge
      final List<Widget> pendingRows = pendingCounts.entries.map((entry) {
        final challengeTitle = entry.key;
        final count = entry.value;

        return Container(
          width: double.infinity, // fill the card's width
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(cardRadius)),
          // A row with the text on the left and alert icon on the right
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left side: challenge title + pending count
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      challengeTitle,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // "X pending submissions"
                    Text(
                      "$count pending submission${count > 1 ? 's' : ''}",
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              // Right side: alert icon in a circle
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline, // or Icons.warning_amber_rounded
                  color: Colors.orangeAccent,
                  size: 16,
                ),
              ),
            ],
          ),
        );
      }).toList();

      // Return the card with a fixed height (optional)
      return _buildRoundedCard(
        child: SizedBox(
          height: 167, // or remove if you want auto-size
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                "Pending Approvals",
                style: kSectionTitleStyle.copyWith(fontSize: 14),
              ),
              const SizedBox(height: 8),

              // Show each pending challenge row
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: pendingRows, 
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}



  // ------------------------------------------------
  // Memory Map Card
  // ------------------------------------------------
  Widget _buildMemoryMapCard() {
    return _buildRoundedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Memory Map", style: kSectionTitleStyle),
          const SizedBox(height: 8),
          SizedBox(
            height: 300,
            child:  StreamBuilder<QuerySnapshot>(
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
                }).whereType<GalleryItem>().toList();
                return MemoryGalleryMap(items: mapItems);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------
  // Layout
  // ------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: dashboardBgColor,
     appBar: AppBar(
        title: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start, // Align text to the left
          children: [
            const SizedBox(height: 12),
            Text(
              "HEEEY! Dashboard",
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.bold, color: offBlack),
            ),
            const SizedBox(height: 4),
            Text(
              "This is the statistics of HEEEY!",
              style: TextStyle(
                fontSize: 12,
                color: kSubText,
              ),
            ),
          ],
        ),
        centerTitle:
            false, // Optional: ensures left alignment on some platforms
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(outerPadding),
        child: Column(
          children: [
            // Top Row: Left: Challenge Statistics, Right: Challenge List
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _buildChallengeStatisticsCard(),
                ),
                const SizedBox(width: outerPadding),
                Expanded(
                  flex: 1,
                  child: _buildChallengeListCard(),
                ),
              ],
            ),
            const SizedBox(height: outerPadding),
            // Bottom Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Submission Stats & Required Action
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildSubmissionStatsCard(),
                      const SizedBox(height: outerPadding),
                      _buildRequiredActionCard(),
                    ],
                  ),
                ),
                const SizedBox(width: outerPadding),
                // Right Column: Memory Map
                Expanded(
                  flex: 3,
                  child: _buildMemoryMapCard(),
                ),
              ],
            ),
          ],
        ),
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
