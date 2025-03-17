import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'groupchat_screen.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:image/image.dart' as img;
import 'package:geolocator/geolocator.dart';

// Your color scheme
const Color darkCharcoal = Color(0xFF29292B);
const Color offBlack = Color(0xFF343436);
const Color vividYellow = Color(0xFFd7ed73);
const Color lightGray = Color(0xFFF0F0E6);

enum ChallengeFilter { all, in_progress, completed }

class JoinedChallengesScreen extends StatefulWidget {
  const JoinedChallengesScreen({Key? key}) : super(key: key);

  @override
  _JoinedChallengesScreenState createState() => _JoinedChallengesScreenState();
}

class _JoinedChallengesScreenState extends State<JoinedChallengesScreen> {
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
  ChallengeFilter _selectedFilter = ChallengeFilter.all;

  String _formatPeriod(DateTime start, DateTime end) {
    return '${DateFormat('d MMM').format(start)} - ${DateFormat('d MMM').format(end)}';
  }

  // Build filter chips.
  Widget _buildFilterChips() {
    return Container(
      color: darkCharcoal,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildSingleFilterChip(ChallengeFilter.all, 'All', Icons.all_inclusive, vividYellow),
          const SizedBox(width: 6),
          _buildSingleFilterChip(ChallengeFilter.in_progress, 'In Progress', Icons.hourglass_top, vividYellow),
          const SizedBox(width: 6),
          _buildSingleFilterChip(ChallengeFilter.completed, 'Completed', Icons.history, const Color(0xffcc6969)),
        ],
      ),
    );
  }

  Widget _buildSingleFilterChip(
      ChallengeFilter filter, String label, IconData icon, Color chipColor) {
    final bool isSelected = (_selectedFilter == filter);
    return ChoiceChip(
      showCheckmark: false,
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedFilter = filter),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? offBlack : chipColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? offBlack : lightGray,
              fontFamily: 'Karla',
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      backgroundColor: offBlack,
      selectedColor: chipColor.withOpacity(0.8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  // Returns true if the challenge matches the selected filter.
  bool _filterChallenge(Map<String, dynamic> groupData, challengeData) {
  final String status = groupData['status'] ?? 'pending';
  final Timestamp? endStamp = challengeData['end_date'] as Timestamp?;
  final DateTime now = DateTime.now().toUtc();
  final bool challengeOver = endStamp != null && endStamp.toDate().toUtc().isBefore(now);
  print("endStamp: ${endStamp?.toDate().toUtc()}, now: $now, challengeOver: $challengeOver, status: $status");

  
  switch (_selectedFilter) {
    case ChallengeFilter.in_progress:
      // In progress only if not over and status is pending or rejected.
      return !challengeOver && (status == 'pending' || status == 'rejected');
    case ChallengeFilter.completed:
      // Completed if status is approved or challenge is over.
      return status == 'approved' || challengeOver;
    case ChallengeFilter.all:
    default:
      return true;
  }
}



  // Build a joined challenge card with updated design.
  Widget _buildJoinedChallengeCard(
      BuildContext context, String challengeId, Map<String, dynamic> data) {
    final String title = data['title'] ?? 'Unknown Challenge';
    final String mode = data['mode'] ?? 'TBD';
    final String type = data['type'] ?? 'TBD';
    final DateTime startDate = (data['start_date'] as Timestamp?)?.toDate() ?? DateTime.now();
    final DateTime endDate = (data['end_date'] as Timestamp?)?.toDate() ?? DateTime.now();
    final String period = _formatPeriod(startDate, endDate);
    // Challenge picture (assumed to be a base64 string)
    final String imageCode = data['image'] ?? '';

    // Fetch group document for this challenge where the current user is a member.
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('groups')
          .where('challengeID', isEqualTo: challengeId)
          .where('members', arrayContains: currentUserId)
          .get(),
      builder: (context, groupSnapshot) {
        String groupName = 'No Group';
        if (groupSnapshot.hasData && groupSnapshot.data!.docs.isNotEmpty) {
          final groupDoc = groupSnapshot.data!.docs.first;
          final groupData = groupDoc.data() as Map<String, dynamic>;
          groupName = groupData['groupName'] ?? 'Group';
        }
        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => JoinedChallengeDetailScreen(
                  challengeId: challengeId,
                  data: data,
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            
            decoration: BoxDecoration(
              color: offBlack,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              spreadRadius: 0,
              blurRadius: 10,
              offset: Offset(0, 5), // Changes position of shadow
            ),
          ],
              
            ),
            padding: const EdgeInsets.all(16.0),
            child: Stack(
              children: [
                // Main row: Challenge picture and details.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Challenge picture.
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: imageCode.isNotEmpty
                          ? Image.memory(
                              base64Decode(imageCode),
                              width: 80,
                              height: 95,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 80,
                              height: 95,
                              color: Colors.grey[800],
                              child: const Icon(Icons.image, color: lightGray),
                            ),
                    ),
                    const SizedBox(width: 10),
                    // Details: Title, period (calendar icon), group (group icon), and pills.
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title.
                          Text(
                            title,
                            style: const TextStyle(
                              fontFamily: 'Karla',
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: lightGray,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          // Period row with calendar icon.
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, color: vividYellow, size: 15),
                              const SizedBox(width: 4),
                              Text(
                                period,
                                style: const TextStyle(
                                  fontFamily: 'Karla',
                                  fontSize: 12,
                                  color: lightGray,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Group row with group icon and group name.
                          Row(
                            children: [
                              const Icon(Icons.group, color: vividYellow, size: 15),
                              const SizedBox(width: 4),
                              Text(
                                groupName,
                                style: const TextStyle(
                                  fontFamily: 'Karla',
                                  fontSize: 12,
                                  color: lightGray,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Pills for Mode and Type.
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: vividYellow.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.location_on, color: vividYellow, size: 15),
                                    const SizedBox(width: 4),
                                    Text(
                                      mode,
                                      style: const TextStyle(
                                        fontFamily: 'Karla',
                                        fontSize: 10,
                                        color: vividYellow,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: vividYellow.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.videogame_asset, color: vividYellow, size: 15),
                                    const SizedBox(width: 4),
                                    Text(
                                      type,
                                      style: const TextStyle(
                                        fontFamily: 'Karla',
                                        fontSize: 10,
                                        color: vividYellow,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Chat button remains unchanged.
                Positioned(
                  bottom: 25,
                  right: 0,
                  child: FutureBuilder<QuerySnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('groups')
                        .where('challengeID', isEqualTo: challengeId)
                        .where('members', arrayContains: FirebaseAuth.instance.currentUser!.uid)
                        .get(),
                    builder: (context, groupSnapshot) {
                      if (groupSnapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator(color: lightGray);
                      }
                      if (groupSnapshot.hasError || groupSnapshot.data!.docs.isEmpty) {
                        return ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("You're not in a group for this challenge!")),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text("Chat"),
                        );
                      }
                      final group = groupSnapshot.data!.docs.first;
                      return ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GroupChatScreen(
                                groupID: group.id,
                                groupName: group['groupName'] ?? 'Group Chat',
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: vividYellow,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text("Chat",
                            style: TextStyle(
                              fontFamily: 'Karla',
                              color: darkCharcoal,
                              fontSize: 12
                              
                            )),
                      );
                    },
                  ),
                ),
              ],
            ),
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
        backgroundColor: darkCharcoal,
        elevation: 0,
        iconTheme: const IconThemeData(color: lightGray),
        title: const Text(
          'Joined Challenges',
          style: TextStyle(
            fontFamily: 'Karla',
            color: lightGray,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: lightGray, size: 21),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('joined_challenges')
                  .where('user_id', isEqualTo: currentUserId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: lightGray));
                }
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Error loading joined challenges.',
                      style: TextStyle(color: lightGray, fontFamily: 'Karla'),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No challenges joined yet.',
                      style: TextStyle(color: lightGray, fontFamily: 'Karla'),
                    ),
                  );
                }
                final joinedChallenges = snapshot.data!.docs;
                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: joinedChallenges.length,
                  itemBuilder: (context, index) {
                    final joinedDoc = joinedChallenges[index];
                    final joinedData = joinedDoc.data() as Map<String, dynamic>;
                    final String challengeId = joinedData['challenge_id'] ?? '';
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('challenges')
                          .doc(challengeId)
                          .get(),
                      builder: (context, challengeSnapshot) {
                        if (challengeSnapshot.connectionState == ConnectionState.waiting) {
                          return Container(
                            height: 100,
                            alignment: Alignment.center,
                            child: CircularProgressIndicator(color: lightGray),
                          );
                        }
                        if (challengeSnapshot.hasError ||
                            !challengeSnapshot.hasData ||
                            !challengeSnapshot.data!.exists) {
                          return Container(
                            height: 100,
                            alignment: Alignment.center,
                            child: const Text(
                              'Unknown Challenge',
                              style: TextStyle(color: lightGray, fontFamily: 'Karla'),
                            ),
                          );
                        }
                        final challengeData = challengeSnapshot.data!.data() as Map<String, dynamic>;
                        return FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection('groups')
              .where('challengeID', isEqualTo: challengeId)
              .where('members', arrayContains: currentUserId)
              .get(),
          builder: (context, groupSnapshot) {
            if (groupSnapshot.connectionState == ConnectionState.waiting) {
              return Container(
                height: 100,
                alignment: Alignment.center,
                child: CircularProgressIndicator(color: lightGray),
              );
            }
            if (groupSnapshot.hasError || groupSnapshot.data!.docs.isEmpty) {
              return Container(
                height: 100,
                alignment: Alignment.center,
                child: const Text(
                  'No group found',
                  style: TextStyle(color: lightGray, fontFamily: 'Karla'),
                ),
              );
            }
            final groupData = groupSnapshot.data!.docs.first.data() as Map<String, dynamic>;
            

                        if (!_filterChallenge(groupData, challengeData)) return const SizedBox();
                        return _buildJoinedChallengeCard(context, challengeId, challengeData);
                      },
                    );
                  },
                );
              },
            );
              }
          ),
          )
        ],
      ),
    );
  }
}

// Detail screen with submission and chat functionality (design updated, logic unchanged).
class JoinedChallengeDetailScreen extends StatefulWidget {
  final String challengeId;
  final Map<String, dynamic> data;

  const JoinedChallengeDetailScreen({
    Key? key,
    required this.challengeId,
    required this.data,
  }) : super(key: key);

  @override
  _JoinedChallengeDetailScreenState createState() =>
      _JoinedChallengeDetailScreenState();
}

class _JoinedChallengeDetailScreenState
    extends State<JoinedChallengeDetailScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<String> compressAndConvertToBase64(File file) async {
    try {
      final originalBytes = await file.readAsBytes();
      final originalImage = img.decodeImage(originalBytes);
      if (originalImage == null) throw Exception("Failed to decode the image.");
      final resizedImage = img.copyResize(originalImage, width: 300);
      final compressedBytes = img.encodeJpg(resizedImage, quality: 70);
      return base64Encode(compressedBytes);
    } catch (e) {
      print("Error compressing and encoding image: $e");
      rethrow;
    }
  }

 Future<void> _showSubmissionPreview(BuildContext context) async {
  // Show a dialog to let user choose between camera and gallery.
  final ImageSource? source = await showDialog<ImageSource>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: offBlack,
        title: const Text(
          "Select Image Source",
          style: TextStyle(color: lightGray, fontFamily: 'Karla'),
        ),
        content: const Text(
          "Choose whether to take a new photo or select one from your gallery.",
          style: TextStyle(color: lightGray, fontFamily: 'Karla'),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            child: const Text("Camera", style: TextStyle(color: vividYellow)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            child: const Text("Gallery", style: TextStyle(color: vividYellow)),
          ),
        ],
      );
    },
  );

  // If the user cancels, source will be null.
  if (source == null) return;

  // Pick image from the selected source.
  final XFile? pickedFile = await _picker.pickImage(source: source);
  if (pickedFile == null) return;

  final File file = File(pickedFile.path);
  final int fileSize = await file.length();
  const int maxFileSize = 500 * 1024;
  String base64Image;
  if (fileSize > maxFileSize) {
    base64Image = await compressAndConvertToBase64(file);
  } else {
    final bytes = await file.readAsBytes();
    base64Image = base64Encode(bytes);
  }

  // Local variable to hold the checkbox state.
  bool allowVoting = false;

  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: offBlack,
        title: const Text(
          "Preview Submission",
          style: TextStyle(color: lightGray, fontFamily: 'Karla'),
        ),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (base64Image.isNotEmpty)
                  Image.memory(
                    base64Decode(base64Image),
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                  )
                else
                  const SizedBox(),
                const SizedBox(height: 10),
                const Text(
                  "Do you want to submit this file?",
                  style: TextStyle(color: lightGray, fontFamily: 'Karla'),
                ),
                Row(
                  children: [
                    Checkbox(
                      value: allowVoting,
                      onChanged: (value) {
                        setState(() {
                          allowVoting = value ?? false;
                        });
                      },
                    ),
                    const Expanded(
                      child: Text(
                        "Allow this submission to be used for memory gallery & voting",
                        style: TextStyle(
                          color: lightGray,
                          fontFamily: 'Karla',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancel",
              style: TextStyle(color: vividYellow, fontFamily: 'Karla'),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _finalizeSubmission(context, base64Image, allowVoting);
            },
            style: ElevatedButton.styleFrom(backgroundColor: vividYellow),
            child: const Text(
              "Submit",
              style: TextStyle(
                  color: darkCharcoal,
                  fontFamily: 'Karla',
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      );
    },
  );
}


Future<void> _finalizeSubmission(
    BuildContext context, String base64Image, bool allowVoting) async {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) return;

  // (Location retrieval code remains unchanged)
  Position position;
  try {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location services are disabled.")),
      );
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location permissions are denied.")),
        );
        return;
      }
    }
    position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  } catch (e) {
    print("Error getting current location: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error getting location: $e")),
    );
    return;
  }

  final GeoPoint geoPoint = GeoPoint(position.latitude, position.longitude);
  final String submissionDocId =
      "${widget.challengeId.trim()}_${currentUser.uid.trim()}";
  final submissionRef = FirebaseFirestore.instance
      .collection('user_submissions')
      .doc(submissionDocId);
  final docSnapshot = await submissionRef.get();

  if (docSnapshot.exists) {
    await submissionRef.update({
      'files': [base64Image],
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'pending',
      'location': geoPoint,
      'allowVoting': allowVoting, // New field for permission
    });
  } else {
    await submissionRef.set({
      'challengeDocId': widget.challengeId,
      'user_id': currentUser.uid,
      'files': [base64Image],
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
      'location': geoPoint,
      'allowVoting': allowVoting, // New field for permission
    });
  }

  // (Group update code remains unchanged)
  final groupQuerySnapshot = await FirebaseFirestore.instance
      .collection('groups')
      .where('challengeID', isEqualTo: widget.challengeId)
      .where('members', arrayContains: currentUser.uid)
      .get();
  if (groupQuerySnapshot.docs.isNotEmpty) {
    final groupDoc = groupQuerySnapshot.docs.first;
    await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupDoc.id)
        .update({'status': 'pending'});
  }

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
        content: Text("Submission uploaded and is now pending approval!")),
  );
  setState(() {});
}

  @override
  Widget build(BuildContext context) {
    final String title = widget.data['title'] ?? 'Unknown Challenge';
    final String challenge = widget.data['prompt'] ?? 'No description yet.';
    final String submission_options = widget.data['submission_options'] ?? 'No description yet.';
    final String online_submission_notice = widget.data['online_submission_notice'] ?? 'No description yet.';
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return Container();

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('groups')
          .where('challengeID', isEqualTo: widget.challengeId)
          .where('members', arrayContains: currentUser.uid)
          .get(),
      builder: (context, groupSnapshot) {
        if (groupSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: darkCharcoal,
            body: Center(child: CircularProgressIndicator(color: lightGray)),
          );
        }
        if (!groupSnapshot.hasData || groupSnapshot.data!.docs.isEmpty) {
          return Scaffold(
            backgroundColor: darkCharcoal,
            appBar: AppBar(
              backgroundColor: darkCharcoal,
              elevation: 0,
              iconTheme: const IconThemeData(color: lightGray),
              title: Text(title,  style: TextStyle(
            fontFamily: 'Karla',
            color: lightGray,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),),
          leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: lightGray, size: 21),
          onPressed: () => Navigator.pop(context),
        ),
              centerTitle: true,
            ),
            body: Center(
              child: Text(
                "You are not in a group for this challenge. Please join a group first.",
                style: const TextStyle(color: lightGray, fontFamily: 'Karla'),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        final groupDoc = groupSnapshot.data!.docs.first;
        final List<dynamic> membersDynamic = groupDoc['members'] ?? [];
        final List<String> groupMembers = membersDynamic.map((e) => e.toString()).toList();
        final int currentPax = groupDoc['current_pax'] as int;
        final int minPax = groupDoc['min_pax'] as int;
      
          // Get challenge dates from the data.
          final Timestamp? startStamp = widget.data['start_date'] as Timestamp?;
          final Timestamp? endStamp = widget.data['end_date'] as Timestamp?;
          DateTime? startDate;
          DateTime? endDate;
          String startDateFormatted = "";
          String endDateFormatted = "";
          String period = "";
          if (startStamp != null && endStamp != null) {
            startDate = startStamp.toDate();
            endDate = endStamp.toDate();
            final formatter = DateFormat('d MMM yyyy');
            startDateFormatted = formatter.format(startDate);
            endDateFormatted = formatter.format(endDate);
            period = "$startDateFormatted - $endDateFormatted";
          }
          
          // Determine if the challenge is over.
          final now = DateTime.now();   
       
          final bool challengeOver = endDate != null && endDate.isBefore(now) && !(groupDoc['status'] == 'approved');
          final bool challengeCompleted = groupDoc['status'] == 'approved';
          final bool groupReady = currentPax >= minPax;
          final bool allowSubmission = groupReady && !challengeOver && !challengeCompleted;



        return Scaffold(
          backgroundColor: darkCharcoal,
          appBar: AppBar(
            backgroundColor: darkCharcoal,
            elevation: 0,
            iconTheme: const IconThemeData(color: lightGray),
            title: Text('Submission',  style: TextStyle(
            fontFamily: 'Karla',
            color: lightGray,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),),
          leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: lightGray, size: 21),
          onPressed: () => Navigator.pop(context),
        ), 
        centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: offBlack,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Challenge Title & Description
                  Text(
                    "Challenge Details of $title",
                    style: const TextStyle(
                      fontFamily: 'Karla',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: lightGray,
                    ),
                  ),
                    const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration( 
                      color: darkCharcoal,
                    borderRadius: BorderRadius.circular(16), 
                    ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                    'Prompt'.toUpperCase(),
                    style: const TextStyle(
                      fontFamily: 'Karla',
                      fontSize: 14,
                      color: lightGray,
                      fontWeight: FontWeight.bold,

                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    challenge,
                    style: const TextStyle(
                      fontFamily: 'Karla',
                      fontSize: 14,
                      color: lightGray,
                    ),
                  ),
                    ]
                )
                  ),
                  const SizedBox(height: 12),
                   Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration( 
                      color: darkCharcoal,
                    borderRadius: BorderRadius.circular(16), 
                    ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                    'Submission Requirements'.toUpperCase(),
                    style: const TextStyle(
                      fontFamily: 'Karla',
                      fontSize: 14,
                      color: lightGray,
                      fontWeight: FontWeight.bold,

                    ),
                  ),
                  const SizedBox(height: 5),
                      Text(
                    "Ideas for Submission:",
                    style: const TextStyle(
                      fontFamily: 'Karla',
                      fontSize: 12,
                      color: Color.fromARGB(223, 240, 240, 230),
                      fontWeight: FontWeight.bold
                    
                    ),
                  ),
                  Text(
                    submission_options,
                    style: const TextStyle(
                      fontFamily: 'Karla',
                      fontSize: 12,
                      color: Color.fromARGB(223, 240, 240, 230),
                    
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Alternative Ideas for Online Submission:",
                    style: const TextStyle(
                      fontFamily: 'Karla',
                      fontSize: 12,
                      color: Color.fromARGB(223, 240, 240, 230),
                      fontWeight: FontWeight.bold
                    
                    ),
                  ),
                  Text(
                    online_submission_notice,
                    style: const TextStyle(
                      fontFamily: 'Karla',
                      fontSize: 12,
                      color: Color.fromARGB(223, 240, 240, 230),
                    ),
                  ),
                    ]
                  ),
                   ),
                  const SizedBox(height: 20),
                  if (challengeCompleted)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Color(0xff2B6A06),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            "You have already completed the challenge",
                            style: TextStyle(
                              color: lightGray,
                              fontFamily: 'Karla',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    )
                else if (challengeOver)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      "Challenge Over: You didn't complete the challenge in time.",
                      style: const TextStyle(
                        fontFamily: 'Karla',
                        color: Colors.redAccent,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                  else if (!allowSubmission)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        "Submissions are locked until the group reaches the minimum required participants ($minPax).",
                        style: const TextStyle(
                          fontFamily: 'Karla',
                          color: Colors.redAccent,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ElevatedButton(
                    onPressed: allowSubmission ? () => _showSubmissionPreview(context) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: allowSubmission ? vividYellow : offBlack,
                    ),
                    child: Text(
                      "Submit Your File",
                      style: TextStyle(fontFamily: 'Karla', color: allowSubmission? darkCharcoal: offBlack,),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Display group submissions.
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('user_submissions')
                        .where('challengeDocId', isEqualTo: widget.challengeId)
                        .where('user_id', whereIn: groupMembers)
                        .snapshots(),
                    builder: (context, submissionSnapshot) {
                      if (submissionSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!submissionSnapshot.hasData || submissionSnapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text(
                            'No submissions yet.',
                            style: TextStyle(color: lightGray, fontFamily: 'Karla'),
                          ),
                        );
                      }
                      final submissions = submissionSnapshot.data!.docs;
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: submissions.length,
                        itemBuilder: (context, index) {
                          final submission = submissions[index];
                          final submissionData = submission.data() as Map<String, dynamic>;
                          final String userId = submissionData['user_id'] ?? 'Unknown';
                          final String status = submissionData['status'] ?? 'pending';
                          Color statusColor;
                          if (status == 'approved') {
                            statusColor = vividYellow;
                          } else if (status == 'rejected') {
                            statusColor = Colors.redAccent;
                          } else {
                            statusColor = Color(0xffffde5a);
                          }

                          return FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
                          builder: (context, userSnapshot) {
                            String userName = 'Unknown User';
                            if (userSnapshot.hasData && userSnapshot.data!.exists) {
                              final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                              userName = userData['name'] ?? 'Unknown User';
                            }

                          final List<dynamic> files = submissionData['files'] ?? [];
                          String previewBase64 = files.isNotEmpty ? files[0] : "";
                          return Card(
                            color: darkCharcoal,
                            child: ListTile(
                              leading: previewBase64.isNotEmpty
                                  ? Image.memory(
                                      base64Decode(previewBase64),
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                    )
                                  : const Icon(Icons.image, color: lightGray),
                              title: Text(
                                userName,
                                style: const TextStyle(fontFamily: 'Karla', color: lightGray),
                              ),
                              subtitle: Text(
                                "Status: $status",
                                style: TextStyle(fontFamily: 'Karla', color: statusColor),
                              ),
                              trailing: submissionData['user_id'] == currentUser.uid && status == 'rejected'
                                  ? ElevatedButton(
                                      onPressed: () => _showSubmissionPreview(context),
                                       style: ElevatedButton.styleFrom(
                              backgroundColor: vividYellow,
                            ),
                                      child: const Text("Resubmit" , style: TextStyle(color: darkCharcoal, fontFamily: 'Karla'),),
                                    )
                                  : null,
                            ),
                          );
                        },
                      );
                    },
                      );
                    }
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
