import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notifications_screen.dart';
import 'chats_screen.dart';
import 'profile_screen.dart';
import 'package:intl/intl.dart';
import 'challenges/challenge_details_screen.dart';
import 'dart:convert';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = "Loading..."; // Default placeholder for the user's name
  bool isLoading = true; // Track loading state
  int _currentIndex = 0;

  late final List<Widget> _pages; // Pages will populate dynamically

  @override
  void initState() {
    super.initState();
    _initializeHomeScreen(); // Combine initialization steps
  }

  Future<void> _initializeHomeScreen() async {
    await fetchUserName(); // Ensure userName is fetched first
    initializePages(); // Then initialize navigation pages
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
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Image.asset(
                    'lib/mobile/assets/images/LOGOappbar.png',
                    width: 100, // Adjust as needed
                    height: 100, // Adjust as needed
                    fit: BoxFit.contain,
                  ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout, color: Colors.black),
          ),
        ],
      ),
      
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
            child: Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.1,
              decoration: BoxDecoration(
                color: Colors.white,
                 borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                  ),
                ],
              ),
              
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.transparent,
                elevation: 0,
                selectedItemColor: Colors.black,
                unselectedItemColor: Colors.grey,
                selectedFontSize: 12,
                unselectedFontSize: 12,
                items: const [
                  BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                  BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notifications'),
                  BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chats'),
                  BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
                ],
              ),
            ),
          ),
        ],
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
            // Welcome Back Section
            const Text(
              'Welcome Back,',
              style: TextStyle(fontSize: 18, color: Colors.grey, fontFamily: 'Karla'),
            ),
            const SizedBox(height: 4),
            Text(
              userName.toUpperCase(), // Display the user's name
              style: const TextStyle(
                fontFamily: 'Karla',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),

            // Latest Challenge Placeholder
             Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: StreamBuilder<QuerySnapshot>(
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
                    return ListTile(
                      title: const Text(
                        'Latest Challenge',
                        style: TextStyle(fontSize: 16, color: Colors.black),
                      ),
                      subtitle: const Text('No latest challenge available.'),
                      trailing: const Icon(Icons.arrow_forward),
                      onTap: () {
                         // empty
                      },
                    );
                  }

                  final latestChallenge = snapshot.data!.docs.first;
                  final data = latestChallenge.data() as Map<String, dynamic>;
                  final String challengeId = latestChallenge.id;
                  final String title = data['title'] ?? 'Unknown Challenge';
                  final String mode = data['mode'] ?? 'TBD';
                  final String type = data['type'] ?? 'TBD';
                  final String imageCode = data['image'] ?? '';
                  final DateTime startDate =
                      (data['start_date'] as Timestamp).toDate();
                  final DateTime endDate =
                      (data['end_date'] as Timestamp).toDate();

                  final String formattedPeriod =
                      '${DateFormat('d MMM').format(startDate)} - ${DateFormat('d MMM').format(endDate)}';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'Latest Challenge',
                          style: TextStyle(fontSize: 16, color: Colors.black,fontFamily: 'Karla'),
                        ),
                      ),
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Card(
                        color: Colors.grey[900],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: CircleAvatar(
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
                                      overflow: TextOverflow.ellipsis,
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
                              IconButton(
                                icon: const Icon(Icons.arrow_forward, color: Colors.white),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChallengeDetailsScreen(challengeId: challengeId),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Features Section
            const Text(
              'Features',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black, fontFamily: 'Karla'),
            ),
            const SizedBox(height: 8),
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
                  _buildFeatureButton(context, 'Find  Challenges', Icons.emoji_events, '/challenges', Color(0xD9FFEDA5), Color(0xFF636304)),
                  _buildFeatureButton(context, 'Matching System', Icons.person_add, '/match-home', Color(0xD9FF57A0), Color(0xFF911240)),
                  _buildFeatureButton(context, 'Memory   Gallery', Icons.photo_library, '/memory_gallery', Color(0xD9F0C69B), Color(0xFFB7762C)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Highlights Section
            const Text(
              'Highlights',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black, fontFamily: 'Karla'),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/memory_gallery');
              },
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[300]
                ),
                child: const Center(
                  child: Text(
                    'Map Placeholder (Memory Gallery)',
                    style: TextStyle(color: Colors.black54, fontFamily: 'Karla'),
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
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, route);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),  // Shadow color with transparency
                spreadRadius: 1,  // Extend the shadow outward
                blurRadius: 10,   // Blur radius to soften the shadow
                offset: Offset(0, 4),  // Offset in x, y direction to give an elevated effect
              ),
            ],
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 10, top: 3), 
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,  // Specifies the width of the square
                height: 40, // Specifies the height of the square
                alignment: Alignment.center,
                padding: EdgeInsets.all(4), // Example padding
                decoration: BoxDecoration(
                  color: iconbgColor, // Example background color
                  borderRadius: BorderRadius.circular(6) // Example rounded corners
                ),
                child: Icon(icon, color: iconColor, size: 25),
              ),
              const SizedBox(height: 8),
              Container(
              child: Text(
                label,
                style: TextStyle(color: Colors.black, fontFamily: 'Karla'),
                textAlign: TextAlign.left,  // Ensures the text is centered within its container
              ),
              ),
              ],
            ),
          ),
        ),
      );
    }
  }
