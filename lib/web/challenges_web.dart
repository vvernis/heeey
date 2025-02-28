import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:flutter/material.dart';
import 'package:heeey/mobile/screens/memory%20gallery/memory_gallery.dart';
import 'package:heeey/web/challenge_submission_web.dart';
import 'package:heeey/web/user_data_web.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

const Color kBorderGray    = Color(0xFFE1E1E1);


  /// Custom InputDecoration for all fields.
  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: const BorderSide(color: kBorderGray, width: 1.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: const BorderSide(color: kBorderGray, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: const BorderSide(color: offBlack, width: 0.8),
      ),
      isDense: true,
    );
  }


/// Compresses and converts a main image file to a Base64 string.
/// (Only used on non-web platforms.)
Future<String> compressAndConvertToBase64(File file) async {
  try {
    final originalBytes = await file.readAsBytes();
    final originalImage = img.decodeImage(originalBytes);
    if (originalImage == null) throw Exception("Failed to decode the image.");

    // Target max size in bytes (1 MB)
    const int targetMaxBytes = 1048576;
    int quality = 50;
    List<int> compressedBytes;

    // Try compressing until the raw bytes are below targetMaxBytes.
    do {
      final resizedImage = img.copyResize(originalImage, width: 150);
      compressedBytes = img.encodeJpg(resizedImage, quality: quality);
      quality -= 10;
    } while (compressedBytes.length > targetMaxBytes && quality > 10);

    return base64Encode(compressedBytes);
  } catch (e) {
    print("Error compressing and encoding image: $e");
    rethrow;
  }
}

/// Compresses and converts an additional image file to a Base64 string.
/// This function dynamically reduces width and quality until the
/// compressed image is under a target size (here ~750KB raw bytes).
Future<String> compressAdditionalImageStrict(File file) async {
  try {
    final originalBytes = await file.readAsBytes();
    final originalImage = img.decodeImage(originalBytes);
    if (originalImage == null) throw Exception("Failed to decode image.");

    // Set a target raw size (e.g., 750 KB)
    const int targetRawSize = 768000;
    int quality = 30; // start with a lower quality
    int width = 80; // start with a smaller width
    String base64Result = "";
    bool sizeOk = false;

    while (!sizeOk && quality > 5 && width > 30) {
      final resizedImage = img.copyResize(originalImage, width: width);
      final compressedBytes = img.encodeJpg(resizedImage, quality: quality);
      base64Result = base64Encode(compressedBytes);

      // Check raw byte size (not the base64 string length)
      if (compressedBytes.length < targetRawSize) {
        sizeOk = true;
      } else {
        quality -= 5;
        width -= 10;
      }
    }

    if (!sizeOk) {
      throw Exception("Could not compress additional image under target size");
    }

    return base64Result;
  } catch (e) {
    print("Error compressing additional image: $e");
    rethrow;
  }
}

class ChallengesDashboardPage extends StatefulWidget {
  const ChallengesDashboardPage({Key? key}) : super(key: key);

  @override
  _ChallengesDashboardPageState createState() =>
      _ChallengesDashboardPageState();
}

class _ChallengesDashboardPageState extends State<ChallengesDashboardPage> {
  final CollectionReference challenges =
      FirebaseFirestore.instance.collection('challenges');

  // ---------------- Fields for Create/Edit Dialog ----------------
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();
  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _submissionOptionsController =
      TextEditingController();
  final TextEditingController _onlineSubmissionController =
      TextEditingController();
  final TextEditingController _minParticipantsController =
      TextEditingController();
  final TextEditingController _maxParticipantsController =
      TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedMode;
  String? _selectedType;
  Uint8List? _challengeImageBytes;
  final List<Uint8List> _additionalChallengeImages = [];
  final ImagePicker _picker = ImagePicker();

  final List<String> _mode = ['Online', 'In-Person', 'Hybrid'];
  final List<String> _type = [
    'The Escape',
    'Riddle Me This',
    'Story-Based',
    'Amazing Race',
    'Cultural Detective'
  ];

  // ---------------- Sample Templates for Each Challenge Type ----------------
  final Map<String, Map<String, String>> _challengeTemplates = {
    "The Escape": {
      "about":
          "(Customizable: Solve puzzles, follow clues, and escape from a situation.)",
      "groupSize": "2-5 people",
      "objective":
          "Work as a team to crack the final solution before time runs out.",
      "prompt":
          "Your team is locked in a secret NTU research facility. The only way out? Solve the clues hidden across campus before security resets.",
      "submission":
          "Each group member must submit one unique photo.\nLock & Key Pose: Each member forms a key shape with their body.\nFinal Unlock: Act out a dramatic 'Eureka!' moment when solving the final puzzle.\nSecret Message: Write the final answer on a whiteboard and hold it up in a selfie.",
      "online":
          "Virtual Escape: Solve a digital puzzle as a team.\nHidden Clues: Share screenshots of hidden messages found online.\nEscape Room Overlay: Edit photos with escape-themed effects and stickers."
    },
    "Riddle Me This": {
      "about":
          "(Customizable: A classic scavenger hunt where participants solve riddles to find locations or objects.)",
      "groupSize": "2-5 people",
      "objective":
          "Crack the riddles, find the hidden spot, and capture a creative moment.",
      "prompt":
          "Solve the riddle to discover the hidden location and complete the challenge.",
      "submission":
          "Each group member must submit one unique photo.\nReflection Challenge: Capture a water reflection.\nPerspective Play: Create an optical illusion using the location.\nJump Shot: Everyone jumps with the landmark in the background.",
      "online":
          "Virtual Background: Set a virtual background of an NTU landmark.\nSynchronized Collage: Each member submits a photo from their location to form a collage.\nDigital Filter: Apply a detective filter (e.g., a magnifying glass overlay)."
    },
    "Story-Based": {
      "about":
          "(Customizable: A role-playing, interactive storytelling challenge where participants follow a scripted mystery.)",
      "groupSize": "2-5 people",
      "objective":
          "Take on character roles, uncover secrets, and solve the final mystery.",
      "prompt":
          "You are time travelers sent to NTU in 2050. Your mission? Find the futuristic landmark where students still gather to learn.",
      "submission":
          "Each group member must submit one unique photo.\nCharacter Pose: Each member strikes a pose matching their role.\nStory Snapshot: Capture a moment that represents a key scene in the adventure.\nFinal Chapter: Recreate an ending scene based on your group's interpretation.",
      "online":
          "Virtual Scene: Set a virtual background matching the storyline.\nDigital Storyboard: Create a collage of all mission photos with captions.\nTheatrical Clip: Record a short skit acting out part of the story."
    },
    "Amazing Race": {
      "about":
          "(Customizable: Fast-paced challenges where participants race to complete specific tasks across different checkpoints.)",
      "groupSize": "2-5 people",
      "objective":
          "Travel across NTU or Singapore and complete mini-challenges at each location.",
      "prompt":
          "Follow the given checkpoints and complete all tasks before reaching the final destination.",
      "submission":
          "Each group member must submit one unique photo.\nCheckpoint 1: Find a dish older than 50 years and take a creative food shot.\nCheckpoint 2: Find the structure inspired by nature and recreate its form using your group.\nCheckpoint 3: Perform a 10-second MRT dance challenge at a significant station!",
      "online":
          "Race Map: Edit a virtual race map with your team's progress.\nVideo Montage: Compile short clips from each checkpoint into a race recap.\nDigital Leaderboard: Display a creative scoreboard ranking all teams."
    },
    "Photographic Quest": {
      "about":
          "(Customizable: Complete fun, creative photo missions based on different prompts.)",
      "groupSize": "2-5 people",
      "objective": "Capture unique moments with specific themes or actions.",
      "prompt":
          "Follow the given prompts and take the most creative photos possible.",
      "submission":
          "Each group member must submit one unique photo.\nJump Shot: Everyone must be mid-air with a landmark behind.\nPerspective Play: Make a giant look tiny using forced perspective.\nShadow Art: Use your group’s shadows to create an interesting shape.",
      "online":
          "Virtual Photography: Edit digital effects onto your photo.\nCollage Challenge: Combine all group photos into a themed collage.\nPhotography Quiz: Create a short quiz based on the pictures taken."
    },
    "Cultural Detective": {
      "about":
          "(Customizable: Explore Singapore’s rich cultural heritage through interactive storytelling.)",
      "groupSize": "2-5 people",
      "objective":
          "Unravel hidden cultural symbols, complete tasks, and document findings.",
      "prompt":
          "Explore a cultural site, uncover hidden meanings, and complete themed tasks.",
      "submission":
          "Each group member must submit one unique photo.\nLantern Pose: Form a shape using lanterns or lights.\nTemple Tribute: Capture a moment of reflection at a historic site.\nCultural Dance: Try mimicking a traditional move and take a short clip.",
      "online":
          "Cultural Background: Set a virtual background of a famous cultural landmark.\nDigital Montage: Create a photo montage with cultural filters and stickers.\nVirtual Tour: Record a short video in front of a cultural icon at home."
    }
  };

  // ---------------- Track which challenge is “selected” for inline details ----------------
  DocumentSnapshot? _selectedChallengeDoc;

  // ---------------- Clear All Form Fields ----------------
  void _clearChallengeFields() {
    _titleController.clear();
    _aboutController.clear();
    _promptController.clear();
    _submissionOptionsController.clear();
    _onlineSubmissionController.clear();
    _minParticipantsController.clear();
    _maxParticipantsController.clear();
    setState(() {
      _challengeImageBytes = null;
      _additionalChallengeImages.clear();
      _selectedMode = null;
      _selectedType = null;
      _startDate = null;
      _endDate = null;
    });
  }


  // ---------------- Create/Edit Challenge Dialog with Two-Column Layout ----------------
Future<void> _addOrUpdateChallenge({DocumentSnapshot? challengeDoc}) async {
  // Prefill fields if editing.
  if (challengeDoc != null) {
    final data = challengeDoc.data() as Map<String, dynamic>;
    _titleController.text = data['title'] ?? '';
    _aboutController.text = data['about'] ?? '';
    _promptController.text = data['prompt'] ?? '';
    _submissionOptionsController.text = data['submission_options'] ?? '';
    _onlineSubmissionController.text = data['online_submission_notice'] ?? '';
    _selectedMode = data['mode'];
    _selectedType = data['type'];
    final tsStart = data['start_date'] as Timestamp?;
    final tsEnd = data['end_date'] as Timestamp?;
    _startDate = tsStart?.toDate();
    _endDate = tsEnd?.toDate();
    _minParticipantsController.text = data['min_participants']?.toString() ?? '';
    _maxParticipantsController.text = data['max_participants']?.toString() ?? '';
    final base64Img = data['image'] as String?;
    if (base64Img != null && base64Img.isNotEmpty) {
      try {
        _challengeImageBytes = base64Decode(base64Img);
      } catch (_) {}
    }
    _additionalChallengeImages.clear();
    final additionalImages = data['additional_images'] as List<dynamic>?;
    if (additionalImages != null) {
      for (var base64Str in additionalImages) {
        try {
          _additionalChallengeImages.add(base64Decode(base64Str as String));
        } catch (_) {}
      }
    }
  }

  await showDialog(
    context: context,
    builder: (context) {
      // Use StatefulBuilder for immediate UI updates.
      return StatefulBuilder(
        builder: (context, dialogSetState) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 800),
              child: Dialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Dialog Header
                       Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    challengeDoc == null ? "Create Challenge" : "Edit Challenge",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: offBlack,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                // Close icon at top-right
                                IconButton(
                                  icon: const Icon(Icons.close, color: offBlack),
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                              ],
                            ),
                        const SizedBox(height: 16),

                        // Three-column Layout
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left Column: Challenge Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "1. Challenge Details",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: offBlack,
                                    ),
                                  ),
                                  const Divider(),
                                  const SizedBox(height: 4),
                                  // Main Image Picker
                                  GestureDetector(
                                  onTap: () async {
                                    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                                    if (image != null) {
                                      if (kIsWeb) {
                                        final bytes = await image.readAsBytes();
                                        dialogSetState(() {
                                          _challengeImageBytes = bytes;
                                        });
                                      } else {
                                        File file = File(image.path);
                                        String compressedBase64 = await compressAndConvertToBase64(file);
                                        dialogSetState(() {
                                          _challengeImageBytes = base64Decode(compressedBase64);
                                        });
                                      }
                                    }
                                  },
                                  child: Container(
                                    height: 80,
                                    width: 80,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: _challengeImageBytes != null
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(5),
                                            child: Image.memory(_challengeImageBytes!, fit: BoxFit.cover),
                                          )
                                        : const Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Additional Images Picker with remove option
                                TextButton.icon(
                                  onPressed: () async {
                                    final List<XFile>? images = await _picker.pickMultiImage();
                                    if (images != null && images.isNotEmpty) {
                                      for (var image in images) {
                                        if (kIsWeb) {
                                          final bytes = await image.readAsBytes();
                                          dialogSetState(() {
                                            _additionalChallengeImages.add(bytes);
                                          });
                                        } else {
                                          File file = File(image.path);
                                          String compressedBase64 = await compressAdditionalImageStrict(file);
                                          dialogSetState(() {
                                            _additionalChallengeImages.add(base64Decode(compressedBase64));
                                          });
                                        }
                                      }
                                    }
                                  },
                                  icon: const Icon(Icons.add),
                                  label: const Text("Add Additional Images", style: TextStyle(fontSize: 12)),
                                ),
                                if (_additionalChallengeImages.isNotEmpty)
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: List.generate(
                                      _additionalChallengeImages.length,
                                      (index) {
                                        final imageBytes = _additionalChallengeImages[index];
                                        return Stack(
                                          children: [
                                            Container(
                                              width: 80,
                                              height: 80,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(5),
                                                image: DecorationImage(
                                                  image: MemoryImage(imageBytes),
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              top: 0,
                                              right: 0,
                                              child: GestureDetector(
                                                onTap: () {
                                                  dialogSetState(() {
                                                    _additionalChallengeImages.removeAt(index);
                                                  });
                                                },
                                                child: Container(
                                                  decoration: const BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: Colors.redAccent,
                                                  ),
                                                  child: const Icon(Icons.close, size: 16, color: Colors.white),
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Title Field
                                  TextField(
                                    controller: _titleController,
                                    decoration: InputDecoration(
                                      labelText: "Title",
                                      labelStyle: const TextStyle(fontSize: 12),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(5),
                                        borderSide: const BorderSide(
                                          color: kBorderGray,
                                          width: 1.0,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(5),
                                        borderSide: const BorderSide(
                                          color: kBorderGray,
                                          width: 1.0,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(5),
                                        borderSide: const BorderSide(
                                          color: offBlack,
                                          width: 0.8,
                                        ),
                                      ),
                                      isDense: true,
                                    ),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  const SizedBox(height: 8),

                                  // About Field
                                  TextField(
                                    controller: _aboutController,
                                    decoration: InputDecoration(
                                      labelText: "About",
                                      labelStyle: const TextStyle(fontSize: 12),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(5),
                                        borderSide: const BorderSide(
                                          color: kBorderGray,
                                          width: 1.0,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(5),
                                        borderSide: const BorderSide(
                                          color: kBorderGray,
                                          width: 1.0,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(5),
                                        borderSide: const BorderSide(
                                          color: offBlack,
                                          width: 0.8,
                                        ),
                                      ),
                                      isDense: true,
                                    ),
                                    maxLines: 2,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  const SizedBox(height: 8),

                                  // Type Dropdown with Instruction
                                  DropdownButtonFormField<String>(
                                    value: _selectedType,
                                    decoration: InputDecoration(
                                      labelText: "Select Type",
                                      labelStyle: const TextStyle(fontSize: 12),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(5),
                                        borderSide: const BorderSide(
                                          color: kBorderGray,
                                          width: 1.0,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(5),
                                        borderSide: const BorderSide(
                                          color: kBorderGray,
                                          width: 1.0,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(5),
                                        borderSide: const BorderSide(
                                          color: offBlack,
                                          width: 0.8,
                                        ),
                                      ),
                                      isDense: true,
                                    ),
                                    items: _type
                                        .map((type) => DropdownMenuItem(
                                              value: type,
                                              child: Text(
                                                type,
                                                style: const TextStyle(fontSize: 12),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ))
                                        .toList(),
                                    onChanged: (val) {
                                      dialogSetState(() {
                                        _selectedType = val;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 4),

                                  // "Load Sample Template" button
                                  if (_selectedType != null &&
                                      _challengeTemplates.containsKey(_selectedType))
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: () {
                                          dialogSetState(() {
                                            final sample = _challengeTemplates[_selectedType]!;
                                            _aboutController.text = sample["about"]!;
                                            _promptController.text = sample["prompt"]!;
                                            _submissionOptionsController.text = sample["submission"]!;
                                            _onlineSubmissionController.text = sample["online"] ?? "";
                                          });
                                        },
                                        child: const Text(
                                          "Load Sample Template",
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ),

                                  const Text(
                                    "Please select a challenge type first to load template guidelines.",
                                    style: TextStyle(fontSize: 10, color: Colors.grey),
                                  ),
                                  const SizedBox(height: 8),

                                  // Mode Dropdown
                                  DropdownButtonFormField<String>(
                                    value: _selectedMode,
                                    decoration: InputDecoration(
                                      labelText: "Select Mode",
                                      labelStyle: const TextStyle(fontSize: 12),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(5),
                                        borderSide: const BorderSide(
                                          color: kBorderGray,
                                          width: 1.0,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(5),
                                        borderSide: const BorderSide(
                                          color: kBorderGray,
                                          width: 1.0,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(5),
                                        borderSide: const BorderSide(
                                          color: offBlack,
                                          width: 0.8,
                                        ),
                                      ),
                                      isDense: true,
                                    ),
                                    items: _mode
                                        .map((mode) => DropdownMenuItem(
                                              value: mode,
                                              child: Text(
                                                mode,
                                                style: const TextStyle(fontSize: 12),
                                              ),
                                            ))
                                        .toList(),
                                    onChanged: (val) {
                                      dialogSetState(() {
                                        _selectedMode = val;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 8),

                                  // Participants Row
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _minParticipantsController,
                                          decoration: InputDecoration(
                                            labelText: "Min Participants",
                                            labelStyle: const TextStyle(fontSize: 12),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(5),
                                              borderSide: const BorderSide(
                                                color: kBorderGray,
                                                width: 1.0,
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(5),
                                              borderSide: const BorderSide(
                                                color: kBorderGray,
                                                width: 1.0,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(5),
                                              borderSide: const BorderSide(
                                                color: offBlack,
                                                width: 0.8,
                                              ),
                                            ),
                                            isDense: true,
                                          ),
                                          keyboardType: TextInputType.number,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextField(
                                          controller: _maxParticipantsController,
                                          decoration: InputDecoration(
                                            labelText: "Max Participants",
                                            labelStyle: const TextStyle(fontSize: 12),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(5),
                                              borderSide: const BorderSide(
                                                color: kBorderGray,
                                                width: 1.0,
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(5),
                                              borderSide: const BorderSide(
                                                color: kBorderGray,
                                                width: 1.0,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(5),
                                              borderSide: const BorderSide(
                                                color: offBlack,
                                                width: 0.8,
                                              ),
                                            ),
                                            isDense: true,
                                          ),
                                          keyboardType: TextInputType.number,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // Date Pickers Row
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            DateTime initial = DateTime.now();
                                            if (_startDate != null && _startDate!.isAfter(DateTime.now())) {
                                              initial = _startDate!;
                                            }
                                            final DateTime? picked = await showDatePicker(
                                              context: context,
                                              initialDate: initial,
                                              firstDate: DateTime.now(),
                                              lastDate: DateTime(2035),
                                            );
                                            if (picked != null) {
                                              dialogSetState(() {
                                                _startDate = picked;
                                                if (_endDate != null && _endDate!.isBefore(picked)) {
                                                  _endDate = null;
                                                }
                                              });
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: offBlack,
                                            foregroundColor: Colors.white,
                                            textStyle: const TextStyle(fontSize: 12),
                                          ),
                                          child: Text(
                                            _startDate == null
                                                ? "Pick Start Date"
                                                : "Start: ${_startDate!.toLocal().toString().split(' ')[0]}",
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            DateTime initial = DateTime.now();
                                            if (_startDate != null && _startDate!.isAfter(DateTime.now())) {
                                              initial = _startDate!;
                                            }
                                            final DateTime? picked = await showDatePicker(
                                              context: context,
                                              initialDate: initial,
                                              firstDate: DateTime.now(),
                                              lastDate: DateTime(2035),
                                            );
                                            if (picked != null) {
                                              dialogSetState(() {
                                                _endDate = picked;
                                              });
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: offBlack,
                                            foregroundColor: Colors.white,
                                            textStyle: const TextStyle(fontSize: 12),
                                          ),
                                          child: Text(
                                            _endDate == null
                                                ? "Pick End Date"
                                                : "End: ${_endDate!.toLocal().toString().split(' ')[0]}",
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),

                            // Middle Column: Submission Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "2. Submission Details",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: offBlack,
                                    ),
                                  ),
                                  const Divider(),
                                  const SizedBox(height: 4),

                                  // Prompt Field
                                  TextField(
                                    controller: _promptController,
                                    decoration: InputDecoration(
                                      labelText: "Prompt",
                                      labelStyle: const TextStyle(fontSize: 12),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(5),
                                        borderSide: const BorderSide(
                                          color: kBorderGray,
                                          width: 1.0,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(5),
                                        borderSide: const BorderSide(
                                          color: kBorderGray,
                                          width: 1.0,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(5),
                                        borderSide: const BorderSide(
                                          color: offBlack,
                                          width: 0.8,
                                        ),
                                      ),
                                      isDense: true,
                                    ),
                                    maxLines: 3,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  const SizedBox(height: 8),

                                  // Submission Options Field
                                  TextField(
                                    controller: _submissionOptionsController,
                                    decoration: InputDecoration(
                                      labelText: "Submission Options",
                                      labelStyle: const TextStyle(fontSize: 12),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(5),
                                        borderSide: const BorderSide(
                                          color: kBorderGray,
                                          width: 1.0,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(5),
                                        borderSide: const BorderSide(
                                          color: kBorderGray,
                                          width: 1.0,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(5),
                                        borderSide: const BorderSide(
                                          color: offBlack,
                                          width: 0.8,
                                        ),
                                      ),
                                      isDense: true,
                                    ),
                                    maxLines: 3,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  const SizedBox(height: 8),

                                  // Online/Hybrid Submission Instructions
                                  TextField(
                                    controller: _onlineSubmissionController,
                                    decoration: InputDecoration(
                                      labelText: "Online Submission Instructions",
                                      labelStyle: const TextStyle(fontSize: 12),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(5),
                                        borderSide: const BorderSide(
                                          color: kBorderGray,
                                          width: 1.0,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(5),
                                        borderSide: const BorderSide(
                                          color: kBorderGray,
                                          width: 1.0,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(5),
                                        borderSide: const BorderSide(
                                          color: offBlack,
                                          width: 0.8,
                                        ),
                                      ),
                                      isDense: true,
                                    ),
                                    maxLines: 2,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),

                            // Right Column: Template Guidelines
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Template Guidelines",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: offBlack,
                                    ),
                                  ),
                                  const Divider(),
                                  const SizedBox(height: 8),
                                  if (_selectedType != null &&
                                      _challengeTemplates.containsKey(_selectedType))
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Text(
                                        "About the Challenge: " +
                                            _challengeTemplates[_selectedType]!["about"]! +
                                            "\n\nGroup Size: " +
                                            _challengeTemplates[_selectedType]!["groupSize"]! +
                                            "\nObjective: " +
                                            _challengeTemplates[_selectedType]!["objective"]! +
                                            "\n\nPrompt:\n" +
                                            _challengeTemplates[_selectedType]!["prompt"]! +
                                            "\n\nSubmission:\n" +
                                            _challengeTemplates[_selectedType]!["submission"]! +
                                            "\n\nOnline Alternatives:\n" +
                                            _challengeTemplates[_selectedType]!["online"]!,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    )
                                  else
                                    const Text(
                                      "Select a challenge type to view template guidelines.",
                                      style: TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Buttons Row: Cancel and Create/Update
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  // Clear the fields
                                      _clearChallengeFields();
                                      // Optionally update the UI by calling dialogSetState if needed.
                                      dialogSetState(() {});
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: offBlack,
                                  side: const BorderSide(color: offBlack),
                                  textStyle: const TextStyle(fontSize: 13),
                                ),
                                child: const Text("Clear"),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  // Validate fields
                                  if (_titleController.text.isEmpty ||
                                      _aboutController.text.isEmpty ||
                                      _promptController.text.isEmpty ||
                                      _submissionOptionsController.text.isEmpty ||
                                      _onlineSubmissionController.text.isEmpty ||
                                      _selectedMode == null ||
                                      _selectedType == null ||
                                      _startDate == null ||
                                      _endDate == null ||
                                      _minParticipantsController.text.isEmpty ||
                                      _maxParticipantsController.text.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Please fill all fields")),
                                    );
                                    return;
                                  }

                                  // Build challenge data
                                  final base64Image = _challengeImageBytes != null
                                      ? base64Encode(_challengeImageBytes!)
                                      : "";
                                  final additionalImagesBase64 = _additionalChallengeImages
                                      .map((img) => base64Encode(img))
                                      .toList();

                                  final challengeData = {
                                    'title': _titleController.text,
                                    'about': _aboutController.text,
                                    'prompt': _promptController.text,
                                    'submission_options': _submissionOptionsController.text,
                                    'online_submission_notice': _onlineSubmissionController.text,
                                    'mode': _selectedMode,
                                    'type': _selectedType,
                                    'start_date': Timestamp.fromDate(_startDate!),
                                    'end_date': Timestamp.fromDate(_endDate!),
                                    'image': base64Image,
                                    'additional_images': additionalImagesBase64,
                                    'min_participants': int.tryParse(_minParticipantsController.text) ?? 0,
                                    'max_participants': int.tryParse(_maxParticipantsController.text) ?? 0,
                                    'participants': 0,
                                  };

                                  try {
                                    if (challengeDoc == null) {
                                      await challenges.add(challengeData);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Challenge created successfully!")),
                                      );
                                    } else {
                                      await challenges.doc(challengeDoc.id).update(challengeData);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Challenge updated successfully!")),
                                      );
                                    }
                                    _clearChallengeFields();
                                    Navigator.of(context).pop();
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("Error: $e")),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: offBlack,
                                  foregroundColor: Colors.white,
                                  textStyle: const TextStyle(fontSize: 13),
                                ),
                                child: Text(challengeDoc == null ? "Create" : "Update"),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}


  // ---------------- Delete Challenge ----------------
  Future<void> _deleteChallenge(String id) async {
    WriteBatch batch = FirebaseFirestore.instance.batch();
    DocumentReference challengeRef =
        FirebaseFirestore.instance.collection('challenges').doc(id);
    batch.delete(challengeRef);

    QuerySnapshot submissionSnapshot = await FirebaseFirestore.instance
        .collection('user_submissions')
        .where('challengeDocId', isEqualTo: id)
        .get();
    for (DocumentSnapshot doc in submissionSnapshot.docs) {
      batch.delete(doc.reference);
    }

    QuerySnapshot groupSnapshot = await FirebaseFirestore.instance
        .collection('groups')
        .where('challengeID', isEqualTo: id)
        .get();
    for (DocumentSnapshot doc in groupSnapshot.docs) {
      batch.delete(doc.reference);
    }

    QuerySnapshot votesSnapshot = await FirebaseFirestore.instance
        .collection('group_votes')
        .where('challenge_id', isEqualTo: id)
        .get();
    for (DocumentSnapshot doc in votesSnapshot.docs) {
      batch.delete(doc.reference);
    }

    QuerySnapshot joinedSnapshot = await FirebaseFirestore.instance
        .collection('joined_challenges')
        .where('challenge_id', isEqualTo: id)
        .get();
    for (DocumentSnapshot doc in joinedSnapshot.docs) {
      batch.delete(doc.reference);
    }

    try {
      await batch.commit();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Challenge and related data deleted successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting challenge: $e")),
      );
    }
  }

  // Then define a helper method for the confirmation dialog:
void _confirmDeleteChallenge(String challengeId) {
  showDialog(
    context: context,
    builder: (BuildContext ctx) {
      return AlertDialog(
        title: const Text("Confirm Deletion"),
        content: const Text("Are you sure you want to delete this challenge and all its data?"),
        actions: [
          TextButton(
            onPressed: () {
              // Close the dialog
              Navigator.of(ctx).pop();
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            onPressed: () async {
              // User confirmed deletion
              Navigator.of(ctx).pop(); // Close the dialog first
              await _deleteChallenge(challengeId);
            },
            child: const Text("Delete"),
          ),
        ],
      );
    },
  );
}



  Widget _buildChallengeSection({
    required String sectionTitle,
    required List<DocumentSnapshot> challenges,
    required Color chipColor,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xfff9f9f9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          Text(
            "${sectionTitle} [${challenges.length}]",
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // List of challenges in this section
          for (var doc in challenges) _buildChallengeListItem(doc),
        ],
      ),
    );
  }

  Widget _buildChallengeListItem(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final title = data['title'] ?? "";
    final mode = data['mode'] ?? "";
    final minParticipants = data['min_participants'] ?? 0;
    final maxParticipants = data['max_participants'] ?? 0;

    // Same image logic as in _buildChallengeCard
    Widget imageWidget = Container(
      height: 40,
      width: 40,
      color: Colors.grey[300],
      child: const Icon(Icons.image, color: Colors.white),
    );
    final base64Img = data['image'] as String?;
    if (base64Img != null && base64Img.isNotEmpty) {
      try {
        final bytes = base64Decode(base64Img);
        imageWidget = ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(bytes, height: 40, width: 40, fit: BoxFit.cover),
        );
      } catch (_) {}
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
             opaque: false,               
            barrierDismissible: true,     
            barrierColor: Colors.black26, 
            pageBuilder: (context, animation, secondaryAnimation) {
              return ChallengeDetailsSlideIn(doc: doc);
            },
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;

              // Must be Tween<Offset> for SlideTransition
              final tween = Tween<Offset>(
                begin: begin,
                end: end,
              ).chain(CurveTween(curve: Curves.easeInOut));

              return SlideTransition(
                position: animation.drive(tween),
                child: child,
              );
            },
          ),
        );

        /*
        setState(() {
          _selectedChallengeDoc = doc; // So you can show details when tapped
        });*/
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 4, spreadRadius: 1),
          ],
        ),
        child: Row(
          children: [
            imageWidget,
            const SizedBox(width: 12),
            // Title & mode & participants
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: darkCharcoal
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text("Mode: $mode", style: 
                        TextStyle(
                          fontSize: 10,
                          color: offBlack,
                        )),
                  if (minParticipants > 0 || maxParticipants > 0)
                    Text(
                      "Min: $minParticipants | Max: $maxParticipants",
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
            ),
            // Edit & Delete icons
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blueGrey),
              onPressed: () => _addOrUpdateChallenge(challengeDoc: doc),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () => _confirmDeleteChallenge(doc.id),
            ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start, // Align text to the left
          children: [
            const SizedBox(height: 12),
            Text(
              "Challenge Management",
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.bold, color: offBlack),
            ),
            const SizedBox(height: 4),
            Text(
              "Manage or Create challenges here.",
              style: TextStyle(
                fontSize: 12,
                color: kSubText,
              ),
            ),
          ],
        ),
        centerTitle:
            false, // Optional: ensures left alignment on some platforms
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: offBlack,
        onPressed: () => _addOrUpdateChallenge(),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: challenges.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No challenges found"));
          }

          final endedChallenges = <DocumentSnapshot>[];
          final ongoingChallenges = <DocumentSnapshot>[];
          final comingUpChallenges = <DocumentSnapshot>[];
          final now = DateTime.now();
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final startTs = data['start_date'] as Timestamp?;
            final endTs = data['end_date'] as Timestamp?;
            final startDate = startTs?.toDate();
            final endDate = endTs?.toDate();
            if (startDate == null || endDate == null) {
              ongoingChallenges.add(doc);
              continue;
            }
            if (endDate.isBefore(now)) {
              endedChallenges.add(doc);
            } else if (startDate.isAfter(now)) {
              comingUpChallenges.add(doc);
            } else {
              ongoingChallenges.add(doc);
            }
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Upcoming section
                        _buildChallengeSection(
                          sectionTitle: "Coming Up",
                          challenges: comingUpChallenges,
                          chipColor:
                              Colors.purple, // or whatever color you prefer
                        ),
                        // Ongoing section
                        _buildChallengeSection(
                          sectionTitle: "In Progress",
                          challenges: ongoingChallenges,
                          chipColor: Colors.orange,
                        ),
                        // Ended section
                        _buildChallengeSection(
                          sectionTitle: "Ended",
                          challenges: endedChallenges,
                          chipColor: Colors.green,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

}
class ChallengeDetailsSlideIn extends StatelessWidget {
  final DocumentSnapshot doc;

  const ChallengeDetailsSlideIn({Key? key, required this.doc}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;

    // Extract challenge info
    final String challengeId = doc.id;
    final String title = data['title'] ?? "Untitled Challenge";
    final String about = data['about'] ?? "";
    final String mode = data['mode'] ?? "";
    final String type = data['type'] ?? "";
    final int minParticipants = data['min_participants'] ?? 0;
    final int maxParticipants = data['max_participants'] ?? 0;

    // Dates
    final Timestamp? tsStart = data['start_date'];
    final Timestamp? tsEnd = data['end_date'];
    final DateTime? startDate = tsStart?.toDate();
    final DateTime? endDate = tsEnd?.toDate();

    // Images
    final String? base64Img = data['image'];
    Uint8List? mainImageBytes;
    if (base64Img != null && base64Img.isNotEmpty) {
      try {
        mainImageBytes = base64Decode(base64Img);
      } catch (_) {}
    }
    // Additional images
    final additionalImages = data['additional_images'] as List<dynamic>?;
    List<Uint8List> additionalImagesBytes = [];
    if (additionalImages != null && additionalImages.isNotEmpty) {
      for (var base64Str in additionalImages) {
        try {
          additionalImagesBytes.add(base64Decode(base64Str as String));
        } catch (_) {}
      }
    }

    // Submission Options
     final String? submissionPrompts = data['prompt'] ?? "";
    final String? submissionOptions = data['submission_options'] ?? "";
    final String? onlineSubmissionNotice = data['online_submission_notice'] ?? "";

    final screenWidth = MediaQuery.of(context).size.width;

    // If screen < 600 px, panel = 90% of screen
    // Otherwise, panel = 40% of screen
    double panelWidth;
    if (screenWidth < 600) {
      panelWidth = screenWidth * 0.9;
    } else {
      panelWidth = screenWidth * 0.4;
    }

    return Material(
      color: Colors.transparent,  // Let the background show
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          // This is where you control how wide the panel is.
          width: panelWidth, // 1/3 of screen
          height: double.infinity, // full height
          color: Colors.transparent,     // the panel’s background
        child: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              // For a card-like effect:
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Challenge Title + Close Button
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start ,
                        children: [
                            Text(
                              "Challenges",
                              style: const TextStyle(
                                fontSize: 10,
                                color: kSubText,
                              ),
                            ),
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                      )
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Row of images (main + additional) in one line
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      if (mainImageBytes != null)
                        _buildSmallImage(mainImageBytes),
                      ...additionalImagesBytes.map((imgBytes) {
                        return _buildSmallImage(imgBytes);
                      }).toList(),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Mode & Type (instead of "High Priority" & date)
                Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Color(0xffffbfc3).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Color(0xff361e1e),
                        size: 15,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        mode,
                        style: const TextStyle(
                          fontFamily: 'Karla',
                          fontSize: 10,
                          color: Color(0xff361e1e),
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
                    color: Color(0xffc7c3ed).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.videogame_asset,
                        color: Color(0xFF575467),
                        size: 15,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        type,
                        style: const TextStyle(
                          fontFamily: 'Karla',
                          fontSize: 10,
                          color: Color(0xFF575467),
                        ),
                      ),
                    ],
                  ),
                ),
              ]
                ),

                const SizedBox(height: 16),

                // Challenge Period (instead of time spent)
                // Example: "StartDate --- EndDate"
                if (startDate != null && endDate != null) 
                  _buildDateRangeBar(startDate, endDate),

                const SizedBox(height: 16),

                // "Challenge Details" (instead of Description)
                Text(
                  "Challenge Details",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  about,
                  style: TextStyle(fontSize: 10, color: Colors.grey[700]),
                ),

                const SizedBox(height: 16),

                // Submission Options & Online Submission Notice (instead of Attachments)
                if (submissionPrompts!= null && submissionPrompts.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Submission Requirements",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        submissionPrompts,
                        style: TextStyle(fontSize: 10, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                if (submissionOptions != null && submissionOptions.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Submission Suggestions",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                         submissionOptions,
                        style: TextStyle(fontSize: 10, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                if (onlineSubmissionNotice != null &&
                    onlineSubmissionNotice.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        onlineSubmissionNotice,
                        style: TextStyle(fontSize: 10, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),

                // Leaderboard (instead of Comments/Updates)
                Text(
                  "Leaderboard",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                // Call your existing leaderboard widget here:
                _buildLeaderboard(challengeId),

                const SizedBox(height: 16),

                // "View Submissions" Button (instead of "Add a comment")
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to Submissions Screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AdminSubmissionsScreen(challengeId: challengeId),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: lightGray,
                      backgroundColor: offBlack,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Text("View Submissions"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
        ),
      ),
    );
  }

  // Helper widget for building small images in a row
  Widget _buildSmallImage(Uint8List bytes) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(6),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.memory(
          bytes,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  // Helper widget for a "Start --- End" date bar
  Widget _buildDateRangeBar(DateTime start, DateTime end) {
    final startStr = "${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}";
    final endStr = "${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}";

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFecdbe1), Color(0xFFe6def5)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        borderRadius: BorderRadius.circular(6),
        
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            startStr,
            style: TextStyle(fontSize: 12, color: offBlack, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Center(
              child: Container(
                height: 1,
                width: double.infinity,
                color: offBlack,
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ),
          Text(
            endStr,
            style: TextStyle(fontSize: 12, color: offBlack, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // ---------------- Build Leaderboard Modal ------------------
  Widget _buildLeaderboard(String challengeId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('groups')
          .where('challengeID', isEqualTo: challengeId)
          .where('status', isEqualTo: 'approved')
          .orderBy('approvedAt', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Text("Error loading leaderboard", style: TextStyle(fontSize: 10));
        }
        final groups = snapshot.data!.docs;
        if (groups.isEmpty) {
          return const Text("No groups available for leaderboard.", style: TextStyle(fontSize: 10));
        }
        return Card(
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 10),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final groupData =
                        groups[index].data() as Map<String, dynamic>;
                    final groupName =
                        groupData['groupName'] ?? "Group ${index + 1}";
                    final approvedTimestamp =
                        groupData['approvedAt'] as Timestamp?;
                    final approvedDate = approvedTimestamp != null
                        ? approvedTimestamp.toDate()
                        : null;
                    Color? bgColor;
                    if (index == 0) {
                      bgColor = Colors.amber[300];
                    } else if (index == 1) {
                      bgColor = Colors.grey[300];
                    } else if (index == 2) {
                      bgColor = Colors.brown[300];
                    }
                    else {
                      bgColor = Colors.transparent;
                    }
                    return Container(
                      color: bgColor,
                
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 4),
                      child: Row(
                        children: [
                          Text("${index + 1}.",
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          Expanded(child: Text(groupName)),
                          if (approvedDate != null)
                            Text(
                                approvedDate.toLocal().toString().split(' ')[0],
                                style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
