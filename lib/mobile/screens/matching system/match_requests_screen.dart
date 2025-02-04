import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_match.dart';
import 'matchchat_screen.dart';

class MatchRequestsScreen extends StatefulWidget {
  const MatchRequestsScreen({super.key});

  @override
  State<MatchRequestsScreen> createState() => _MatchRequestsScreenState();
}

class _MatchRequestsScreenState extends State<MatchRequestsScreen> {
  bool isViewingSentRequests = false;

    void createOrGetChat({
  required String senderId,
  required String receiverId,
  required BuildContext context,
}) async {
  try {
    // Ensure consistent chatId generation: the smaller user ID comes first
    final chatId = senderId.compareTo(receiverId) < 0
        ? '$senderId-$receiverId'
        : '$receiverId-$senderId';

    final chatDoc = FirebaseFirestore.instance.collection('chats').doc(chatId);

    // Check if the chat document exists
    final snapshot = await chatDoc.get();

    if (!snapshot.exists) {
      // If the chat doesn't exist, create a new one
      await chatDoc.set({
        'userIds': [senderId, receiverId],
        'lastMessage': '',
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
      });
    }

    // Navigate to the ChatScreen with the chatId, senderId, and receiverId
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          chatId: chatId,
          senderId: senderId,
          receiverId: receiverId,
        ),
      ),
    );
  } catch (e) {
    debugPrint('Error creating/getting chat: $e');
  }
}



  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      return const Scaffold(
        body: Center(
          child: Text('You need to be logged in to view match requests.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Match Requests',
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
      body: Column(
        children: [
          // Toggle Button for Sent/Received Requests
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    isViewingSentRequests = false;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isViewingSentRequests ? Colors.grey : Colors.blue,
                ),
                child: const Text('Received Requests'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    isViewingSentRequests = true;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isViewingSentRequests ? Colors.blue : Colors.grey,
                ),
                child: const Text('Sent Requests'),
              ),
            ],
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('matchRequests')
                  .where(
                    isViewingSentRequests ? 'senderId' : 'receiverId',
                    isEqualTo: currentUserId,
                  )
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final requests = snapshot.data!.docs;

                if (requests.isEmpty) {
                  return const Center(
                    child: Text('No match requests at the moment.'),
                  );
                }

                return ListView.builder(
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final matchRequest = requests[index];
                    final String userId = isViewingSentRequests
                        ? matchRequest['receiverId']
                        : matchRequest['senderId'];
                    final String status = matchRequest['status'];
                    final Timestamp timestamp = matchRequest['timestamp'];
                    final DateTime dateTime = timestamp.toDate();

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
                      builder: (context, userSnapshot) {
                        if (!userSnapshot.hasData) {
                          return const SizedBox(); // Show nothing while loading user data
                        }

                        final userData = userSnapshot.data!;
                        final String name = userData['name'] ?? 'Unknown';
                        final String course = userData['masterCourse'] ?? 'Unknown Course';
                        final String aboutMe = userData['aboutMe'] ?? '';
                        final String profilePicture = userData['images']['place'] ?? '';

                        return GestureDetector(
                          onTap: () {
                            // Navigate to the profile of the user
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProfileMatchWidget(uid: userId),
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
                            color: Colors.white,
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
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              style: const TextStyle(
                                                fontFamily: 'Karla',
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                              overflow: TextOverflow.ellipsis, // Add ellipsis to prevent overflow
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              course,
                                              style: const TextStyle(
                                                fontFamily: 'Karla',
                                                fontSize: 14,
                                                color: Colors.grey,
                                              ),
                                              overflow: TextOverflow.ellipsis, // Add ellipsis to prevent overflow
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8), // Add some spacing
                                      Icon(
                                        status == 'accepted'
                                            ? Icons.check_circle
                                            : status == 'rejected'
                                                ? Icons.cancel
                                                : Icons.pending,
                                        color: status == 'accepted'
                                            ? Colors.green
                                            : status == 'rejected'
                                                ? Colors.red
                                                : Colors.amber,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'About Me: $aboutMe',
                                    style: const TextStyle(
                                      fontFamily: 'Karla',
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                    maxLines: 2, // Limit the number of lines
                                    overflow: TextOverflow.ellipsis, // Add ellipsis if text overflows
                                  ),
                                  const SizedBox(height: 8),
                                  if (!isViewingSentRequests)
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        ElevatedButton(
                                          onPressed: () {
                                            if (status == 'pending') {
                                              FirebaseFirestore.instance
                                                  .collection('matchRequests')
                                                  .doc(matchRequest.id)
                                                  .update({'status': 'accepted'});

                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('You accepted $name\'s match request!'),
                                                ),
                                              );
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                          ),
                                          child: const Text('Accept'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            if (status == 'pending') {
                                              FirebaseFirestore.instance
                                                  .collection('matchRequests')
                                                  .doc(matchRequest.id)
                                                  .update({'status': 'rejected'});

                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('You rejected $name\'s match request!'),
                                                ),
                                              );
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                          ),
                                          child: const Text('Reject'),
                                        ),
                                      ],
                                    ),
                                  if (status == 'accepted')
                                    ElevatedButton(
                                      onPressed: () {
                                        final receiverId = matchRequest['receiverId'];
                                        createOrGetChat(
                                          senderId: FirebaseAuth.instance.currentUser!.uid, // Current user
                                          receiverId: receiverId, // ID of the user to chat with
                                          context: context, // Pass the BuildContext
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                      ),
                                      child: const Text('Chat'),
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
        ],
      ),
    );
  }
}
