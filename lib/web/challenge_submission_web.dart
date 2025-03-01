import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:heeey/mobile/screens/memory%20gallery/memory_gallery.dart';
import 'package:heeey/web/user_data_web.dart';
import 'package:intl/intl.dart';

const Color kChipBlueBg    = Color(0xFFeef7ff);
const Color kChipBlueText  = Color(0xFF4775a6);
const Color kChipGreenBg   = Color(0xFFedfdf4);
const Color kChipGreenText = Color(0xFF256a45);

class AdminSubmissionsScreen extends StatefulWidget {
  final String challengeId;
  const AdminSubmissionsScreen({Key? key, required this.challengeId})
      : super(key: key);

  @override
  _AdminSubmissionsScreenState createState() => _AdminSubmissionsScreenState();
}

class _AdminSubmissionsScreenState extends State<AdminSubmissionsScreen> {
  /// Track which status filter is selected. Defaults to 'all'.
  String _selectedStatusFilter = 'all';

  /// Sends completion notifications to all approved groups.
  /// Groups are sorted by their "approvedAt" timestamp (earlier approvals rank higher).
  /// The top three groups receive a special notification indicating 1st/2nd/3rd place.
  Future<void> _sendCompletionNotifications(BuildContext context) async {
  try {
    // Retrieve challenge name.
    DocumentSnapshot challengeDoc = await FirebaseFirestore.instance
        .collection('challenges')
        .doc(widget.challengeId)
        .get();
    Map<String, dynamic> challengeData =
        challengeDoc.data() as Map<String, dynamic>;
    String challengeName = challengeData['title'] ?? 'Challenge';

    // Query approved groups for this challenge.
    QuerySnapshot groupSnapshot = await FirebaseFirestore.instance
        .collection('groups')
        .where('challengeID', isEqualTo: widget.challengeId)
        .where('status', isEqualTo: 'approved')
        .get();
    List<DocumentSnapshot> approvedGroups = groupSnapshot.docs;

    // Sort approved groups by "approvedAt" ascending (earlier approvals rank higher).
    approvedGroups.sort((a, b) {
      Timestamp aTime = a.get('approvedAt') as Timestamp;
      Timestamp bTime = b.get('approvedAt') as Timestamp;
      return aTime.compareTo(bTime);
    });

    // Compute maximum likes among all approved groups.
    int maxLikesAll = 0;
    for (var doc in approvedGroups) {
      int groupLikes = doc.get('likes') ?? 0;
      if (groupLikes > maxLikesAll) {
        maxLikesAll = groupLikes;
      }
    }

    // Loop through approved groups and send notifications.
    for (int i = 0; i < approvedGroups.length; i++) {
      int groupLikes = approvedGroups[i].get('likes') ?? 0;
      String message;

      if (i < 3) {
        // Top 3 cases.
        if (i == 0) {
          message =
              "Congratulations! You have won 1st Place for $challengeName. ";
        } else if (i == 1) {
          message =
              "Congratulations! You have won 2nd Place for $challengeName. ";
        } else {
          message =
              "Congratulations! You have won 3rd Place for $challengeName. ";
        }
        if (groupLikes == maxLikesAll && maxLikesAll > 0) {
          // Case 2: Top 3 and most liked.
          message +=
              "Also, you have won the Most Liked Submission Award! Please come down to the EEE Admin Office to collect your prize.";
        } else {
          // Case 1: Top 3 but not most liked.
          message +=
              "Please come down to the EEE Admin Office to collect your prize.";
        }
      } else {
        // Not top 3.
        if (groupLikes == maxLikesAll && maxLikesAll > 0) {
          // Case 3: Not top 3 but most liked.
          message =
              "Congratulations on completing $challengeName and winning the Most Liked Submission Award! Please come down to the EEE Admin Office to collect your prize.";
        } else {
          // Case 4: Not top 3 and not most liked.
          message =
              "Congratulations on completing $challengeName. Unfortunately, you weren't the fastest this time. Try again next challenge!";
        }
      }

      // Send notification to all members of this group.
      List<dynamic> members = approvedGroups[i].get('members') ?? [];
      for (var member in members) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'receiverId': member,
          'message': message,
          'timestamp': Timestamp.now(),
          'type': 'challengeCompleted',
          'senderId': 'ADMIN', // Adjust as needed.
          'isRead': false,
          'challengeId': widget.challengeId,
        });
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Notifications sent successfully!")),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error sending notifications: $e")),
    );
  }
}


  /// Fetches submissions for a group.
  Future<QuerySnapshot> _fetchSubmissionsForGroup(List<dynamic> members) {
    if (members.isEmpty) {
      // Return empty results if no members.
      return FirebaseFirestore.instance
          .collection('user_submissions')
          .where('user_id', isEqualTo: '__nonexistent__')
          .get();
    }
    return FirebaseFirestore.instance
        .collection('user_submissions')
        .where('challengeDocId', isEqualTo: widget.challengeId)
        .where('user_id', whereIn: members)
        .get();
  }

Future<void> _sendApprovalNotificationForGroup(DocumentSnapshot groupDoc) async {
  final groupData = groupDoc.data() as Map<String, dynamic>;
  final List<dynamic> members = groupData['members'] ?? [];
  
  // You can customize the message as needed.
  const String message =
      "Congratulations! Your submission has been approved. You have successfully completed the challenge!";
  
  for (var member in members) {
    await FirebaseFirestore.instance.collection('notifications').add({
      'receiverId': member,
      'message': message,
      'timestamp': Timestamp.now(),
      'type': 'challengeCompleted',
      'senderId': 'ADMIN', // Adjust as needed.
      'isRead': false,
      'challengeId': widget.challengeId,
    });
  }
}


Widget _buildStatusChip(String status) {
  Color backgroundColor;
  Color textColor;
  String displayText;

  switch (status) {
    case 'approved':
      backgroundColor = kChipGreenBg; // pale green
      textColor = kChipGreenText;       // darker green
      displayText = 'Approved';
      break;
    case 'rejected':
      backgroundColor = Color(0xffffbfc3).withOpacity(0.2);
      textColor = const Color(0xFFC62828);       // darker red
      displayText = 'Rejected';
      break;
    default: // 'pending'
      backgroundColor = const Color(0xFFFFF3E0); // pale orange
      textColor = const Color(0xFFFB8C00);       // darker orange
      displayText = 'Pending';
      break;
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      displayText,
      style: TextStyle(
        color: textColor,
        fontWeight: FontWeight.w600,
        fontSize: 10
      ),
    ),
  );
}

Widget _buildGroupCard(
  BuildContext context,
  DocumentSnapshot groupDoc,
  Future<QuerySnapshot> Function(List<dynamic>) fetchSubmissionsForGroup,
  Future<void> Function(DocumentSnapshot) approveGroup,
  Future<void> Function(DocumentSnapshot) rejectGroup,
) {
  final groupData = groupDoc.data() as Map<String, dynamic>;
  final String groupName = groupData['groupName'] ?? groupDoc.id;
  final List<dynamic> members = groupData['members'] ?? [];
  final String status = groupData['status'] ?? 'pending';
  final int likes = groupData['likes'] ?? 0;

  return Container(
      height: 300,
      width: 300,
      // Constrain the card width so multiple cards can fit side by side
      constraints: const BoxConstraints(
        maxWidth: 300, // Adjust as desired (280, 320, etc.)
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: FutureBuilder<QuerySnapshot>(
        future: fetchSubmissionsForGroup(members),
        builder: (context, snapshot) {
          // Default placeholders
          String submissionDateString = 'No submissions';
          List<Widget> submissionImages = [
            const Text(
              "No submissions",
              style: TextStyle(fontSize: 12, color: offBlack),
            )
          ];

          // If loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            submissionImages = const [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            ];
          }
          // If we have data
          else if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            final submissions = snapshot.data!.docs;

            // 1) Find latest submission date
            DateTime? latestDate;
            for (var doc in submissions) {
              final docData = doc.data() as Map<String, dynamic>?;
              if (docData != null && docData['timestamp'] != null) {
                final t = docData['timestamp'] as Timestamp;
                final dt = t.toDate();
                if (latestDate == null || dt.isAfter(latestDate)) {
                  latestDate = dt;
                }
              }
            }
            if (latestDate != null) {
              submissionDateString =
                  DateFormat('yyyy-MM-dd HH:mm').format(latestDate);
            }

            // 2) Build a horizontal list of images
            submissionImages = [];
            for (var doc in submissions) {
              final docData = doc.data() as Map<String, dynamic>;
              final List<dynamic> files = docData['files'] ?? [];
              for (var fileBase64 in files) {
                Uint8List? imageBytes;
                try {
                  imageBytes = base64Decode(fileBase64);
                } catch (e) {
                  debugPrint("Error decoding image: $e");
                }
                // Wrap the image container with GestureDetector
                submissionImages.add(
                GestureDetector(
                  onTap: () {
                    if (imageBytes != null) {
                      _showEnlargedImage(context, imageBytes);
                    }
                  },
                child:
                  Container(
                    width: 60,
                    height: 60,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[200],
                    ),
                    child: imageBytes != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              imageBytes,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Icon(Icons.image, color: Colors.grey),
                  ),
                ),
                );
              }
            }
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1) Top row: group name + status
              Row(
                children: [
                  // Group name & # of members
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          groupName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: offBlack,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${members.length} members',
                          style: const TextStyle(
                            fontSize: 12,
                            color: offBlack,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status chip
                  _buildStatusChip(status),
                ],
              ),
              const SizedBox(height: 8),

              // 2) One row: submission date & likes side by side
              Row(
                children: [
                  // Submission date box
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Latest Submission",
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            submissionDateString,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: offBlack,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Likes box
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(left: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Likes",
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$likes',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: offBlack,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
             const SizedBox(height: 12),
             Text(
                            'Submitted Images',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: offBlack,
                            ),
                          ),
              const SizedBox(height: 3),
              // 3) Horizontal list of images
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: submissionImages),
              ),
               const Spacer(),
              // 4) Approve/Reject if pending
              if (status == 'pending') ...[
               Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _confirmApproval(groupDoc),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: offBlack,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                        child: const Text("Approve", style: TextStyle(color: lightGray)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _confirmRejection(groupDoc),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[100],
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                        child: const Text("Reject", style: TextStyle(color: offBlack)),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
  );
}

void _showEnlargedImage(BuildContext context, Uint8List imageBytes) {
  showDialog(
    context: context,
    builder: (ctx) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          // Set constraints to make it as big as you want
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: InteractiveViewer(
            // Allows pinch-to-zoom
            child: Image.memory(
              imageBytes,
              fit: BoxFit.contain,
            ),
          ),
        ),
      );
    },
  );
}



  /// Approves a group by updating its status to "approved" and adding an "approvedAt" timestamp.
  Future<void> _approveGroup(DocumentSnapshot groupDoc) async {
    final groupData = groupDoc.data() as Map<String, dynamic>;
    final List<dynamic> members = groupData['members'] ?? [];

    WriteBatch batch = FirebaseFirestore.instance.batch();
    DocumentReference groupRef =
        FirebaseFirestore.instance.collection('groups').doc(groupDoc.id);

    batch.update(groupRef, {
      'status': 'approved',
      'approvedAt': Timestamp.now(),
      'likes': 0
    });

    if (members.isNotEmpty) {
      QuerySnapshot submissionSnapshot = await FirebaseFirestore.instance
          .collection('user_submissions')
          .where('challengeDocId', isEqualTo: widget.challengeId)
          .where('user_id', whereIn: members)
          .get();

      for (DocumentSnapshot doc in submissionSnapshot.docs) {
        batch.update(doc.reference, {'status': 'approved'});
      }
    }

    await batch.commit();

    // Automatically send notifications for this approved group.
    await _sendApprovalNotificationForGroup(groupDoc);
  }

  /// Rejects a group by updating its status to "rejected".
  Future<void> _rejectGroup(DocumentSnapshot groupDoc) async {
    final groupData = groupDoc.data() as Map<String, dynamic>;
    final List<dynamic> members = groupData['members'] ?? [];

    WriteBatch batch = FirebaseFirestore.instance.batch();
    DocumentReference groupRef =
        FirebaseFirestore.instance.collection('groups').doc(groupDoc.id);

    batch.update(groupRef, {'status': 'rejected'});

    if (members.isNotEmpty) {
      QuerySnapshot submissionSnapshot = await FirebaseFirestore.instance
          .collection('user_submissions')
          .where('challengeDocId', isEqualTo: widget.challengeId)
          .where('user_id', whereIn: members)
          .get();

      for (DocumentSnapshot doc in submissionSnapshot.docs) {
        batch.update(doc.reference, {'status': 'rejected'});
      }
    }

    await batch.commit();
  }

  Future<void> _confirmApproval(DocumentSnapshot groupDoc) async {
  bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Confirm Approval", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to approve this submission?", style: TextStyle(fontSize: 12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel", style: TextStyle(fontSize: 12)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: kChipGreenBgOutline,
              foregroundColor: kChipGreenText,
              textStyle: const TextStyle(fontSize: 12),
            ),
            child: const Text("Approve"),
          ),
        ],
      );
    },
  );
  if (confirmed == true) {
    await _approveGroup(groupDoc);
  }
}

Future<void> _confirmRejection(DocumentSnapshot groupDoc) async {
  bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Confirm Rejection", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to reject this submission?", style: TextStyle(fontSize: 12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel", style: TextStyle(fontSize: 12)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.withOpacity(0.3) ,
              foregroundColor: Colors.red,
              textStyle: const TextStyle(fontSize: 12),
            ),
            child: const Text("Reject"),
          ),
        ],
      );
    },
  );
  if (confirmed == true) {
    await _rejectGroup(groupDoc);
  }
}


  /// Retrieves the main image from the "images" subcollection.
  Future<Uint8List?> _fetchMainImage(String challengeId) async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('challenges')
        .doc(challengeId)
        .collection('images')
        .where('type', isEqualTo: 'main')
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    String base64Str = snapshot.docs.first.get('base64') as String;
    return base64Decode(base64Str);
  }

  /// Returns a stream of groups filtered by the current _selectedStatusFilter.
  Stream<QuerySnapshot> _getGroupsStream() {
    final collection = FirebaseFirestore.instance
        .collection('groups')
        .where('challengeID', isEqualTo: widget.challengeId);

    if (_selectedStatusFilter == 'all') {
      return collection.snapshots();
    } else {
      return collection.where('status', isEqualTo: _selectedStatusFilter).snapshots();
    }
  }

 Widget _buildTopBar(BuildContext context) {
  return FutureBuilder<List>(
    future: Future.wait([
      // 1) The challenge document
      FirebaseFirestore.instance
          .collection('challenges')
          .doc(widget.challengeId)
          .get(),
      // 2) All groups for this challenge
      FirebaseFirestore.instance
          .collection('groups')
          .where('challengeID', isEqualTo: widget.challengeId)
          .get(),
      // 3) Approved groups for this challenge
      FirebaseFirestore.instance
          .collection('groups')
          .where('challengeID', isEqualTo: widget.challengeId)
          .where('status', isEqualTo: 'approved')
          .get(),
      // 4) The main challenge image
      _fetchMainImage(widget.challengeId),
    ]),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const SizedBox(
          height: 120,
          child: Center(child: CircularProgressIndicator()),
        );
      }

      // Extract results
      final challengeDoc = snapshot.data![0] as DocumentSnapshot;
      final allGroupsSnap = snapshot.data![1] as QuerySnapshot;
      final approvedGroupsSnap = snapshot.data![2] as QuerySnapshot;
      final Uint8List? imageBytes = snapshot.data![3] as Uint8List?;

      if (!challengeDoc.exists) {
        return const Center(child: Text("Challenge not found"));
      }

      // Parse challenge data
      Map<String, dynamic> challengeData =
          challengeDoc.data() as Map<String, dynamic>;
      final String title = challengeData['title'] ?? 'Challenge';
      final String image = challengeData['image'] ??  'lib/mobile/assets/images/fallback.png';
      final String about = challengeData['about'] ?? '';
      final String riddle = challengeData['riddle'] ?? '';
      final String submissionOptions =
          challengeData['submission_options'] ?? '';
      final String onlineNotice = challengeData['online_submission_notice'] ?? '';

      // Combine about + riddle for "Submission Requirements"
      final String submissionRequirements = "$about\n$riddle";
      // Combine submission_options + online_notice for "Submission Suggestions"
      final String submissionSuggestions = "$submissionOptions\n$onlineNotice";

      // Count total groups
      final int totalGroups = allGroupsSnap.docs.length;
      // Count approved groups
      final int approvedGroups = approvedGroupsSnap.docs.length;

      // Build challenge image
      Widget challengeImage = Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10), // fully rounded
              color: offBlack, // or any background color you like
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.memory(
                          base64Decode(image),
                fit: BoxFit.cover,
              ),
            ),
          );
 

        // Wrap the logo in a Container (or ClipRRect) with a borderRadius
          


      // Wrap the entire "top bar + stats" in a floating card
      return Container(
        margin: const EdgeInsets.all(16),  // spacing from screen edges
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              offset: const Offset(0, 4),
              blurRadius: 12,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ============ TOP BAR ROW ============
            Row(
              children: [
                // Challenge image
                challengeImage,
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                    "Challenge",
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 2),
                // Challenge title
                Text(
                    title,
                    style: const TextStyle(
                      color: offBlack,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  ]
                ),
                const Spacer(),
                // "Send Notifications" button
                ElevatedButton.icon(
                  onPressed: () => _sendCompletionNotifications(context),
                  icon: const Icon(Icons.notifications, color:lightGray ),
                  label: const Text("Release Results"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: offBlack,
                    foregroundColor: lightGray,
                  ),
                ),
                const SizedBox(width: 5),
                IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
              ],
            ),

            const SizedBox(height: 16),

            // ============ SUBMISSION STATISTICS HEADING ============
            const Text(
              "Submission Statistics",
              style: TextStyle(
                color: offBlack,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            // ============ ROW OF 4 WHITE CARDS ============
             Row(
        children: [
          Expanded(
            child: _buildTextStatCard(
              label: "Submission Requirements",
              content: submissionRequirements,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildTextStatCard(
              label: "Submission Suggestions",
              content: submissionSuggestions,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildNumberStatCard(
              label: "Number of Groups",
              number: totalGroups,
              icon: Icons.group,
              iconColor: kChipBlueText,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildNumberStatCard(
              label: "Approved Submissions",
              number: approvedGroups,
              icon: Icons.check_circle,
              iconColor: kChipGreenText,
            ),
          ),
         ],
        ),
          ]
        ),
      );
    },
  );
}

Widget _buildTextStatCard({
  required String label,
  required String content,
}) {
  return Container(
    // No fixed width or height so Expanded can fill the space
    height: 125,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card title
        Text(
          label,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),

        // Card content (multi-line text)
        Text(
          content,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 10,
          ),
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
}

Widget _buildNumberStatCard({
  required String label,
  required int number,
  required IconData icon,
  required Color iconColor,
}) {
  return Container(
    height: 125,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card title
        Text(
          label,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 12,
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
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            const Spacer(),

            // Icon in a circle
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}


bool showAll = true;
bool showApproved = false;
bool showPending = false;
bool showRejected = false;

Widget _buildFiltersPanel() {
  return Container(
    width: 220,
    margin: const EdgeInsets.all(16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.9),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          offset: const Offset(0, 4),
          blurRadius: 12,
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Filters",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: offBlack,
          ),
        ),
        const SizedBox(height: 12),

        const Text(
          "Submission Status",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 4),

        // ALL
        Row(
          children: [
            Checkbox(
              value: showAll,
              onChanged: (val) {
                setState(() {
                  showAll = val ?? false;
                  // If "All" is checked, we set the filter to "all"
                  // and uncheck the other boxes.
                  if (showAll) {
                    showApproved = false;
                    showPending = false;
                    showRejected = false;
                    _selectedStatusFilter = "all";
                  } else {
                    // If user unchecks 'All', you might want to handle differently
                    // e.g., set no filter or revert to something else
                    _selectedStatusFilter = "";
                  }
                });
              },
            ),
            const Text("All", style: TextStyle(fontSize: 12)),
          ],
        ),

        // APPROVED
        Row(
          children: [
            Checkbox(
              value: showApproved,
              onChanged: (val) {
                setState(() {
                  showApproved = val ?? false;
                  // If "Approved" is checked, set the filter
                  // and uncheck the others if you only want 1 filter at a time
                  if (showApproved) {
                    showAll = false;
                    showPending = false;
                    showRejected = false;
                    _selectedStatusFilter = "approved";
                  } else {
                    _selectedStatusFilter = "";
                  }
                });
              },
            ),
            const Text("Approved", style: TextStyle(fontSize: 12)),
          ],
        ),

        // PENDING
        Row(
          children: [
            Checkbox(
              value: showPending,
              onChanged: (val) {
                setState(() {
                  showPending = val ?? false;
                  if (showPending) {
                    showAll = false;
                    showApproved = false;
                    showRejected = false;
                    _selectedStatusFilter = "pending";
                  } else {
                    _selectedStatusFilter = "";
                  }
                });
              },
            ),
            const Text("Pending", style: TextStyle(fontSize: 12)),
          ],
        ),

        // REJECTED
        Row(
          children: [
            Checkbox(
              value: showRejected,
              onChanged: (val) {
                setState(() {
                  showRejected = val ?? false;
                  if (showRejected) {
                    showAll = false;
                    showApproved = false;
                    showPending = false;
                    _selectedStatusFilter = "rejected";
                  } else {
                    _selectedStatusFilter = "";
                  }
                });
              },
            ),
            const Text("Rejected", style: TextStyle(fontSize: 12)),
          ],
        ),
      ],
    ),
  );
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Remove the default app bar
      backgroundColor: Colors.transparent,
      body: Container(
        // Apply the gradient here
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFD71440), Color(0xFF181C62)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      child: Column(
        children: [
          // Top bar with challenge image + title + notifications button
          _buildTopBar(context),

          // Main content area
          Expanded(
            child: Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    // Left-side filter panel in a flexible container
    Flexible(
  flex: 0, // so it doesn't expand, only wraps its content
  child: SingleChildScrollView(
    child: _buildFiltersPanel(),
  ),
),


    // Right-side main content
    Expanded(
      child: SingleChildScrollView(
        child: StreamBuilder<QuerySnapshot>(
          stream: _getGroupsStream(),
          builder: (context, groupSnapshot) {
            if (groupSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!groupSnapshot.hasData || groupSnapshot.data!.docs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("No groups found for this challenge!", style: TextStyle(color: lightGray),),
              );
            }
            final groupDocs = groupSnapshot.data!.docs;
            return Wrap(
              alignment: WrapAlignment.start,
              spacing: 16,
              runSpacing: 16,
              children: groupDocs.map((groupDoc) {
                return _buildGroupCard(
                  context,
                  groupDoc,
                  _fetchSubmissionsForGroup,
                  _approveGroup,
                  _rejectGroup,
                );
              }).toList(),
            );
          },
        ),
      ),
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
