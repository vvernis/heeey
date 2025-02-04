import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_match.dart';

class MatchingScreen extends StatelessWidget {
  final Map<String, dynamic> filters;

  const MatchingScreen({super.key, required this.filters});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Match',
          style: TextStyle(fontFamily: 'Karla', fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
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

            final placeOfInterest = doc['placeOfInterest'] as String? ?? '';
            final Timestamp? earliestTimestamp = doc['earliestDate'] as Timestamp?;
            final Timestamp? latestTimestamp = doc['latestDate'] as Timestamp?;

            if (earliestTimestamp == null || latestTimestamp == null) {
              return false; // Skip invalid documents
            }

            final earliestDate = earliestTimestamp.toDate();
            final latestDate = latestTimestamp.toDate();

            final filterPlace = filters['placeOfInterest'] as String? ?? '';
            final filterEarliestDate = filters['earliestDate'] as DateTime?;
            final filterLatestDate = filters['latestDate'] as DateTime?;

            // Debugging logs
            print('Evaluating Match:');
            print('Place: $placeOfInterest');
            print('Date Range: $earliestDate to $latestDate');
            print('Filter Place: $filterPlace');
            print('Filter Date Range: $filterEarliestDate to $filterLatestDate');

            // Check for overlapping dates
            final dateOverlaps = (filterEarliestDate == null || filterLatestDate == null) ||
                (earliestDate.isBefore(filterLatestDate) && latestDate.isAfter(filterEarliestDate));

            // Match conditions
            final placeMatches = filterPlace.isEmpty || placeOfInterest.contains(filterPlace);

            return placeMatches && dateOverlaps;
          }).toList();

          // Step 2: Group matches by ownerId and placeOfInterest
          final groupedMatches = <String, Map<String, dynamic>>{};
          for (var match in matches) {
            final ownerId = match['owner'];
            final placeOfInterest = match['placeOfInterest'];

            final key = '$ownerId|$placeOfInterest';
            final earliestDate = (match['earliestDate'] as Timestamp).toDate();
            final latestDate = (match['latestDate'] as Timestamp).toDate();

            if (!groupedMatches.containsKey(key)) {
              groupedMatches[key] = {
                'ownerId': ownerId,
                'placeOfInterest': placeOfInterest,
                'dateRanges': <Map<String, DateTime>>[
                  {'start': earliestDate, 'end': latestDate},
                ],
              };
            } else {
              // Add non-overlapping date ranges
              (groupedMatches[key]!['dateRanges'] as List<Map<String, DateTime>>).add({
                'start': earliestDate,
                'end': latestDate,
              });
            }
          }

          // Step 3: Build UI
          if (groupedMatches.isEmpty) {
            print('No matches found!');
            return const Center(child: Text('No matches found.'));
          }

          return ListView(
            children: groupedMatches.values.map((match) {
              final ownerId = match['ownerId'] as String;
              final placeOfInterest = match['placeOfInterest'] as String;
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
                  final String profilePicture = userData['images']['place'] ?? '';
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
                      color: Colors.grey[900],
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundImage: NetworkImage(profilePicture),
                                  radius: 30,
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontFamily: 'Karla', 
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Place: $placeOfInterest',
                              style: const TextStyle(
                                fontFamily: 'Karla', 
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Dates:',
                              style: const TextStyle(
                                fontFamily: 'Karla', 
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            ...dateRanges.map((range) {
                              return Text(
                                '${range['start']!.toShortDate()} to ${range['end']!.toShortDate()}',
                                style: const TextStyle(
                                  fontFamily: 'Karla', 
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              );
                            }),
                            const SizedBox(height: 8),
                            Text(
                              'About Me: $aboutMe',
                              style: const TextStyle(
                                fontFamily: 'Karla', 
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () {
                                // Fetch the sender's name dynamically
                                FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(currentUserId)
                                    .get()
                                    .then((senderSnapshot) {
                                  if (senderSnapshot.exists) {
                                    final senderName = senderSnapshot.data()?['name'] ?? 'Unknown';

                                    // Add match request to Firestore
                                    FirebaseFirestore.instance.collection('matchRequests').add({
                                      'receiverId': ownerId,
                                      'senderId': currentUserId,
                                      'placeOfInterest': placeOfInterest,
                                      'status': 'pending',
                                      'timestamp': Timestamp.now(),
                                    });

                                    // Add notification to Firestore
                                    FirebaseFirestore.instance.collection('notifications').add({
                                      'receiverId': ownerId,
                                      'senderId': currentUserId,
                                      'message': 'You have a new match request from $senderName!',
                                      'type': 'matchRequest',
                                      'isRead': false,
                                      'timestamp': Timestamp.now(),
                                    });

                                    // Show confirmation SnackBar
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Match request sent to $name!')),
                                    );
                                  } else {
                                    // Handle missing sender data
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Failed to fetch sender details.')),
                                    );
                                  }
                                }).catchError((error) {
                                  // Handle any errors during the fetch
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed to send match request: $error')),
                                  );
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text('Say Hey!'),
                            )
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
    return '${day}/${month}/${year}';
  }
}
