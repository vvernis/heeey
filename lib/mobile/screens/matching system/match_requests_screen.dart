import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'dart:typed_data';

import 'matchchat_screen.dart';
import 'profile_match.dart';

/// Your colors
const Color darkCharcoal = Color(0xFF29292B);
const Color offBlack = Color(0xFF343436);
const Color vividYellow = Color(0xFFd7ed73);
const Color lightGray = Color(0xFFF0F0E6);

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
      final chatId = senderId.compareTo(receiverId) < 0
          ? '$senderId-$receiverId'
          : '$receiverId-$senderId';

      final chatDoc = FirebaseFirestore.instance.collection('chats').doc(chatId);

      final snapshot = await chatDoc.get();
      if (!snapshot.exists) {
        // Create the chat document if it doesn't exist
        await chatDoc.set({
          'userIds': [senderId, receiverId],
          'lastMessage': '',
          'lastMessageTimestamp': FieldValue.serverTimestamp(),
        });
      }

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

  Widget _buildToggleButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16.0),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: offBlack,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Received Requests
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isViewingSentRequests
                      ? Colors.transparent
                      : vividYellow, // highlight if active
                  foregroundColor:
                      isViewingSentRequests ? lightGray : offBlack, // text color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  elevation: 0,
                ),
                onPressed: () {
                  setState(() {
                    isViewingSentRequests = false;
                  });
                },
                child: const Text('Received Requests'),
              ),
            ),
            // Sent Requests
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isViewingSentRequests ? vividYellow : Colors.transparent,
                  foregroundColor:
                      isViewingSentRequests ? offBlack : lightGray,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  elevation: 0,
                ),
                onPressed: () {
                  setState(() {
                    isViewingSentRequests = true;
                  });
                },
                child: const Text('Sent Requests'),
              ),
            ),
          ],
        ),
      ),
    );
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
      backgroundColor: darkCharcoal,
      appBar: AppBar(
        title: const Text(
          'Match Requests',
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
          icon: const Icon(
            Icons.arrow_back_ios,
            color: lightGray,
            size: 21,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          _buildToggleButtons(),
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
                    child: Text(
                      'No match requests at the moment.',
                      style: TextStyle(color: lightGray),
                    ),
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
                    final String activity = matchRequest['activity'];

                  

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .get(),
                      builder: (context, userSnapshot) {
                        if (!userSnapshot.hasData) {
                          return const SizedBox();
                        }

                        final userData = userSnapshot.data!;
                        final String name = userData['name'] ?? 'Unknown';
                        final String course =
                            userData['mastercourse'] ?? 'Unknown Course';
                        final String aboutMe = userData['aboutMe'] ?? '';

                        // If the base64 decoding fails, fallback to empty
                        final String base64Img =
                            userData['profilePic'] ?? '';
                        Uint8List decodedImage;
                        try {
                          decodedImage = base64.decode(base64Img);
                        } catch (_) {
                          decodedImage = Uint8List(0);
                        }


                        return GestureDetector(
                          onTap: () {
                            // Navigate to ProfileMatchWidget on card tap
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ProfileMatchWidget(uid: userId),
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
                            // Instead of a fixed SizedBox, use IntrinsicHeight
                            child: IntrinsicHeight(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // Rectangular image of fixed width
                                    Container(
                                      width: 90,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        child: decodedImage.isNotEmpty
                                            ? Image.memory(
                                                decodedImage,
                                                fit: BoxFit.cover,
                                              )
                                            : Container(
                                                color: Colors.grey,
                                                child: const Center(
                                                  child: Text('No image'),
                                                ),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),

                                    // Column with name, course, about me
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                          Text(
                                            name,
                                            style: const TextStyle(
                                              fontFamily: 'Karla',
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: lightGray,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(width: 4),
                                          Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: vividYellow.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: 
                               
                                              Text(
                                                activity,
                                                style: const TextStyle(
                                                  fontFamily: 'Karla',
                                                  fontSize: 12,
                                                  color: vividYellow,
                                                ),
                                              ),

                                        ),
                                            ]
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            course,
                                            style: const TextStyle(
                                              fontFamily: 'Karla',
                                              fontSize: 14,
                                              color: Color(0xFFC0C0C0),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 8),
                                          Expanded(
                                            child: Text(
                                              'About Me: $aboutMe',
                                              style: const TextStyle(
                                                fontFamily: 'Karla',
                                                fontSize: 14,
                                                color: Color(0xFFD0D0D0),
                                              ),
                                              maxLines: 4,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          // Accept/Reject if user is the receiver & status is 'pending'
                                          if (!isViewingSentRequests &&
                                              status == 'pending') ...[
                                            const SizedBox(height: 8),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                // Accept icon button
                                                ElevatedButton(
                                                  onPressed: () {
                                                    FirebaseFirestore.instance
                                                        .collection(
                                                            'matchRequests')
                                                        .doc(matchRequest.id)
                                                        .update({
                                                      'status': 'accepted'
                                                    });

                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          'You accepted $name\'s match request!',
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        darkCharcoal
                                                            .withOpacity(0.2),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              16),
                                                    ),
                                                  ),
                                                  child: const Icon(
                                                    Icons.favorite,
                                                    color: Color(0xffcc6969),
                                                    size: 13,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                // Reject icon button
                                                ElevatedButton(
                                                  onPressed: () {
                                                    FirebaseFirestore.instance
                                                        .collection(
                                                            'matchRequests')
                                                        .doc(matchRequest.id)
                                                        .update({
                                                      'status': 'rejected'
                                                    });

                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          'You rejected $name\'s match request!',
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        darkCharcoal
                                                            .withOpacity(0.2),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              16),
                                                    ),
                                                  ),
                                                  child: const Icon(
                                                    Icons.close,
                                                    color: lightGray,
                                                    size: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    // Right column for status & Chat
                                    // Center them vertically
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        _buildStatusCircle(status),
                                        const SizedBox(height: 8),
                                        if (status == 'accepted')
                                          ElevatedButton(
                                            onPressed: () {
                                              final receiverId =
                                                  matchRequest['receiverId'];
                                              createOrGetChat(
                                                senderId: currentUserId,
                                                receiverId: receiverId,
                                                context: context,
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: vividYellow,
                                              // Make the Chat button smaller
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 6,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                            ),
                                            child: Text(
                                              'Chat',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: offBlack,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
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

  /// Build a circular button to visually represent the status
  Widget _buildStatusCircle(String status) {
    // Adjust these to your liking
    Color bgColor;
    String displayText;
    TextStyle textStyle = const TextStyle(
      fontFamily: 'Karla',
      color: darkCharcoal,
      fontWeight: FontWeight.bold,
      fontSize: 18,
    );

    switch (status) {
      case 'pending':
        bgColor = const Color(0xffffde5a).withOpacity(0.5);
        displayText = '👋';
        break;
      case 'accepted':
        bgColor = const Color(0xff2B6A06).withOpacity(0.5);
        displayText = '👋';
        break;
      case 'rejected':
        bgColor = const Color(0xffcc6969).withOpacity(0.5);
        displayText = '👋';
        break;
      default:
        bgColor = Colors.grey.withOpacity(0.5);
        displayText = '👋';
    }

    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        shape: const CircleBorder(),
      ),
      child: Text(
        displayText,
        style: textStyle,
      ),
    );
  }
}
