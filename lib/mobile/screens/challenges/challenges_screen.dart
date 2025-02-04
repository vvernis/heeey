import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'challenge_details_screen.dart';

class ChallengesScreen extends StatelessWidget {
  const ChallengesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Challenges',
          style: TextStyle(fontFamily: 'Karla', color: Colors.black),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('challenges').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error fetching challenges.'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No challenges available.'));
          }

          final challenges = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: challenges.length,
            itemBuilder: (context, index) {
              final challenge = challenges[index];
              return _buildChallengeCard(context, challenge, currentUserId);
            },
          );
        },
      ),
    );
  }

  Widget _buildChallengeCard(
      BuildContext context, QueryDocumentSnapshot challenge, String? userId) {
    final data = challenge.data() as Map<String, dynamic>;
    final String challengeId = challenge.id;

    final String title = data['title'] ?? 'Unknown Challenge';
    final String mode = data['mode'] ?? 'TBD';
    final String type = data['type'] ?? 'TBD';
    final String imageCode =
        data['image'] ?? 'lib/mobile/assets/images/fallback.png';
    final DateTime startDate =
        (data['start_date'] as Timestamp?)?.toDate() ?? DateTime.now();
    final DateTime endDate =
        (data['end_date'] as Timestamp?)?.toDate() ?? DateTime.now();

    final String formattedPeriod =
        '${DateFormat('d MMM').format(startDate)} - ${DateFormat('d MMM').format(endDate)}';

    return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChallengeDetailsScreen(challengeId: challengeId),
        ),
      );
    },
    
    child: Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: 
                CircleAvatar(
                    radius: 30,
                    backgroundImage: MemoryImage(base64Decode(imageCode)),
                  ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Karla', 
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis, // Handle long text
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "PERIOD: $formattedPeriod\nMODE: $mode\nTYPE: $type",
                    style: const TextStyle(
                      fontFamily: 'Karla', 
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('joined_challenges')
                  .where('user_id', isEqualTo: userId)
                  .where('title', isEqualTo: title)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                final alreadyJoined =
                    snapshot.data != null && snapshot.data!.docs.isNotEmpty;

                return Flexible(
                  child: ElevatedButton(
                    onPressed: () {
                      if (alreadyJoined) {
                        // Navigate to Group Selection Screen
                        Navigator.pushNamed(
                          context,
                          '/group-selection',
                          arguments: challengeId,
                        );
                      } else {
                        // Join the challenge
                        _joinChallenge(userId!, challenge).then((_) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Joined $title successfully!'),
                            ),
                          );
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: alreadyJoined
                          ? Colors.green
                          : Colors.grey[800],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      alreadyJoined ? 'HEEEY!' : 'Join',
                      style: const TextStyle(fontFamily: 'Karla', fontSize: 14),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    )
    );
  }

  Future<void> _joinChallenge(String userId, QueryDocumentSnapshot challenge) async {
    final data = challenge.data() as Map<String, dynamic>;
    final String challengeId = challenge.id;

    await FirebaseFirestore.instance.collection('joined_challenges').add({
      'user_id': userId,
      'challenge_id': challengeId,
      'joined_at': FieldValue.serverTimestamp(),
    });
  }
}
