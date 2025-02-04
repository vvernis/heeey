import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StatisticsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Statistics"),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('challenges').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData) {
            return Center(child: Text("No data available"));
          }

          int totalParticipants = snapshot.data!.docs
              .map((doc) => doc.get('participants').length as int)
              .fold(0, (prev, length) => prev + length);

          var mostPopularChallenge = snapshot.data!.docs
              .reduce((curr, next) => (curr.get('participants').length > next.get('participants').length) ? curr : next);

          return SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 20),
                Text('Total Participants: $totalParticipants', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 20),
                Text('Most Popular Challenge: ${mostPopularChallenge.get('title')} with ${mostPopularChallenge.get('participants').length} participants',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          );
        },
      ),
    );
  }
}
