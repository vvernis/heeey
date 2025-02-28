import 'package:flutter/material.dart';
import 'package:heeey/mobile/screens/matching%20system/filter_screen.dart';
import 'match_requests_screen.dart';

// Define the color palette
const Color darkCharcoal = Color(0xFF29292B);
const Color offBlack = Color(0xFF343436);
const Color vividYellow = Color(0xFFd7ed73);
const Color lightGray = Color(0xFFF0F0E6);

class MatchingSystemHome extends StatelessWidget {
  const MatchingSystemHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Matching System',
          style: TextStyle(fontFamily: 'Karla', color: lightGray, fontSize: 17, fontWeight: FontWeight.bold),
        ),
        backgroundColor: darkCharcoal,
        iconTheme: const IconThemeData(color: lightGray),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: lightGray, size: 21),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      backgroundColor: darkCharcoal,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            // Option Buttons with the desired layout
            _buildOptionButton(
              context: context,
              title: 'Match New',
              subtitle: 'Explore new connections today.',
              imagePath: 'lib/mobile/assets/images/joined.png', // Path to your image
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FiltersScreen(),
                    ),
                  );
              },
            ),
            const SizedBox(height: 16),
           _buildOptionButton(
              context: context,
              title: 'View Match Requests',
              subtitle: 'Check request sent to you.',
              imagePath: 'lib/mobile/assets/images/avail.png', // Path to your image
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MatchRequestsScreen(),
                    ),
                  );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String imagePath,
    required VoidCallback onTap,
  }) {
    List<String> words = title.split(' ');
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 175,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        decoration: BoxDecoration(
          color: offBlack,
          borderRadius: BorderRadius.circular(20),
          image: DecorationImage(
            image: AssetImage(imagePath),
            fit: BoxFit.contain,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              spreadRadius: 0,
              blurRadius: 10,
              offset: Offset(0, 5), // Changes position of shadow
            ),
          ],
        ),
        child: Padding( // Wrap RichText in Padding
        padding: const EdgeInsets.only(top: 7),
       child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Text(
          title,
          style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: lightGray,
                  fontFamily: 'Karla',
          )
          ),
        Text(
          subtitle,
          style: TextStyle(
                    fontFamily: 'Karla',
                    fontSize: 12,
                    //fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 195, 193, 193),
                )
                )
        ]
       )
      ),
      ),
    );
  }
}
