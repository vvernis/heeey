import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_match.dart';
import 'dart:convert';

const Color darkCharcoal = Color(0xFF29292B);
const Color offBlack = Color(0xFF343436);
const Color vividYellow = Color(0xFFd7ed73);
const Color lightGray = Color(0xFFF0F0E6);

class MatchingScreen extends StatelessWidget {
  final Map<String, dynamic> filters;

  MatchingScreen({super.key, required this.filters});

  // List of activity mappings
  final List<Map<String, dynamic>> activities = [
    {'name': 'Sport', 'icon': Icons.directions_run},
    {'name': 'Attractions', 'icon': Icons.attractions},
    {'name': 'Museums', 'icon': Icons.museum},
    {'name': 'Talk', 'icon': Icons.record_voice_over},
    {'name': 'Movie', 'icon': Icons.movie},
    {'name': 'Eat', 'icon': Icons.restaurant},
    {'name': 'Study', 'icon': Icons.school},
    {'name': 'Gaming', 'icon': Icons.games},
    {'name': 'Others', 'icon': Icons.add_circle_outline},
  ];

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Potential Matches',
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
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('filters').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // Step 1: Filter matches
          final matches = snapshot.data!.docs.where((doc) {
            final ownerId = doc['owner'] as String? ?? '';
            if (ownerId == currentUserId) {
              return false; // Exclude the current user
            }

            final activity = doc['activity'] as String? ?? '';
            final otherActivity = doc['otherActivity'] as String? ?? '';
            final Timestamp? earliestTimestamp = doc['earliestDate'] as Timestamp?;
            final Timestamp? latestTimestamp = doc['latestDate'] as Timestamp?;

            if (earliestTimestamp == null || latestTimestamp == null) {
              return false; // Skip invalid documents
            }

            final earliestDate = earliestTimestamp.toDate();
            final latestDate = latestTimestamp.toDate();

            final filterActivity = filters['activity'] as String? ?? '';
            final filterOtherActivity = filters['otherActivity'] as String? ?? '';
            final filterEarliestDate = filters['earliestDate'] as DateTime?;
            final filterLatestDate = filters['latestDate'] as DateTime?;

            // Define effective document activity: if the doc’s activity is "Others" and otherActivity is provided, use that.
            final effectiveDocActivity = (activity == 'Others' && otherActivity.trim().isNotEmpty)
                ? otherActivity.trim()
                : activity;

            // Define effective filter activity: if the filter's activity is "Others" and a specific value was provided, use that.
            final effectiveFilterActivity = (filterActivity == 'Others' && filterOtherActivity.trim().isNotEmpty)
                ? filterOtherActivity.trim()
                : filterActivity;

            // Now, check for a match (you can use a case-insensitive contains match or an exact comparison)
            bool activityMatch = effectiveDocActivity.toLowerCase().contains(effectiveFilterActivity.toLowerCase());


            // Check for overlapping dates
            final dateOverlaps = (filterEarliestDate == null || filterLatestDate == null) ||
                (earliestDate.isBefore(filterLatestDate!) && latestDate.isAfter(filterEarliestDate!));


            return activityMatch && dateOverlaps;
          }).toList();

          // Step 2: Group matches by ownerId and activity
          final groupedMatches = <String, Map<String, dynamic>>{};
          for (var match in matches) {
            final ownerId = match['owner'];
            final activity = match['activity'];
            final otherActivity = (match['otherActivity'] as String? ?? '').trim();
                // Check if the original activity was "Others"
            final bool originallyOthers = (activity as String).toLowerCase() == 'others';

            // Use effectiveActivity: if the stored activity is 'Others' and otherActivity is non-empty, use it.
            final effectiveActivity = (activity == 'Others' && otherActivity.isNotEmpty)
                ? otherActivity
                : activity;
            
  

            final key = '$ownerId|$effectiveActivity';
            final earliestDate = (match['earliestDate'] as Timestamp).toDate();
            final latestDate = (match['latestDate'] as Timestamp).toDate();

            if (!groupedMatches.containsKey(key)) {
              groupedMatches[key] = {
                'ownerId': ownerId,
                'activity': effectiveActivity,
                'otherActivity': otherActivity,
                'originallyOthers': originallyOthers, // Store the flag here.
                'dateRanges': <Map<String, DateTime>>[
                  {'start': earliestDate, 'end': latestDate},
                ],
              };
            } else {
              (groupedMatches[key]!['dateRanges'] as List<Map<String, DateTime>>).add({
                'start': earliestDate,
                'end': latestDate,
              });
            }
          }

          // Step 3: Build UI
          if (groupedMatches.isEmpty) {
            return const Center(child: Text('No matches found.'));
          }

          return ListView(
            children: groupedMatches.values.map((match) {
              final ownerId = match['ownerId'] as String;
              final String rawActivity = (match['activity'] as String).trim();

              // Determine if the document originally indicated "Others"
              final bool isOthers = rawActivity.toLowerCase() == 'others';


              // Use the custom value (if provided) when "Others" is selected,
              // otherwise just use the raw activity.
              final String effectiveActivity = (isOthers &&
                      match.containsKey('otherActivity') &&
                      (match['otherActivity'] as String).trim().isNotEmpty)
                  ? (match['otherActivity'] as String).trim()
                  : rawActivity;

              // Get the flag from grouping.
              final bool originallyOthers = match['originallyOthers'] as bool? ?? false;

              // Use the custom icon if originallyOthers is true.
              final IconData iconToShow = originallyOthers
                  ? Icons.add_circle_outline
                  : activities.firstWhere(
                      (act) =>
                          (act['name'] as String).toLowerCase() ==
                          effectiveActivity.toLowerCase(),
                      orElse: () => {'icon': Icons.help_outline},
                    )['icon'] as IconData;



              final List<Map<String, DateTime>> dateRanges =
                  match['dateRanges'] as List<Map<String, DateTime>>;

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(ownerId).get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const SizedBox(); // Show nothing while loading user data
                  }

                  final userData = userSnapshot.data!;
                  final String name = userData['name'] ?? 'Unknown';
                  final String aboutMe = userData['aboutMe'] ?? '';
                  final String profilePicture = userData['profilePic'] ?? '';

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileMatchWidget(uid: ownerId),
                        ),
                      );
                    },
                    child: Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      color: offBlack,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          // Center all children vertically.
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Rectangular image
                            Container(
                              width: 80,
                              height: 110,
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: MemoryImage(base64Decode(profilePicture)),
                                  fit: BoxFit.cover,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Align text column at the top left
                            Expanded(
                              child: Align(
                                alignment: Alignment.topLeft,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontFamily: 'Karla',
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: lightGray,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'About Me: $aboutMe',
                                      style: const TextStyle(
                                        fontFamily: 'Karla',
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.calendar_today,
                                          color: vividYellow,
                                          size: 15,
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            dateRanges
                                                .map((range) =>
                                                    '${range['start']!.toShortDate()} to ${range['end']!.toShortDate()}')
                                                .join(' / '),
                                            style: const TextStyle(
                                              fontFamily: 'Karla',
                                              fontSize: 13,
                                              color: lightGray,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Builder(
                                      builder: (context) {
                                     
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: vividYellow.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                iconToShow,
                                                size: 15,
                                                color: vividYellow,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                effectiveActivity,
                                                style: const TextStyle(
                                                  fontFamily: 'Karla',
                                                  fontSize: 12,
                                                  color: vividYellow,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Button on the right, vertically centered
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton(
                                  onPressed: () async {
                                    try {
                                      // 1) Check if there's already a pending or accepted request
                                      final existingRequest = await FirebaseFirestore.instance
                                          .collection('matchRequests')
                                          .where('senderId', isEqualTo: currentUserId)
                                          .where('receiverId', isEqualTo: ownerId)
                                          .where('status', whereIn: ['pending', 'accepted'])
                                          .limit(1)
                                          .get();

                                      // If there's already one doc, user has requested or matched
                                      if (existingRequest.docs.isNotEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'You have already requested or matched with this person!',
                                            ),
                                          ),
                                        );
                                        return;
                                      }

                                      // 2) If not found, create a new request
                                      final senderSnapshot = await FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(currentUserId)
                                          .get();

                                      if (senderSnapshot.exists) {
                                        final senderName =
                                            senderSnapshot.data()?['name'] ?? 'Unknown';

                                        await FirebaseFirestore.instance
                                            .collection('matchRequests')
                                            .add({
                                          'receiverId': ownerId,
                                          'senderId': currentUserId,
                                          'activity': effectiveActivity,
                                          'status': 'pending',
                                          'timestamp': Timestamp.now(),
                                        });

                                        await FirebaseFirestore.instance
                                            .collection('notifications')
                                            .add({
                                          'receiverId': ownerId,
                                          'senderId': currentUserId,
                                          'message':
                                              'You have a new match request from $senderName!',
                                          'type': 'matchRequest',
                                          'isRead': false,
                                          'timestamp': Timestamp.now(),
                                        });

                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Match request sent to $name!'),
                                          ),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Failed to fetch sender details.'),
                                          ),
                                        );
                                      }
                                    } catch (error) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content:
                                              Text('Failed to send match request: $error'),
                                        ),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: vividYellow.withOpacity(0.5),
                                    shape: const CircleBorder(),
                                  ),
                                  child: const Text(
                                    '👋',
                                    style: TextStyle(
                                      fontFamily: 'Karla',
                                      color: darkCharcoal,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

extension DateTimeFormatter on DateTime {
  String toShortDate() {
    return '$day/$month/$year';
  }
}
