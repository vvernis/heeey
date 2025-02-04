import 'package:cloud_firestore/cloud_firestore.dart';

class ChallengeModel {
  final String id;
  final String title;
  final String description;
  final String period;
  final String mode;
  final String type;
  final List<String> participants;
  final String imageUrl;

  ChallengeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.period,
    required this.mode,
    required this.type,
    required this.participants,
    required this.imageUrl,
  });

  factory ChallengeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChallengeModel(
      id: doc.id,
      title: data['title'],
      description: data['description'],
      period: data['period'],
      mode: data['mode'],
      type: data['type'],
      participants: List<String>.from(data['participants']),
      imageUrl: data['imageUrl'],
    );
  }
}
