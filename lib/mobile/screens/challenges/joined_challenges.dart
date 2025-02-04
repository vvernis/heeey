import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'groupchat_screen.dart';

class JoinedChallengesScreen extends StatelessWidget {
  const JoinedChallengesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Joined Challenges',
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
        stream: FirebaseFirestore.instance
            .collection('joined_challenges')
            .where('user_id', isEqualTo: currentUserId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error loading joined challenges.'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No challenges joined yet.'));
          }

          final joinedChallenges = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: joinedChallenges.length,
            itemBuilder: (context, index) {
              final data = joinedChallenges[index].data() as Map<String, dynamic>;
              return _buildJoinedChallengeCard(context, data);
            },
          );
        },
      ),
    );
  }

  Widget _buildJoinedChallengeCard(BuildContext context, Map<String, dynamic> data) {
    final String title = data['title'] ?? 'Unknown Challenge';
    final String mode = data['mode'] ?? 'TBD';
    final String type = data['type'] ?? 'TBD';
    final String imageCode = data['image'] ?? '';
    final DateTime startDate = (data['start_date'] as Timestamp?)?.toDate() ?? DateTime.now();
    final DateTime endDate = (data['end_date'] as Timestamp?)?.toDate() ?? DateTime.now();

    final String formattedPeriod = '${DateFormat('d MMM').format(startDate)} - ${DateFormat('d MMM').format(endDate)}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Karla', 
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Text(
              'PERIOD: $formattedPeriod',
              style: const TextStyle(
                fontFamily: 'Karla', 
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            Text(
              'MODE: $mode',
              style: const TextStyle(
                fontFamily: 'Karla', 
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            Text(
              'TYPE: $type',
              style: const TextStyle(
                fontFamily: 'Karla', 
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
