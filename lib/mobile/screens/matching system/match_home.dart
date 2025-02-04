import 'package:flutter/material.dart';
import 'package:heeey/mobile/screens/matching%20system/filter_screen.dart';
import 'match_requests_screen.dart';

class MatchingSystemHome extends StatelessWidget {
  const MatchingSystemHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Matching System',
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Section
            const Text(
              "Welcome to the Matching System",
              style: TextStyle(
                fontFamily: 'Karla', 
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Find your perfect match by exploring the options below.",
              style: TextStyle(fontFamily: 'Karla', fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Purple Button (Match New)
            Card(
              color: const Color(0xFFF2E8FF), // Light purple background
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFB47BFF), Color(0xFF8B45FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(
                    Icons.search,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                title: const Text(
                  'Match New',
                  style: TextStyle(
                    fontFamily: 'Karla', 
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B45FF),
                  ),
                ),
                subtitle: const Text(
                  'Explore new connections today.',
                  style: TextStyle(fontFamily: 'Karla', color: Colors.grey),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  color: Color(0xFF8B45FF),
                  size: 18,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FiltersScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Yellow Button (View Match Requests)
            Card(
              color: const Color(0xFFFFF4E5), // Light yellow background
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFC764), Color(0xFFFFA200)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                title: const Text(
                  'View Match Requests',
                  style: TextStyle(
                    fontFamily: 'Karla', 
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFA200),
                  ),
                ),
                subtitle: const Text(
                  'Check requests sent to you.',
                  style: TextStyle(fontFamily: 'Karla', color: Colors.grey),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  color: Color(0xFFFFA200),
                  size: 18,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MatchRequestsScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
