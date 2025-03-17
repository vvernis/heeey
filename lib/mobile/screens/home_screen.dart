import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notifications_screen.dart';
import 'chats_screen.dart';
import 'profile_screen.dart';
import 'challenges/challenge_details_screen.dart';
import 'dart:convert';
import 'dart:ui';
import 'dart:io';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:typed_data';
import '../../../shared/memory_gallery_map.dart';
import '../screens/memory gallery/location_photo_list_page.dart';



const Color darkCharcoal = Color(0xFF29292B);
const Color offBlack = Color(0xFF343436);
const Color vividYellow = Color(0xFFd7ed73);
const Color lightGray = Color(0xFFF0F0E6);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = "Loading..."; // Default placeholder for the user's name
  String profilePic = "Loading..."; // Default placeholder for the user's name
  bool isLoading = true; // Track loading state
  int _currentIndex = 0;

  List<Widget> _pages = [];


  @override
  void initState() {
    super.initState();
     isLoading = true;
    _initializeHomeScreen(); // Combine initialization steps
    
  }

  Future<void> _initializeHomeScreen() async {
    await fetchUserName(); // Ensure userName is fetched first
    await fetchProfilePic();
    await initializePages(); // Then initialize navigation pages
  }

  Future<void> initializePages() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      setState(() {
        _pages = [
          _buildMainContent(),
          const NotificationsScreen(),
          const ChatsScreen(),
          ProfileWidget(uid: uid),
        ];
        isLoading = false; // Stop loading spinner when pages are ready
      });
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<void> fetchUserName() async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;

      if (currentUserId != null) {
        // Fetch user document
        final userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .get();

        if (userSnapshot.exists) {
          final fetchedUserName = userSnapshot.data()?['name'] ?? 'User';
          setState(() {
            userName = fetchedUserName; // Update userName
            isLoading = false; // Set loading to false
          });
        } else {
          // If user document doesn't exist
          setState(() {
            userName = 'No user found';
            isLoading = false;
          });
        }
      } else {
        // If currentUserId is null
        setState(() {
          userName = 'Not logged in';
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching user name: $e');
      setState(() {
        userName = 'Error fetching name';
        isLoading = false;
      });
    }
  }

    Future<void> fetchProfilePic() async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;

      if (currentUserId != null) {
        // Fetch user document
        final userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .get();

        if (userSnapshot.exists) {
          final fetchedProfilePic = userSnapshot.data()?['profilePic'] ?? 'profilePic';
          setState(() {
            profilePic = fetchedProfilePic; // Update userName
            isLoading = false; // Set loading to false
          });
        } else {
          // If user document doesn't exist
          setState(() {
            profilePic = 'No profile picture found';
            isLoading = false;
          });
        }
      } else {
        // If currentUserId is null
        setState(() {
          profilePic = 'Not logged in';
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching profile picture: $e');
      setState(() {
        profilePic = 'Error fetching profile picture';
        isLoading = false;
      });
    }
  }

  void _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show a loading spinner if still initializing
  if (isLoading) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: IndexedStack(
              index: _currentIndex,
              children: _pages,
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
              child: _customNavBar()
            ),
        ],
      ),
    ); 
  }

  Stream<int> getNotificationCount(String userId) {
  return FirebaseFirestore.instance
      .collection('notifications')
      .where('receiverId', isEqualTo: userId)
      .where('isRead', isEqualTo: false)
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
      
}

  Widget _customNavBar() {
    final user = FirebaseAuth.instance.currentUser;
  final userId = user?.uid;

  // If userId is null, we return a Stream that always emits 0,
  // so we don't crash or have to create a separate widget.
  return StreamBuilder<int>(
    stream: userId == null
      ? Stream.value(0) // fallback: always 0 notifications
      : getNotificationCount(userId), // your actual function
    builder: (context, snapshot) {
      // If the stream hasn’t emitted yet, default to 0
      final notificationCount = snapshot.data ?? 0;

  return Container(
    padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom, left: 30, right: 30),
    decoration: BoxDecoration(
      color: Colors.transparent, // Use transparent background
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          spreadRadius: 0,
          blurRadius: 10,
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.all(Radius.circular(30)), // Rounded corners
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          color: Colors.black.withOpacity(0.6), // Semi-transparent black background
          padding: EdgeInsets.symmetric(vertical: 15, horizontal: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              _navBarItem(icon: Icons.home, label: 'Home', index: 0),
              _navBarItem(
                    icon: Icons.notifications,
                    label: 'Notification',
                    index: 1,
                    badgeCount: notificationCount,
                  ),
              _navBarItem(icon: Icons.chat, label: 'Chats', index: 2),
              _navBarItem(icon: Icons.person, label: 'Profile', index: 3),
            ],
          ),
        ),
      ),
    ),
  );
    }
    );
}



Widget _navBarItem({
  required IconData icon,
  required String label,
  required int index,
  int badgeCount = 0, // default to 0
}) {
  bool isSelected = _currentIndex == index;
  return GestureDetector(
    onTap: () => setState(() {
      _currentIndex = index;
    }),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          // Wrap the icon in a stack to show a badge
          Stack(
            clipBehavior: Clip.none, // so badge can overflow outside the icon
            children: [
              Icon(
                icon,
                color: isSelected ? offBlack : Colors.white,
              ),
              if (badgeCount > 0) // only show badge if there's something to show
                Positioned(
                  // position the badge in the top-right corner of the icon
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$badgeCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          if (isSelected)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(label, style: TextStyle(color: offBlack)),
            )
        ],
      ),
    ),
  );
}


  Widget _buildMainContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween, 
              children: [
              Row( 
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: MemoryImage(base64Decode(profilePic)),
                  ),
                  SizedBox(width: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, ',
                        style: TextStyle(fontSize: 16, color: Color(0xFFF0F0E6), fontFamily: 'Karla', fontWeight: FontWeight.bold),
                      ),
                      Text(
                        userName, 
                        style: TextStyle(
                          fontFamily: 'Karla',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF0F0E6),
                        ),
                      ),
                    ]
                  ),
                ],
              ),
              IconButton(
                icon: Icon(Icons.logout, color: Color(0xFFF0F0E6)),
                onPressed: () => _logout(context), // Assuming _logout is defined
              ),
            ],
            ),
            const SizedBox(height: 16),
            _buildLatestChallenge(),
            const SizedBox(height: 16),

           Padding(
              padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3, // Three items per row
                crossAxisSpacing: 8, // Space between items
                mainAxisSpacing: 8, // Space between rows
                childAspectRatio: 3 / 2.5, // Adjusted aspect ratio for better fit
                children: [
                  _buildFeatureButton(context, 'Find Challenges', Icons.emoji_events, '/challenges', Color(0xD9cbf4e9), darkCharcoal),
                  _buildFeatureButton(context, 'Find Matches', Icons.person_add, '/match-home', Color(0xD9f5f9d1), darkCharcoal),
                  _buildFeatureButton(context, 'Memory Gallery', Icons.photo_library, '/memory_gallery', Color(0xD9f5e8ff), darkCharcoal),
                ],
              ),
            ),
            const SizedBox(height: 4),
              // Insert the rotating announcement card here:
             const SmartStackRotatingAnnouncements(),
            const SizedBox(height: 4),
            // Highlights Section
            const Text(
              'Highlights',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFF0F0E6), fontFamily: 'Karla'),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/memory_gallery');
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16), // Rounded corners
                child: Container(
                  height: 200,
                  // Remove the borderRadius from the decoration as ClipRRect handles it
                  child: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance.collection('user_submissions').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final submissionDocs = snapshot.data!.docs;
          // Filter submissions with a location.
          final submissionsWithLocation = submissionDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['location'] != null;
          }).toList();
          
          // Add these lines to compute participant counts by location:
          final Map<String, Set<String>> locationToUserIds = {};
          for (var doc in submissionsWithLocation) {
            final data = doc.data() as Map<String, dynamic>;
            final location = data['location']; // assumed to be a GeoPoint
            if (location != null) {
              // Use a key based on latitude and longitude
              final key = '${(location as dynamic).latitude.toDouble()},${(location as dynamic).longitude.toDouble()}';
              final userId = data['user_id'] as String? ?? '';
              if (userId.isNotEmpty) {
                locationToUserIds.putIfAbsent(key, () => <String>{}).add(userId);
              }
            }
          }

          // Create a mapping from location key to participant count
          final Map<String, int> locationToParticipantCount = {};
          locationToUserIds.forEach((key, userIds) {
            locationToParticipantCount[key] = userIds.length;
          });

        final List<GalleryItem> mapItems = submissionsWithLocation.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final location = data['location']; // assumed to be a GeoPoint
        final key = '${(location as dynamic).latitude.toDouble()},${(location as dynamic).longitude.toDouble()}';
        final participantCount = locationToParticipantCount[key] ?? 0;
            
              
            return GalleryItem(
              lat: (location as dynamic).latitude.toDouble(),
              lng: (location as dynamic).longitude.toDouble(),
              image: data['files'] is List &&
                      (data['files'] as List).isNotEmpty
                  ? (data['files'] as List).first as String
                  : '',
               participantCount: participantCount,
            );
          }).toList();
                      return MemoryGalleryMap(
                        items: mapItems,
                      onMarkerTap: (GalleryItem item) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                LocationPhotoListPage(location: item),
                          ),
                        );
                      },);
                    },
                  ),
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
  

  Widget _buildFeatureButton(BuildContext context, String label, IconData icon, String route, Color iconbgColor, Color iconColor) {
    List<String> words = label.split(' '); // Split the label into words
// Convert each word into a Text widget and collect into a list
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, route);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: offBlack,
            boxShadow: [
             BoxShadow(
              color: Colors.black.withOpacity(0.5),
              spreadRadius: 0,
              blurRadius: 10,
              offset: Offset(0, 5), // Changes position of shadow
            ),
            ],
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 10, top: 3), 
          child: Stack(
            children: [
              Positioned(
                top: 10, // Adjust top padding to align the icon at the top
                right: 10, // Adjust right padding to align the icon at the right
                child:  Container(
                width: 40,  
                height: 40, 
                alignment: Alignment.center,
                padding: EdgeInsets.all(4), // Example padding
                decoration: BoxDecoration(
                  color: iconbgColor, // Example background color
                  borderRadius: BorderRadius.circular(20) // Example rounded corners
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ), // Icon with adjusted color and size
              ),
              Positioned(
                bottom: 10, // Adjust bottom padding to align text at the bottom
                left: 5, // Adjust left padding to align text at the left
                child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
         for (var word in words) Text(
                  word,
                  style: TextStyle(
                    color: lightGray,
                    fontFamily: 'Karla',
                    fontSize: 12,
                  ),
                ),
        ],
      ),
                 
              ),
              /*
              Container(
                width: 40,  
                height: 40, 
                alignment: Alignment.center,
                padding: EdgeInsets.all(4), // Example padding
                decoration: BoxDecoration(
                  color: iconbgColor, // Example background color
                  borderRadius: BorderRadius.circular(20) // Example rounded corners
                ),
                child: Icon(icon, color: iconColor, size: 25),
              ),
              const SizedBox(height: 8),
              Container(
              child: Text(
                label,
                style: TextStyle(color: lightGray, fontFamily: 'Karla'),
                textAlign: TextAlign.left,  // Ensures the text is centered within its container
              ),
              ),*/
              ],
            ),
          ),
        ),
      );
    }
  }
  

Widget _buildLatestChallenge() {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('challenges')
        .orderBy('start_date', descending: true)
        .limit(1)
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return Center(child: Text('No latest challenge available.', style: TextStyle(color: lightGray)));
      }

      var challenge = snapshot.data!.docs.first;
      var data = challenge.data() as Map<String, dynamic>;
      final String challengeId = challenge.id;
      var title = data['title'] ?? 'Unknown Challenge';
      var imageCode = data['image'] ?? ''; // Make sure this field exists and contains valid base64 string for image.

      return Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: offBlack, // Card background color
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              spreadRadius: 0,
              blurRadius: 10,
              offset: Offset(0, 5), // Changes position of shadow
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: 
              ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundImage: MemoryImage(base64Decode(imageCode)),
                  ),
                ),
            ),
            SizedBox(width: 20),
            Expanded(
              child: 
                Column(
                  
              crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Discover the latest challenge',
                                      style: const TextStyle(
                                        fontFamily: 'Karla',
                                        fontSize: 12,
                                        //fontWeight: FontWeight.bold,
                                        color: Color.fromARGB(255, 195, 193, 193),
                                      ),
                                    ),
                                    Text(
                                      title,
                                      style: const TextStyle(
                                        fontFamily: 'Karla',
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: lightGray,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ]
                ),
            ),
             // Inline custom arrow button
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChallengeDetailsScreen(challengeId: challengeId),
              ),
            );
          },
          child: Container(
            width: 25,
            height: 25,
            decoration: BoxDecoration(
              color: darkCharcoal, // Background color of the circle
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.arrow_forward_ios,
                color: lightGray,
                size: 15,
              ),
            ),
          ),
        ),
          ],
        ),
      );
    },
  );
  
}



/// Auto-rotating announcement card list.
class SmartStackRotatingAnnouncements extends StatefulWidget {
  const SmartStackRotatingAnnouncements({Key? key}) : super(key: key);

  @override
  _SmartStackRotatingAnnouncementsState createState() =>
      _SmartStackRotatingAnnouncementsState();
}

class _SmartStackRotatingAnnouncementsState
    extends State<SmartStackRotatingAnnouncements> {
  List<DocumentSnapshot> _announcements = [];
  int _currentIndex = 0;
  Timer? _autoRotateTimer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAnnouncements();
  }

  @override
  void dispose() {
    _autoRotateTimer?.cancel();
    super.dispose();
  }

  /// Fetch all docs from `announcements` collection.
  Future<void> _fetchAnnouncements() async {
  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('announcements')
        .orderBy('start_date', descending: false)
        .get();

    final now = DateTime.now();
    // Filter announcements where the end_date is after now.
    final activeAnnouncements = snapshot.docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final Timestamp? endStamp = data['end_date'] as Timestamp?;
      if (endStamp == null) return true; // or return false if you want to exclude those without an end date
      final endDate = endStamp.toDate();
      return endDate.isAfter(now);
    }).toList();

    setState(() {
      _announcements = activeAnnouncements;
      _isLoading = false;
    });

    // If there's more than one active announcement, start auto-rotating every 3 seconds.
    if (_announcements.length > 1) {
      _autoRotateTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _announcements.length;
        });
      });
    }
  } catch (e) {
    debugPrint("Error fetching announcements: $e");
    setState(() {
      _isLoading = false;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_announcements.isEmpty) {
      return const Text("No announcements available",
          style: TextStyle(color: Colors.white));
    }

    // Get the current announcement doc
    final doc = _announcements[_currentIndex];
    final data = doc.data() as Map<String, dynamic>;

    // Fields from Firestore
    final String title = data['title'] ?? 'No Title';
    final Timestamp? startStamp = data['start_date'] as Timestamp?;
    final Timestamp? endStamp = data['end_date'] as Timestamp?;
    final String imageBase64 = data['image'] ?? '';
    final String docId = doc.id;

    // Format period from start_date to end_date
    String period = "";
    if (startStamp != null && endStamp != null) {
      final startDate = startStamp.toDate();
      final endDate = endStamp.toDate();
      final formatter = DateFormat('d MMM yyyy');
      period = "${formatter.format(startDate)} - ${formatter.format(endDate)}";
    }

    // Decode image
    Uint8List? imageBytes;
    if (imageBase64.isNotEmpty) {
      try {
        imageBytes = base64Decode(imageBase64);
      } catch (e) {
        debugPrint("Error decoding announcement image: $e");
      }
    }

    // Build the announcement card layout
  return Container(
  margin: const EdgeInsets.symmetric(vertical: 8),
  decoration: BoxDecoration(
    color: offBlack,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // TOP SECTION (text + Explore button), with padding
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row #1: Announcement label + Explore button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                 Text(
                  "Announcement",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.grey.shade300,
                  ),
                ),
                Text(
                  "Look out for events here!",
                  style: TextStyle(
                    
                    fontSize: 10,
                    color: Colors.grey.shade300,
                  ),
                ),
                  ]
                ),
                ElevatedButton(
                  onPressed: () {
                    // Navigate to details
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AnnouncementDetailsScreen(
                          announcementId: docId,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkCharcoal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    "Details",
                    style: TextStyle(color: lightGray),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),

            // Row #2: Title (left) + Period (right)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title: allow multi-line wrapping without breaking in the middle of words
                Expanded(
                  child: Text(
                    title, // from your announcement doc
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: lightGray,
                    ),
                    softWrap: true,       // allow multi-line
                    maxLines: null,       // unlimited lines
                    overflow: TextOverflow.visible,
                  ),
                ),
                const SizedBox(width: 8),

                // Period column: label + date range
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                     const SizedBox(height: 8),
                     Text(
                      "Period",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade300,
                      ),
                    ),
                    
                    Text(
                      period, // e.g., "26 Feb 2025 - 28 Feb 2025"
                      style: const TextStyle(
                        fontSize: 12,
                        color: lightGray,
                 
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),

      // BOTTOM SECTION (image) with NO extra padding
      if (imageBytes != null)
        ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          child: Image.memory(
            imageBytes,
            fit: BoxFit.cover,
            height: 100,
            width: double.infinity,
            // No fixed height -> the image will fill width, 
            // and scale height based on its aspect ratio
          ),
        )
      else
        const Icon(Icons.image, size: 40, color: Colors.grey),
    ],
  ),
);



  }
}

class AnnouncementDetailsScreen extends StatelessWidget {
  final String announcementId;

  const AnnouncementDetailsScreen({Key? key, required this.announcementId})
      : super(key: key);

   // Format date "DD MMM YYYY"
  String _formatDate(DateTime dt) {
    final months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    return "${dt.day} ${months[dt.month - 1]} ${dt.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Announcements',
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
          icon: const Icon(Icons.arrow_back_ios, color: lightGray, size: 21),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      backgroundColor: darkCharcoal,
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('announcements')
            .doc(announcementId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text(
                "Announcement not found",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final String title = data['title'] ?? 'No Title';
          final String details = data['description'] ?? 'No details provided.';
          
          final Timestamp? startStamp = data['start_date'] as Timestamp?;
          final Timestamp? endStamp = data['end_date'] as Timestamp?;
           String startDateFormatted = "";
          String endDateFormatted = "";
          String period = "";
          if (startStamp != null && endStamp != null) {
            final startDate = startStamp.toDate();
            final endDate = endStamp.toDate();
            final formatter = DateFormat('d MMM yyyy');
            startDateFormatted = _formatDate(startStamp.toDate());
            endDateFormatted = _formatDate(endStamp.toDate());
            period =
                "${formatter.format(startDate)} - ${formatter.format(endDate)}";
          }

           final imageBase64 = data['image'] as String?;
          Uint8List? announcementImageBytes;
          if (imageBase64 != null && imageBase64.isNotEmpty) {
            try {
              announcementImageBytes = base64Decode(imageBase64);
            } catch (_) {}
          }
          final List<dynamic> additionalImages = data['additional_images'] ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                announcementImageBytes != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.memory(
                                announcementImageBytes,
                                fit: BoxFit.cover,
                                height: 170,
                                width: double.infinity,
                              ),
                            )
                          : Container(
                            height: 170,
                              decoration: BoxDecoration(
                                color: Colors.black26,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.image,
                                  size: 48,
                                  color: lightGray,
                                ),
                              ),
                            ),
                const SizedBox(height: 10),
                // NEW: Horizontal carousel for additional images:
                additionalImages != null && additionalImages.isNotEmpty
                    ? SizedBox(
                        height: 80, // Fixed height for each square image
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: additionalImages.length,
                          itemBuilder: (context, index) {
                            final base64Str = additionalImages[index] as String;
                            Uint8List? imgBytes;
                            try {
                              imgBytes = base64Decode(base64Str);
                            } catch (e) {
                              debugPrint("Error decoding additional image: $e");
                            }
                            return Container(
                              width: 80,
                              height: 80,
                              margin: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                              onTap: () {
                                if (imgBytes != null) {
                                  showDialog(
                                    context: context,
                                    builder: (context) => Dialog(
                                      backgroundColor: Colors.transparent,
                                      insetPadding: const EdgeInsets.all(16),
                                      child: InteractiveViewer(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.memory(
                                            imgBytes!,
                                            fit: BoxFit.contain,
                                            width: double.infinity,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: imgBytes != null
                                    ? Image.memory(
                                        imgBytes,
                                        fit: BoxFit.cover,
                                        width: 80,
                                        height: 80,
                                      )
                                    : Container(
                                        color: Colors.black26,
                                        child: const Center(
                                          child: Icon(
                                            Icons.image,
                                            size: 40,
                                            color: lightGray,
                                          ),
                                        ),
                                      ),
                              ),
                              ),
                            );
                          },
                        ),
                      )
                    : const SizedBox.shrink(),
                const SizedBox(height: 8),
                  Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
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
                const SizedBox(height: 16),
                Text(
                  details,
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
