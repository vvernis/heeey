import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

import 'challenge_details_screen.dart';

// Existing color scheme
const Color darkCharcoal = Color(0xFF29292B);
const Color offBlack = Color(0xFF343436);
const Color vividYellow = Color(0xFFd7ed73);
const Color lightGray = Color(0xFFF0F0E6);

// Filter types
enum ChallengeFilter { all, ongoing, upcoming, past }

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  _ChallengesScreenState createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;

  /// Track which filter is currently selected (default All).
  ChallengeFilter _selectedFilter = ChallengeFilter.all;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Available Challenges',
          style: TextStyle(
            fontFamily: 'Karla',
            color: lightGray,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: darkCharcoal,
        iconTheme: const IconThemeData(color: lightGray),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: lightGray, size: 21),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // 1) Filter Chips
          _buildFilterChips(),
          // 2) Challenges List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('challenges')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Error fetching challenges.'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No challenges available.'));
                }

                // All docs from Firestore
                final challenges = snapshot.data!.docs;

                // Filter them based on the selected filter
                final filteredChallenges = challenges.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final start = (data['start_date'] as Timestamp?)?.toDate() ??
                      DateTime.now();
                  final end = (data['end_date'] as Timestamp?)?.toDate() ??
                      DateTime.now();
                  final now = DateTime.now();

                  final isOngoing = now.isAfter(start) && now.isBefore(end);
                  final isUpcoming = now.isBefore(start);
                  final isPast = now.isAfter(end);

                  switch (_selectedFilter) {
                    case ChallengeFilter.ongoing:
                      return isOngoing;
                    case ChallengeFilter.upcoming:
                      return isUpcoming;
                    case ChallengeFilter.past:
                      return isPast;
                    case ChallengeFilter.all:
                    default:
                      return true; // show all
                  }
                }).toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: filteredChallenges.length,
                  itemBuilder: (context, index) {
                    final challenge = filteredChallenges[index];
                    return _buildChallengeCard(context, challenge);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the row of filter chips (All, Ongoing, Upcoming, Past).
  Widget _buildFilterChips() {
    return Container(
      color: darkCharcoal,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(width: 5),
          _buildSingleFilterChip(ChallengeFilter.all),
          const SizedBox(width: 6),
          _buildSingleFilterChip(ChallengeFilter.ongoing),
          const SizedBox(width: 6),
          _buildSingleFilterChip(ChallengeFilter.upcoming),
          const SizedBox(width: 6),
          _buildSingleFilterChip(ChallengeFilter.past),
          const SizedBox(width: 5),
        ],
      ),
    );
  }

  /// Helper to build a single ChoiceChip with icon + text using custom colors.
  Widget _buildSingleFilterChip(ChallengeFilter filter) {
    final bool isSelected = (_selectedFilter == filter);
    return ChoiceChip(
      showCheckmark: false,
      selected: isSelected,
      onSelected: (_) {
        setState(() => _selectedFilter = filter);
      },
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getFilterIcon(filter),
            size: 16,
            color: isSelected ? offBlack : _getFilterColor(filter),
          ),
          const SizedBox(width: 4),
          Text(
            _getFilterLabel(filter),
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
      selectedColor: _getFilterColor(filter).withOpacity(0.8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  /// Returns a label for each filter.
  String _getFilterLabel(ChallengeFilter filter) {
    switch (filter) {
      case ChallengeFilter.all:
        return 'All';
      case ChallengeFilter.ongoing:
        return 'Ongoing';
      case ChallengeFilter.upcoming:
        return 'Upcoming';
      case ChallengeFilter.past:
        return 'Past';
    }
  }

  /// Returns an icon for each filter.
  IconData _getFilterIcon(ChallengeFilter filter) {
    switch (filter) {
      case ChallengeFilter.all:
        return Icons.all_inclusive;
      case ChallengeFilter.ongoing:
        // Use hourglass icon for ongoing (more understandable)
        return Icons.hourglass_top;
      case ChallengeFilter.upcoming:
        return Icons.schedule;
      case ChallengeFilter.past:
        return Icons.history;
    }
  }

  /// Returns a color for each filter/status.
  Color _getFilterColor(ChallengeFilter filter) {
    switch (filter) {
      case ChallengeFilter.all:
        return vividYellow;
      case ChallengeFilter.ongoing:
        return vividYellow;
      case ChallengeFilter.upcoming:
        return Color(0xffffde5a);
      case ChallengeFilter.past:
        return Color(0xffcc6969);
    }
  }

  /// Build the card for each challenge.
  Widget _buildChallengeCard(
    BuildContext context,
    QueryDocumentSnapshot challenge,
  ) {
    final data = challenge.data() as Map<String, dynamic>;
    final String challengeId = challenge.id;
    final String title = data['title'] ?? 'Unknown Challenge';
    final String mode = data['mode'] ?? 'TBD';
    final String type = data['type'] ?? 'TBD';
    final String about = data['about'] ?? '';

    // 'participants' is a number.
    final num rawParticipants = data['participants'] ?? 0;
    final int participantCount = rawParticipants.toInt();
    final String participantDisplay = participantCount.toString();

    // Start/end date.
    final DateTime startDate =
        (data['start_date'] as Timestamp?)?.toDate() ?? DateTime.now();
    final DateTime endDate =
        (data['end_date'] as Timestamp?)?.toDate() ?? DateTime.now();
    final String formattedPeriod =
        '${DateFormat('d MMM').format(startDate)} - ${DateFormat('d MMM').format(endDate)}';

    // Determine status booleans.
    final now = DateTime.now();
    final bool isOngoing = now.isAfter(startDate) && now.isBefore(endDate);
    final bool isUpcoming = now.isBefore(startDate);
    final bool isPast = now.isAfter(endDate);

    // Choose status icon and pill color.
    IconData statusIcon;
    Color pillColor;
    if (isOngoing) {
      statusIcon = Icons.hourglass_top;
      pillColor = vividYellow;
    } else if (isUpcoming) {
      statusIcon = Icons.schedule;
      pillColor = Color(0xffffde5a);
    } else if (isPast) {
      statusIcon = Icons.history;
      pillColor = Color(0xffcc6969);
    } else {
      statusIcon = Icons.help;
      pillColor = vividYellow;
    }

    // Base64 decode the image or fallback.
    final String imageCode =
        data['image'] ?? 'lib/mobile/assets/images/fallback.png';

    return Container(
      margin: const EdgeInsets.only(bottom: 20, left: 5, right: 5),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: offBlack,
        elevation: 5,
        shadowColor: Colors.black.withOpacity(0.5),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Stack(
            children: [
              // Bottom layer: normal row layout (image + text)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: Stack with image and status pill (icon only).
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          base64Decode(imageCode),
                          width: 80,
                          height: 95,
                          fit: BoxFit.cover,
                        ),
                      ),
                      if (isOngoing || isUpcoming || isPast)
                        Positioned(
                          top: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: pillColor.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              statusIcon,
                              size: 12,
                              color: offBlack,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  // Expanded column: title, period, about, and pills.
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row: Title + participant count.
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontFamily: 'Karla',
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.groups,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  participantDisplay,
                                  style: const TextStyle(
                                    fontFamily: 'Karla',
                                    fontSize: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Period row.
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_month,
                              color: vividYellow,
                              size: 15,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              formattedPeriod,
                              style: const TextStyle(
                                fontFamily: 'Karla',
                                fontSize: 12,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // About text, 2 lines max.
                        Text(
                          about,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Karla',
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Pills for Mode and Type.
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: vividYellow.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: vividYellow,
                                    size: 15,
                                  ),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: vividYellow.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.videogame_asset,
                                    color: vividYellow,
                                    size: 15,
                                  ),
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
              // Top layer: Arrow button pinned center-right.
              Positioned.fill(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ChallengeDetailsScreen(challengeId: challengeId),
                        ),
                      );
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chevron_right,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
