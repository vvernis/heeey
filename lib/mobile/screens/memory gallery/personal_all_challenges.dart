import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:heeey/mobile/screens/memory%20gallery/memory_gallery.dart';
import 'package:intl/intl.dart';
import 'personal_challenge_detail.dart'; // Make sure you have this page defined

const Color darkCharcoal = Color(0xFF29292B);
const Color offBlack = Color(0xFF343436);
const Color vividYellow = Color(0xFFd7ed73);
const Color lightGray = Color(0xFFF0F0E6);


class FullChallengePassportPage extends StatelessWidget {
  final String userId;

  const FullChallengePassportPage({Key? key, required this.userId}) : super(key: key);

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


   Widget _buildChallengePassport() {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('joined_challenges')
        .where('user_id', isEqualTo: userId)
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


// Inside your ListView.builder in _buildChallengePassport():
return ListView.builder(
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  itemCount: joinedDocs.length,
  itemBuilder: (context, index) {
    final joinedData = joinedDocs[index].data() as Map<String, dynamic>;
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
          onTap: () {
            // Navigate to your detail page
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChallengeDetailPage(challengeId: challengeId),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      body: _buildChallengePassport(),
    );
  }
}
