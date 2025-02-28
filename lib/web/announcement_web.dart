import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:image/image.dart' as img;

// Example color constants (adjust as needed)
const Color offBlack    = Color(0xFF222222);
const Color kBorderGray = Color(0xFFE1E1E1);
const Color kWhite      = Color(0xFFFFFFFF);
const Color kSubText    = Color(0xFF777777);

// AnnouncementsPage: Allows admin to create, edit, view and delete announcements.
class AnnouncementsPage extends StatefulWidget {
  const AnnouncementsPage({Key? key}) : super(key: key);

  @override
  _AnnouncementsPageState createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends State<AnnouncementsPage> {
  final CollectionReference announcements =
      FirebaseFirestore.instance.collection('announcements');

  // Controllers for announcement fields
  final TextEditingController _titleController       = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  Uint8List? _announcementImageBytes;
  final List<Uint8List> _additionalAnnouncementImages = [];
  final ImagePicker _picker = ImagePicker();

  /// Custom InputDecoration for text fields.
  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 12),
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

Future<void> _deleteAnnouncement(String id) async {
  WriteBatch batch = FirebaseFirestore.instance.batch();
  DocumentReference announcementRef =
      FirebaseFirestore.instance.collection('announcements').doc(id);
  batch.delete(announcementRef);

  try {
    await batch.commit();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Announcement deleted successfully")),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error deleting announcement: $e")),
    );
  }
}

void _confirmDeleteAnnouncement(String announcementId) {
  showDialog(
    context: context,
    builder: (BuildContext ctx) {
      return AlertDialog(
        title: const Text("Confirm Deletion"),
        content: const Text("Are you sure you want to delete this announcement?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop(); // Close dialog
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop(); // Close dialog
              await _deleteAnnouncement(announcementId);
            },
            child: const Text("Delete"),
          ),
        ],
      );
    },
  );
}


  /// Clears all announcement form fields.
  void _clearAnnouncementFields() {
    _titleController.clear();
    _descriptionController.clear();
    setState(() {
      _announcementImageBytes = null;
      _additionalAnnouncementImages.clear();
      _startDate = null;
      _endDate = null;
    });
  }

  

  /// Create/Edit Announcement Form.
 Future<void> _addOrUpdateAnnouncement({DocumentSnapshot? announcementDoc}) async {
  if (announcementDoc != null) {
    final data = announcementDoc.data() as Map<String, dynamic>;
    _titleController.text = data['title'] ?? '';
    _descriptionController.text = data['description'] ?? '';
    final tsStart = data['start_date'] as Timestamp?;
    final tsEnd = data['end_date'] as Timestamp?;
    _startDate = tsStart?.toDate();
    _endDate = tsEnd?.toDate();
    final base64Img = data['image'] as String?;
    if (base64Img != null && base64Img.isNotEmpty) {
      try {
        _announcementImageBytes = base64Decode(base64Img);
      } catch (_) {}
    }
    _additionalAnnouncementImages.clear();
    final additionalImages = data['additional_images'] as List<dynamic>?;
    if (additionalImages != null) {
      for (var base64Str in additionalImages) {
        try {
          _additionalAnnouncementImages.add(base64Decode(base64Str as String));
        } catch (_) {}
      }
    }
  }

  await showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, dialogSetState) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
              child: Dialog(
                backgroundColor: kWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  children: [
                    // Main content
                    SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Header row with title and close icon
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    announcementDoc == null
                                        ? "Create Announcement"
                                        : "Edit Announcement",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: offBlack,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, color: offBlack),
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Period Row: Start and End Date buttons
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      DateTime initial = DateTime.now();
                                      if (_startDate != null && _startDate!.isAfter(DateTime.now())) {
                                        initial = _startDate!;
                                      }
                                      final DateTime? picked = await showDatePicker(
                                        context: context,
                                        initialDate: initial,
                                        firstDate: DateTime(2000),
                                        lastDate: DateTime(2100),
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
                                    icon: const Icon(Icons.date_range, size: 16, color: kWhite),
                                    label: Text(
                                      _startDate == null
                                          ? "Start Date"
                                          : DateFormat('yyyy-MM-dd').format(_startDate!),
                                      style: const TextStyle(fontSize: 12, color: kWhite),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: offBlack,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      DateTime initial = DateTime.now();
                                      if (_startDate != null && _startDate!.isAfter(DateTime.now())) {
                                        initial = _startDate!;
                                      }
                                      final DateTime? picked = await showDatePicker(
                                        context: context,
                                        initialDate: initial,
                                        firstDate: DateTime(2000),
                                        lastDate: DateTime(2100),
                                      );
                                      if (picked != null) {
                                        dialogSetState(() {
                                          _endDate = picked;
                                        });
                                      }
                                    },
                                    icon: const Icon(Icons.date_range, size: 16, color: kWhite),
                                    label: Text(
                                      _endDate == null
                                          ? "End Date"
                                          : DateFormat('yyyy-MM-dd').format(_endDate!),
                                      style: const TextStyle(fontSize: 12, color: kWhite),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: offBlack,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Title Field
                            TextField(
                              controller: _titleController,
                              decoration: _buildInputDecoration("Title"),
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 8),
                            // Description Field
                            TextField(
                              controller: _descriptionController,
                              decoration: _buildInputDecoration("Description"),
                              maxLines: 4,
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 16),
                            // Image Section: Main image and Additional Images in a Row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Main Image Picker
                                GestureDetector(
                                  onTap: () async {
                                    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                                    if (image != null) {
                                      if (kIsWeb) {
                                        final bytes = await image.readAsBytes();
                                        dialogSetState(() {
                                          _announcementImageBytes = bytes;
                                        });
                                      } else {
                                        File file = File(image.path);
                                        String compressedBase64 = await compressAndConvertToBase64(file);
                                        dialogSetState(() {
                                          _announcementImageBytes = base64Decode(compressedBase64);
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
                                    child: _announcementImageBytes != null
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(5),
                                            child: Image.memory(_announcementImageBytes!, fit: BoxFit.cover),
                                          )
                                        : const Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Additional Images Picker & Display in a row
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      TextButton.icon(
                                        onPressed: () async {
                                          final List<XFile>? images = await _picker.pickMultiImage();
                                          if (images != null && images.isNotEmpty) {
                                            for (var image in images) {
                                              if (kIsWeb) {
                                                final bytes = await image.readAsBytes();
                                                dialogSetState(() {
                                                  _additionalAnnouncementImages.add(bytes);
                                                });
                                              } else {
                                                File file = File(image.path);
                                                String compressedBase64 = await compressAdditionalImageStrict(file);
                                                dialogSetState(() {
                                                  _additionalAnnouncementImages.add(base64Decode(compressedBase64));
                                                });
                                              }
                                            }
                                          }
                                        },
                                        icon: const Icon(Icons.add, size: 16),
                                        label: const Text("Add Images", style: TextStyle(fontSize: 12)),
                                      ),
                                      if (_additionalAnnouncementImages.isNotEmpty)
                                        SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            children: List.generate(
                                              _additionalAnnouncementImages.length,
                                              (index) {
                                                final imageBytes = _additionalAnnouncementImages[index];
                                                return Stack(
                                                  children: [
                                                    Container(
                                                      width: 80,
                                                      height: 80,
                                                      margin: const EdgeInsets.only(right: 8),
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
                                                            _additionalAnnouncementImages.removeAt(index);
                                                          });
                                                        },
                                                        child: Container(
                                                          decoration: const BoxDecoration(
                                                            shape: BoxShape.circle,
                                                            color: Colors.red,
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
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Buttons Row: Clear and Create/Update
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      // Clear all announcement fields
                                      _clearAnnouncementFields();
                                      dialogSetState(() {}); // update UI if needed
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
                                      if (_titleController.text.isEmpty ||
                                          _descriptionController.text.isEmpty ||
                                          _startDate == null ||
                                          _endDate == null) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text("Please fill all fields")),
                                        );
                                        return;
                                      }
                                      if (_startDate != null && _endDate != null && _endDate!.isBefore(_startDate!)) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text("End Date cannot be earlier than Start Date")),
                                        );
                                        return;
                                      }

                                     final String base64Image;
                                    if (announcementDoc != null && _announcementImageBytes == null) {
                                      final data = announcementDoc.data() as Map<String, dynamic>;
                                      base64Image = data['image'] ?? "";
                                    } else {
                                      base64Image = _announcementImageBytes != null ? base64Encode(_announcementImageBytes!) : "";
                                    }


                                    
                                      final additionalImagesBase64 = _additionalAnnouncementImages
                                          .map((img) => base64Encode(img))
                                          .toList();
                                      final announcementData = {
                                        'title': _titleController.text,
                                        'description': _descriptionController.text,
                                        'start_date': Timestamp.fromDate(_startDate!),
                                        'end_date': Timestamp.fromDate(_endDate!),
                                        'image': base64Image,
                                        'additional_images': additionalImagesBase64,
                                      };
            

                                      try {
                                        if (announcementDoc == null) {
                                           print("Creating new announcement");
                                          await announcements.add(announcementData);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text("Announcement created successfully!")),
                                          );
                                        } else {
                                         print("Updating announcement: ${announcementDoc.id}");
                                         await FirebaseFirestore.instance.collection('announcements').doc(announcementDoc.id).update(announcementData);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text("Announcement updated successfully!")),
                                         );
                                        }
                                        _clearAnnouncementFields();
                                        Navigator.of(context).pop();
                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text("Error: $e")),
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: offBlack,
                                      foregroundColor: kWhite,
                                      textStyle: const TextStyle(fontSize: 13),
                                    ),
                                    child: Text(announcementDoc == null ? "Create" : "Update"),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ]
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }


  /// Helper widget for displaying small images in the announcement details.
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
        child: Image.memory(bytes, fit: BoxFit.cover),
      ),
    );
  }

  /// Helper widget for a "Start --- End" date bar.
  Widget _buildDateRangeBar(DateTime start, DateTime end) {
    final startStr = "${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}";
    final endStr = "${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}";
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
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

  Widget _buildAnnouncementListItem(DocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>;
  final String title = data['title'] ?? "";
  final Timestamp? tsStart = data['start_date'] as Timestamp?;
  final Timestamp? tsEnd = data['end_date'] as Timestamp?;
  final DateTime? startDate = tsStart?.toDate();
  final DateTime? endDate = tsEnd?.toDate();

  // Build a small image widget for the announcement.
  Widget imageWidget = Container(
    height: 40,
    width: 40,
    color: Colors.grey[300],
    child: const Icon(Icons.image, color: Colors.white),
  );
  final String? base64Img = data['image'] as String?;
  if (base64Img != null && base64Img.isNotEmpty) {
    try {
      final Uint8List bytes = base64Decode(base64Img);
      imageWidget = ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(bytes, height: 40, width: 40, fit: BoxFit.cover),
      );
    } catch (_) {}
  }

  // Format the period if both dates are available.
  String period = "";
  if (startDate != null && endDate != null) {
    period = "${DateFormat('yyyy-MM-dd').format(startDate)} - ${DateFormat('yyyy-MM-dd').format(endDate)}";
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
            return AnnouncementDetailsSlideIn(doc: doc);
          },
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            final tween = Tween<Offset>(begin: begin, end: end)
                .chain(CurveTween(curve: Curves.easeInOut));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        ),
      );
    },
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 4,horizontal: 10),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Announcement Title
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: offBlack,
                  ),
                ),
                const SizedBox(height: 4),
                // Period with Calendar Icon
                Row(
                  children: [
                    const Icon(Icons.date_range, size: 10, color: offBlack),
                    const SizedBox(width: 4),
                    Text(
                      period,
                      style: const TextStyle(fontSize: 10, color: kSubText),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Edit and Delete buttons
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blueGrey),
            onPressed: () => _addOrUpdateAnnouncement(announcementDoc: doc),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent),
            onPressed: () => _confirmDeleteAnnouncement(doc.id),
          ),
        ],
      ),
    ),
  );
}

Widget _buildAnnouncementSection({
    required String sectionTitle,
    required List<DocumentSnapshot> announcements,
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
            "${sectionTitle} [${announcements.length}]",
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // List of challenges in this section
          for (var doc in announcements) _buildAnnouncementListItem(doc),
        ],
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
              "Announcement Management",
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.bold, color: offBlack),
            ),
            const SizedBox(height: 4),
            Text(
              "Manage or Create announcements here.",
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
        onPressed: () => _addOrUpdateAnnouncement(),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: announcements.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No announcements found", style: TextStyle(fontSize: 14)));
          }
          
          final endedAnnouncements = <DocumentSnapshot>[];
          final ongoingAnnouncements = <DocumentSnapshot>[];
          final comingUpAnnouncements = <DocumentSnapshot>[];
          final now = DateTime.now();
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final startTs = data['start_date'] as Timestamp?;
            final endTs = data['end_date'] as Timestamp?;
            final startDate = startTs?.toDate();
            final endDate = endTs?.toDate();
            if (startDate == null || endDate == null) {
              ongoingAnnouncements.add(doc);
              continue;
            }
            if (endDate.isBefore(now)) {
              endedAnnouncements.add(doc);
            } else if (startDate.isAfter(now)) {
              comingUpAnnouncements.add(doc);
            } else {
              ongoingAnnouncements.add(doc);
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
                        _buildAnnouncementSection(
                          sectionTitle: "Coming Up",
                          announcements: comingUpAnnouncements,
                          chipColor:
                              Colors.purple, // or whatever color you prefer
                        ),
                        // Ongoing section
                        _buildAnnouncementSection(
                          sectionTitle: "In Progress",
                          announcements: ongoingAnnouncements,
                          chipColor: Colors.orange,
                        ),
                        // Ended section
                        _buildAnnouncementSection(
                          sectionTitle: "Ended",
                          announcements: endedAnnouncements,
                          chipColor: Colors.green,
                        ),
                      ],
                    ),
                  ),
                ),
              ]
           ),
           );

        },
      ),
    );
  }
}

// Detailed view for an announcement. Tapping an announcement card will slide in this view.
  class AnnouncementDetailsSlideIn extends StatelessWidget {
    final DocumentSnapshot doc;

    const AnnouncementDetailsSlideIn({Key? key, required this.doc}) : super(key: key);

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

    @override
    Widget build(BuildContext context) {
      final data = doc.data() as Map<String, dynamic>;
      final String title = data['title'] ?? "Untitled Announcement";
      final String description = data['description'] ?? "";
      final Timestamp? tsStart = data['start_date'];
      final Timestamp? tsEnd = data['end_date'];
      final DateTime? startDate = tsStart?.toDate();
      final DateTime? endDate = tsEnd?.toDate();
      final String? base64Img = data['image'];
      Uint8List? mainImageBytes;
      if (base64Img != null && base64Img.isNotEmpty) {
        try {
          mainImageBytes = base64Decode(base64Img);
        } catch (_) {}
      }
      final additionalImages = data['additional_images'] as List<dynamic>?;
      List<Uint8List> additionalImagesBytes = [];
      if (additionalImages != null && additionalImages.isNotEmpty) {
        for (var base64Str in additionalImages) {
          try {
            additionalImagesBytes.add(base64Decode(base64Str as String));
          } catch (_) {}
        }
      }
      final screenWidth = MediaQuery.of(context).size.width;
      double panelWidth = screenWidth < 600 ? screenWidth * 0.9 : screenWidth * 0.4;

      return Material(
        color: Colors.transparent,
        child: Align(
          alignment: Alignment.centerRight,
          child: Container(
            width: panelWidth,
            height: double.infinity,
            color: Colors.transparent,
            child: SafeArea(
              child: SingleChildScrollView(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kWhite,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Title and Close Button
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Announcement",
                                  style: const TextStyle(fontSize: 10, color: kSubText),
                                ),
                                Text(
                                  title,
                                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                // Challenge Period (instead of time spent)
                // Example: "StartDate --- EndDate"
                if (startDate != null && endDate != null) 
                  _buildDateRangeBar(startDate, endDate),

                const SizedBox(height: 16),

                      // Main Image and Additional Images Carousel
                      if (mainImageBytes != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(mainImageBytes, height: 150, width: double.infinity, fit: BoxFit.cover),
                        ),
                      const SizedBox(height: 8),
                      if (additionalImagesBytes.isNotEmpty)
                        SizedBox(
                          height: 80,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: additionalImagesBytes.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(additionalImagesBytes[index], height: 80, width: 80, fit: BoxFit.cover),
                                ),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 16),
                      if ( description!= null && description.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Description",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(fontSize: 10, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                    ]
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    
  }
