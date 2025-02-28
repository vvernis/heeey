import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'group_selection_screen.dart'; // Ensure this import points to your GroupSelectionScreen file.

// Your color scheme
const Color darkCharcoal = Color(0xFF29292B);
const Color offBlack = Color(0xFF343436);
const Color vividYellow = Color(0xFFd7ed73);
const Color lightGray = Color(0xFFF0F0E6);



class ChallengeDetailsScreen extends StatefulWidget {
  final String challengeId;

  const ChallengeDetailsScreen({Key? key, required this.challengeId})
      : super(key: key);

  @override
  State<ChallengeDetailsScreen> createState() => _ChallengeDetailsScreenState();
}

class _ChallengeDetailsScreenState extends State<ChallengeDetailsScreen> {
  // Declare a ScrollController for other scrollable widgets if needed.
  final ScrollController _indicatorScrollController = ScrollController();

  @override
  void dispose() {
    _indicatorScrollController.dispose();
    super.dispose();
  }

  // Modified join function that inputs data into the backend.
  Future<void> _joinChallengeModified(String userId) async {
    // Get the challenge document reference
    DocumentSnapshot challengeDoc = await FirebaseFirestore.instance
        .collection('challenges')
        .doc(widget.challengeId)
        .get();
    final String challengeId = challengeDoc.id;
    // Add joined challenge record
    await FirebaseFirestore.instance.collection('joined_challenges').add({
      'user_id': userId,
      'challenge_id': challengeId,
      'joined_at': FieldValue.serverTimestamp(),
    });
    // Increment participants count in the challenge document
    await FirebaseFirestore.instance.collection('challenges').doc(challengeId).update({
      'participants': FieldValue.increment(1),
    });
  }

  // Fetch challenge details from 'challenges'
  Future<Map<String, dynamic>?> fetchChallengeDetails() async {
    try {
      final document = await FirebaseFirestore.instance
          .collection('challenges')
          .doc(widget.challengeId)
          .get();
      if (document.exists) {
        return document.data();
      }
    } catch (e) {
      debugPrint("Error fetching challenge details: $e");
    }
    return null;
  }

  // Fetch participants (user_ids) from 'joined_challenges'
  Future<List<String>> fetchJoinedUsers() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('joined_challenges')
          .where('challenge_id', isEqualTo: widget.challengeId)
          .get();
      return snapshot.docs.map((doc) => doc.get('user_id') as String).toList();
    } catch (e) {
      debugPrint("Error fetching joined users: $e");
      return [];
    }
  }

  // Increment likes for a group
  Future<void> incrementGroupLikes(String groupId) async {
    await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .update({'likes': FieldValue.increment(1)});
  }

  // Check if user has voted for group today
  Future<bool> hasUserVotedForGroupToday(
      String challengeId, String groupId, String userId) async {
    String voteDate = DateFormat("yyyy-MM-dd").format(DateTime.now().toUtc());
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('group_votes')
        .where('challenge_id', isEqualTo: challengeId)
        .where('group_id', isEqualTo: groupId)
        .where('user_id', isEqualTo: userId)
        .where('vote_date', isEqualTo: voteDate)
        .get();
    return querySnapshot.docs.isNotEmpty;
  }

  // Format date "DD MMM YYYY"
  String _formatDate(DateTime dt) {
    final months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    return "${dt.day} ${months[dt.month - 1]} ${dt.year}";
  }

  // Build a pill with an icon and label
  Widget _buildPill({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: vividYellow.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: vividYellow, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: vividYellow,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// Add a vote for the group and increment likes.
Future<void> _addVote(String challengeId, String groupId, String userId) async {
  final voteDate = DateFormat("yyyy-MM-dd").format(DateTime.now().toUtc());
  
  // 1) Increment group likes
  await FirebaseFirestore.instance
      .collection('groups')
      .doc(groupId)
      .update({'likes': FieldValue.increment(1)});

  // 2) Add a new vote doc
  await FirebaseFirestore.instance.collection('group_votes').add({
    'challenge_id': challengeId,
    'group_id': groupId,
    'user_id': userId,
    'voted_at': FieldValue.serverTimestamp(),
    'vote_date': voteDate,
  });
}

/// Remove a user's vote for the group and decrement likes.
Future<void> _removeVote(String challengeId, String groupId, String userId) async {
  final voteDate = DateFormat("yyyy-MM-dd").format(DateTime.now().toUtc());
  
  // 1) Find the existing vote doc
  final querySnapshot = await FirebaseFirestore.instance
      .collection('group_votes')
      .where('challenge_id', isEqualTo: challengeId)
      .where('group_id', isEqualTo: groupId)
      .where('user_id', isEqualTo: userId)
      .where('vote_date', isEqualTo: voteDate)
      .get();

  // 2) Remove that vote doc (user can only have one doc if your logic prevents duplicates)
  for (final doc in querySnapshot.docs) {
    await doc.reference.delete();
  }

  // 3) Decrement group likes
  await FirebaseFirestore.instance
      .collection('groups')
      .doc(groupId)
      .update({'likes': FieldValue.increment(-1)});
}


  // Build a group card for the participants' sharing carousel
Widget _buildGroupCard(DocumentSnapshot groupDoc) {
  final groupData = groupDoc.data() as Map<String, dynamic>;
  final groupName = groupData['groupName'] ?? 'No Group Name';
  final int likes = groupData['likes'] ?? 0;
  final List<dynamic> members = groupData['members'] ?? [];
  final currentUser = FirebaseAuth.instance.currentUser;

  return Container(
    width: 175,
    height: 175, // Ensuring square card
    margin: const EdgeInsets.only(right: 12),
    decoration: BoxDecoration(
      color: offBlack,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Submissions carousel (if any)
          Expanded(
            child: FutureBuilder<QuerySnapshot>(
              future: members.isNotEmpty
                  ? FirebaseFirestore.instance
                      .collection('user_submissions')
                      .where('challengeDocId', isEqualTo: widget.challengeId)
                      .where('status', isEqualTo: 'approved')
                      .where('allowVoting', isEqualTo: true)
                      .where('user_id', whereIn: members)
                      .get()
                  : Future.value(null),
              builder: (context, submissionSnapshot) {
                if (submissionSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!submissionSnapshot.hasData ||
                    submissionSnapshot.data == null ||
                    submissionSnapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No submissions",
                      style: TextStyle(color: lightGray),
                    ),
                  );
                }
                final submissions = submissionSnapshot.data!.docs;
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: submissions.length,
                  itemBuilder: (context, index) {
                    final submissionData =
                        submissions[index].data() as Map<String, dynamic>;
                    final files = submissionData['files'] ?? [];
                    final String imageBase64 = files.isNotEmpty ? files[0] : '';
                    Uint8List? submissionImageBytes;
                    if (imageBase64.isNotEmpty) {
                      try {
                        submissionImageBytes = base64Decode(imageBase64);
                      } catch (e) {
                        debugPrint("Error decoding submission image: $e");
                      }
                    }
                    return Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: 8),
                      child: submissionImageBytes != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                submissionImageBytes,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Icon(
                              Icons.image,
                              color: lightGray,
                              size: 30,
                            ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Group name (shrink if needed)
              Flexible(
                child: Text(
                  groupName,
                  style: const TextStyle(
                    color: lightGray,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                 // overflow: TextOverflow.ellipsis,
                  maxLines: 2,             // allow up to 2 lines
                  overflow: TextOverflow.visible, // or TextOverflow.clip
                  softWrap: true,
                ),
              ),
              const SizedBox(width: 2),
              // Like row: the like icon and the likes count.
              Row(
               mainAxisSize: MainAxisSize.min,
                children: [
                  
                  FutureBuilder<bool>(
                    future: hasUserVotedForGroupToday(
                      widget.challengeId,
                      groupDoc.id,
                      currentUser?.uid ?? '',
                    ),
                    builder: (context, voteSnapshot) {
                      if (voteSnapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: vividYellow,
                          ),
                        );
                      }
                      final alreadyVoted = voteSnapshot.data ?? false;
                      final icon = alreadyVoted ? Icons.favorite : Icons.favorite_border;
                      return IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: Icon(icon, color: const Color(0xffcc6969), size: 20),
                        onPressed: () async {
                          if (currentUser == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("You must be logged in to vote"),
                              ),
                            );
                            return;
                          }
                          try {
                            if (alreadyVoted) {
                              await _removeVote(widget.challengeId, groupDoc.id, currentUser.uid);
                            } else {
                              await _addVote(widget.challengeId, groupDoc.id, currentUser.uid);
                            }
                            setState(() {});
                          } catch (e) {
                            debugPrint("Error toggling vote: $e");
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Error toggling vote: $e")),
                            );
                          }
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 0,
                          minHeight: 0,
                          maxWidth: 30,
                          maxHeight: 30,
                        ),
                      );
                    },
                  ),
                  
                  Text(
                    "$likes",
                  
                    style: const TextStyle(color: lightGray),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
  );
}


  // Horizontal carousel of all approved groups (Participant's Sharing)
  Widget _buildGroupsCarousel() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('groups')
          .where('challengeID', isEqualTo: widget.challengeId)
          .where('status', isEqualTo: 'approved')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 175,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text(
            "No group submissions available",
            style: TextStyle(color: lightGray),
          );
        }
        final groupDocs = snapshot.data!.docs;
        return SizedBox(
          height: 175,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: groupDocs.length,
            itemBuilder: (context, index) {
              return _buildGroupCard(groupDocs[index]);
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkCharcoal,
      appBar: AppBar(
        title: const Text(
          'Challenge Details',
          style: TextStyle(
            color: lightGray,
            fontFamily: "Karla",
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: darkCharcoal,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: lightGray, size: 21),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: fetchChallengeDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.white));
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(
                child: Text("Failed to load challenge details.",
                    style: TextStyle(color: Colors.white)));
          }

          final data = snapshot.data!;
          final title = data['title'] ?? 'No Title';
          final about = data['about'] ?? 'No description.';
          final mode = data['mode'] ?? '';
          final type = data['type'] ?? '';

          // Date logic: format start and end dates
          String startDateFormatted = "";
          String endDateFormatted = "";
          DateTime? startDate;
          DateTime? endDate;
          final startStamp = data['start_date'] as Timestamp?;
          final endStamp = data['end_date'] as Timestamp?;
          if (startStamp != null && endStamp != null) {
            startDate = startStamp.toDate();      
            endDate = endStamp.toDate();    
            startDateFormatted = _formatDate(startStamp.toDate());
            endDateFormatted = _formatDate(endStamp.toDate());
          }

          final now = DateTime.now();
            bool isOngoing = false;
            bool isUpcoming = false;
            bool isPast = false;
            if (startDate != null && endDate != null) {
              isOngoing = now.isAfter(startDate) && now.isBefore(endDate);
              isUpcoming = now.isBefore(startDate);
              isPast = now.isAfter(endDate);
            }

          // Main image + Additional images
          final imageBase64 = data['image'] as String?;
          Uint8List? challengeImageBytes;
          if (imageBase64 != null && imageBase64.isNotEmpty) {
            try {
              challengeImageBytes = base64Decode(imageBase64);
            } catch (_) {}
          }
          final List<dynamic> additionalImages = data['additional_images'] ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // IMAGE LAYOUT
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main image
                    Expanded(
                      flex: 5,
                      child: challengeImageBytes != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                challengeImageBytes,
                                fit: BoxFit.cover,
                                height: 175,
                              ),
                            )
                          : Container(
                              height: 175,
                              decoration: BoxDecoration(
                                color: Colors.black26,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.image,
                                  size: 48,
                                  color: lightGray,
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(width: 16),
                    // Additional Images using SmartStackRotatingImages widget.
                    Expanded(
                      flex: 5,
                      child: additionalImages.isNotEmpty
                          ? SmartStackRotatingImages(
                              additionalImages: additionalImages,
                            )
                          : Container(
                              decoration: BoxDecoration(
                                color: Colors.black26,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Text(
                                  "No additional images",
                                  style: TextStyle(color: lightGray),
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // DATE DISPLAY (Start Date – Divider – End Date)
                (startDateFormatted.isNotEmpty && endDateFormatted.isNotEmpty)
                    ? Row(
                        children: [
                          Text(
                            startDateFormatted,
                            style: TextStyle(
                              color: lightGray.withOpacity(0.7),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              height: 1,
                              color: lightGray.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            endDateFormatted,
                            style: TextStyle(
                              color: lightGray.withOpacity(0.7),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        "Period of Challenge",
                        style: TextStyle(
                          color: lightGray.withOpacity(0.7),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                const SizedBox(height: 8),
                // MAIN TITLE
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: lightGray,
                  ),
                ),
                const SizedBox(height: 12),
                // PILLS (mode + type)
                Row(
                  children: [
                    if (mode.isNotEmpty)
                      _buildPill(icon: Icons.location_on, label: mode),
                    if (type.isNotEmpty)
                      _buildPill(icon: Icons.videogame_asset, label: type),
                  ],
                ),
                const SizedBox(height: 16),
                // ABOUT TEXT
                Text(
                  about,
                  style: TextStyle(
                    color: lightGray.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                // PARTICIPANT'S SHARING (Square cards)
                Text(
                  "Participant's Sharing",
                  style: TextStyle(
                    color: lightGray.withOpacity(0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                _buildGroupsCarousel(),
                const SizedBox(height: 20),
                // JOIN BOX
                FutureBuilder<List<String>>(
                  future: fetchJoinedUsers(),
                  builder: (context, joinedSnapshot) {
                    if (joinedSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final joinedUsers = joinedSnapshot.data ?? [];
                    final joinedCount = joinedUsers.length;
                    final currentUser = FirebaseAuth.instance.currentUser;
                    final hasJoined =
                        currentUser != null && joinedUsers.contains(currentUser.uid);

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                      decoration: BoxDecoration(
                        color: lightGray.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Left: Display the avatars of already joined users.
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Already Joined",
                                style: TextStyle(
                                  color: lightGray.withOpacity(0.8),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  for (int i = 0; i < joinedCount && i < 3; i++)
                                    Container(
                                      margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                                      child: CircleAvatar(
                                        backgroundColor: vividYellow,
                                        radius: 16,
                                        child: Text(
                                          joinedUsers[i].isNotEmpty
                                              ? joinedUsers[i][0].toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                            color: darkCharcoal,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (joinedCount > 3)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 6),
                                      child: CircleAvatar(
                                        backgroundColor: Colors.grey,
                                        radius: 16,
                                        child: Text(
                                          '+${joinedCount - 3}',
                                          style: const TextStyle(
                                            color: darkCharcoal,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          // Right: The Join button.
                           ElevatedButton(
                              onPressed: (hasJoined || currentUser == null || isUpcoming || isPast)
                                  ? null
                                  : () async {
                                      try {
                                        await _joinChallengeModified(currentUser.uid);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => GroupSelectionScreen(
                                              challengeID: widget.challengeId,
                                            ),
                                          ),
                                        );
                                        setState(() {});
                                      } catch (e) {
                                        debugPrint("Error joining challenge: $e");
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text("Error joining challenge: $e")),
                                        );
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: (hasJoined || isUpcoming || isPast || currentUser == null)
                                    ? vividYellow.withOpacity(0.2)
                                    : vividYellow,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 14,
                                ),
                              ),
                              child: Builder(
                                builder: (context) {
                                  if (hasJoined) {
                                    return Text(
                                      "Joined",
                                      style: TextStyle(
                                        color: lightGray,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    );
                                  } else if (isUpcoming && startDate != null) {
                                    final daysUntil = (startDate.difference(now).inHours / 24).ceil();
                                    return Text(
                                      "Opens in $daysUntil day${daysUntil == 1 ? '' : 's'}",
                                      style: TextStyle(
                                        color: lightGray,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    );
                                  } else if (isPast) {
                                    return Text(
                                      "Challenge Over",
                                      style: TextStyle(
                                        color: lightGray,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    );
                                  } else {
                                    return Text(
                                      "Join",
                                      style: TextStyle(
                                        color: darkCharcoal,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    );
                                  }
                                },
                              ),
                           ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// SmartStackRotatingImages widget: Changes between images with a fade effect,
// showing only one image at a time. A horizontal row of line indicators is 
// displayed below the image (outside the image container), so that it remains fixed.
// -----------------------------------------------------------------------------
class SmartStackRotatingImages extends StatefulWidget {
  final List<dynamic> additionalImages;
  final double imageHeight;

  const SmartStackRotatingImages({
    Key? key,
    required this.additionalImages,
    this.imageHeight = 160, // fixed image height
  }) : super(key: key);

  @override
  _SmartStackRotatingImagesState createState() =>
      _SmartStackRotatingImagesState();
}

class _SmartStackRotatingImagesState extends State<SmartStackRotatingImages> {
  int _currentIndex = 0;
  double _dragOffset = 0.0;
  final double dragThreshold = 50.0;

  // Helper to build an image widget from a base64 string.
  Widget _buildImage(String base64Str) {
    Uint8List? imgBytes;
    try {
      imgBytes = base64Decode(base64Str);
    } catch (e) {
      debugPrint("Error decoding image: $e");
    }
    return imgBytes != null
        ? ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              imgBytes,
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          )
        : const Icon(
            Icons.image,
            color: lightGray,
            size: 50,
          );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Image container with swipe gesture.
        GestureDetector(
          onHorizontalDragUpdate: (details) {
            setState(() {
              _dragOffset += details.delta.dx;
            });
          },
          onHorizontalDragEnd: (details) {
            if (_dragOffset.abs() > dragThreshold) {
              if (_dragOffset < 0 &&
                  _currentIndex < widget.additionalImages.length - 1) {
                _currentIndex++;
              } else if (_dragOffset > 0 && _currentIndex > 0) {
                _currentIndex--;
              }
            }
            _dragOffset = 0.0;
            setState(() {});
          },
          child: Container(
            height: widget.imageHeight,
            width: double.infinity,
            // AnimatedSwitcher to fade between images.
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              key: ValueKey<int>(_currentIndex),
              child: _buildImage(widget.additionalImages[_currentIndex]),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Horizontal line indicators below the image.
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.additionalImages.length, (index) {
            // Adjust line width based on the total count.
            double lineWidth = widget.additionalImages.length <= 5
                ? 20.0
                : widget.additionalImages.length <= 10
                    ? 15.0
                    : 10.0;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _currentIndex = index;
                });
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: lineWidth,
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: _currentIndex == index ? vividYellow : Colors.white54,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

