import 'package:flutter/material.dart';
import 'package:heeey/mobile/screens/challenges/challenges_screen.dart';
import 'joined_challenges.dart';


class ChallengeHomeScreen extends StatelessWidget {
  const ChallengeHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Challenges',
          style: TextStyle(fontFamily: 'Karla', color: Colors.black),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
        centerTitle: true,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome to the Challenge System',
              style: TextStyle(
                fontFamily: 'Karla', 
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Find and manage your challenges using the options below.',
              style: TextStyle(fontFamily: 'Karla', fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            _buildOptionButton(
              context: context,
              title: 'Joined Challenges',
              subtitle: 'View challenges you are part of.',
              icon: Icons.event,
              backgroundColor: const Color(0xFFEDE7FF),
              iconColor: const Color(0xFF8A56AC),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const JoinedChallengesScreen(),
                    ),
                  );
              },
            ),
            const SizedBox(height: 16),
            _buildOptionButton(
              context: context,
              title: 'Available Challenges',
              subtitle: 'Explore new challenges to join.',
              icon: Icons.explore,
              backgroundColor: const Color(0xFFFFF3E7),
              iconColor: const Color(0xFFF57C00),
              onTap: () {
                 Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChallengesScreen(),
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
    required IconData icon,
    required Color backgroundColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 28,
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
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Karla', 
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
