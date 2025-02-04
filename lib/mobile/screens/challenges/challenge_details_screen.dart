import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChallengeDetailsScreen extends StatefulWidget {
  final String challengeId; 

  const ChallengeDetailsScreen({super.key, required this.challengeId});

  @override
  _ChallengeDetailsScreenState createState() => _ChallengeDetailsScreenState();
}

class _ChallengeDetailsScreenState extends State<ChallengeDetailsScreen> {
  Future<Map<String, dynamic>?> fetchChallengeDetails() async {
    try {
      var document = await FirebaseFirestore.instance.collection('challenges').doc(widget.challengeId).get();
      if (document.exists) {
        return document.data();
      }
    } catch (e) {
      print("Error fetching challenge details: $e");
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Challenge Details'),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {
              // actions here
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: fetchChallengeDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text("Failed to load challenge details."));
          }

          var data = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                const SizedBox(height: 20),
                Text(
                  data['title'] ?? 'No title',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text("Period: ${data['start_date']} - ${data['end_date']}"),
                Text("Mode: ${data['mode']}"),
                Text("Type: ${data['type']}"),
                const SizedBox(height: 10),
                const Text("About the Challenge", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(data['about'] ?? "No additional information available."),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}
