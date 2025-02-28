import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:heeey/mobile/screens/memory%20gallery/memory_gallery.dart';
import 'dart:convert';


// ----- COLOR & STYLE CONSTANTS (to match your screenshot style) -----
const Color kWhite         = Color(0xFFFFFFFF);
const Color kBlack         = Color(0xFF000000);
const Color kTableHeader   = Color(0xFFF6F6F6);  // Light gray for header row
const Color kBorderGray    = Color(0xFFE1E1E1);
const Color kTextColor     = Color(0xFF444444);
const Color kSubText       = Color(0xFF777777);

// Chip colors for Admin, User
const Color kChipGreenBg   = Color(0xFFedfdf4);
const Color kChipGreenText = Color(0xFF256a45);
const Color kChipGreenBgOutline = Color(0xFFacd2bc);

const Color kChipBlueBg    = Color(0xFFeef7ff);
const Color kChipBlueText  = Color(0xFF4775a6);
const Color kChipBlueBgOutline = Color(0xFFc9def0);


// Minimal email & password regex
final RegExp _emailRegex    = RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$');
// Updated password regex: 8+ chars, at least one uppercase, one digit, and one special character
final RegExp _passwordRegex = RegExp(r"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$");

class AdminUserManagementPage extends StatefulWidget {
  const AdminUserManagementPage({Key? key}) : super(key: key);

  @override
  State<AdminUserManagementPage> createState() => _AdminUserManagementPageState();
}

class _AdminUserManagementPageState extends State<AdminUserManagementPage> {
  // ========== Searching & Selection ==========
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedUserIds = {};

  // ========== CREATE & IMPORT FIELDS ==========
  final TextEditingController _createNameController       = TextEditingController();
  final TextEditingController _createEmailController      = TextEditingController();
  final TextEditingController _createPasswordController   = TextEditingController();
  final TextEditingController _createStartYearController  = TextEditingController();
  final TextEditingController _createGradYearController   = TextEditingController();

  String? _createSelectedMasterCourse;
  String? _emailErrorCreate;
  String? _passwordErrorCreate;

  // Example master courses
  final List<String> _masterCourses = [
    'MSc in Communications Engineering',
    'MSc in Computer Control & Automation',
    'MSc in Electronics',
    'MSc in Power Engineering',
    'MSc in Signal Processing and Machine Learning',
    'NIL'
  ];

  // ========== FILTER / SORT STATE ==========
  String _filterRole = 'All';       // filter by user role or "All"
  String _sortField  = 'none';      // can be "gradYearAsc", "startYearAsc", "courseAlpha"

  // Pagination
  int _currentPage    = 1;
  final int _pageSize = 50;

  @override
  void initState() {
    super.initState();
    // Real‐time validation for create form
    _createEmailController.addListener(_validateCreateEmail);
    _createPasswordController.addListener(_validateCreatePassword);
    _createSelectedMasterCourse = _masterCourses.first;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _createNameController.dispose();
    _createEmailController.dispose();
    _createPasswordController.dispose();
    _createStartYearController.dispose();
    _createGradYearController.dispose();
    super.dispose();
  }

  void _validateCreateEmail() {
    final email = _createEmailController.text.trim();
    if (email.isEmpty) {
      _emailErrorCreate = null;
    } else if (!_emailRegex.hasMatch(email)) {
      _emailErrorCreate = "Invalid email format";
    } else {
      _emailErrorCreate = null;
    }
    setState(() {});
  }

  void _validateCreatePassword() {
    final pass = _createPasswordController.text;
    if (pass.isEmpty) {
      _passwordErrorCreate = null;
    } else if (!_passwordRegex.hasMatch(pass)) {
      _passwordErrorCreate =  "Your password needs to:\n"
         "• include both lower and upper case characters\n"
         "• include at least one number or symbol\n"
         "• be at least 8 characters long";
    } else {
      _passwordErrorCreate = null;
    }
    setState(() {});
  }


  // ================= MAIN BUILD =================
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeaderArea(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildUserStream(isMobile: isMobile),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= HEADER AREA =================
  Widget _buildHeaderArea() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "User Management",
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: offBlack),
          ),
          const SizedBox(height: 4),
          const Text(
            "Manage or Create users here.",
            style: TextStyle(fontSize: 13, color: kSubText),
          ),
          const SizedBox(height: 16),
          FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance.collection('users').get(),
            builder: (context, snap) {
              int total = 0;
              if (snap.hasData && snap.data != null) {
                total = snap.data!.docs.length;
              }
              return Text(
                "All users $total",
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kTextColor),
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(fontSize: 13),
                    onChanged: (_) => setState(() => _currentPage = 1),
                    decoration: InputDecoration(
                      hintText: "Search",
                      hintStyle: const TextStyle(fontSize: 13, color: kSubText),
                      prefixIcon: const Icon(Icons.search, size: 18, color: kSubText),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: offBlack.withOpacity(0.5)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: offBlack.withOpacity(0.5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: offBlack.withOpacity(0.5)),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _openFilterDialog,
                icon: const Icon(Icons.filter_list, size: 16),
                label: const Text("Filters", style: TextStyle(fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kTextColor,
                  side: BorderSide(color: offBlack.withOpacity(0.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _openAddUserModal,
                icon: const Icon(Icons.add, size: 16, color: lightGray,),
                label: const Text("Add User", style: TextStyle(fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: offBlack,
                  foregroundColor: kWhite,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_selectedUserIds.isNotEmpty) ...[
            ElevatedButton.icon(
              onPressed: _deleteSelectedUsers,
              icon: const Icon(Icons.delete, size: 14),
              label: Text(
                "Delete Selected (${_selectedUserIds.length})",
                style: const TextStyle(fontSize: 12),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: kWhite,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ================= USER LIST STREAM =================
  Widget _buildUserStream({required bool isMobile}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data!.docs;
        final searchLower = _searchController.text.trim().toLowerCase();
        var filteredDocs = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name  = (data['name'] ?? '').toString().toLowerCase();
          final email = (data['email'] ?? '').toString().toLowerCase();
          final role  = (data['role'] ?? 'user').toString().toLowerCase();
          bool matchesRole = (_filterRole == 'All') ? true : (role == _filterRole.toLowerCase());
          return (name.contains(searchLower) || email.contains(searchLower)) && matchesRole;
        }).toList();

        if (_sortField == 'gradYearAsc') {
          filteredDocs.sort((a, b) {
            final aY = int.tryParse((a.data() as Map)['graduationYear'] ?? '') ?? 0;
            final bY = int.tryParse((b.data() as Map)['graduationYear'] ?? '') ?? 0;
            return aY.compareTo(bY);
          });
        } else if (_sortField == 'startYearAsc') {
          filteredDocs.sort((a, b) {
            final aY = int.tryParse((a.data() as Map)['startYear'] ?? '') ?? 0;
            final bY = int.tryParse((b.data() as Map)['startYear'] ?? '') ?? 0;
            return aY.compareTo(bY);
          });
        } else if (_sortField == 'courseAlpha') {
          filteredDocs.sort((a, b) {
            final aC = (a.data() as Map)['mastercourse'] ?? '';
            final bC = (b.data() as Map)['mastercourse'] ?? '';
            return aC.toString().compareTo(bC.toString());
          });
        }

        final totalCount = filteredDocs.length;
        final totalPages = (totalCount / _pageSize).ceil();
        if (_currentPage > totalPages && totalPages != 0) {
          _currentPage = totalPages;
        }
        final startIndex = (_currentPage - 1) * _pageSize;
        final endIndex = (startIndex + _pageSize > totalCount) ? totalCount : startIndex + _pageSize;
        final pageDocs = filteredDocs.sublist(startIndex, endIndex);

        return Column(
          children: [
            Expanded(
              child: !isMobile
                  ? _buildDesktopTable(pageDocs)
                  : _buildMobileList(pageDocs),
            ),
            if (totalCount > _pageSize) _buildPagination(totalPages),
          ],
        );
      },
    );
  }

  // ================= DESKTOP TABLE =================
  Widget _buildDesktopTable(List<DocumentSnapshot> docs) {
  // Check if all docs on the current page are selected.
  final allSelected = docs.every((doc) => _selectedUserIds.contains(doc.id));

  return SingleChildScrollView(
    scrollDirection: Axis.vertical,
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Stack(
        children: [
          // Rounded, colored header background.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 42, // This should match your headingRowHeight.
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              child: Container(
                color: kTableHeader, // Your header background color.
              ),
            ),
          ),
          // The DataTable, with transparent header so our background is visible.
          DataTable(
            headingRowHeight: 42,
            dataRowHeight: 56,
            headingRowColor: MaterialStateProperty.all(Colors.transparent),
            columnSpacing: 24,
            columns: [
              DataColumn(
                label: Checkbox(
                  side: MaterialStateBorderSide.resolveWith(
                      (states) => const BorderSide(color: offBlack, width: 1.0)),
                  value: allSelected,
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        for (var doc in docs) {
                          _selectedUserIds.add(doc.id);
                        }
                      } else {
                        for (var doc in docs) {
                          _selectedUserIds.remove(doc.id);
                        }
                      }
                    });
                  },
                ),
              ),
              const DataColumn(
                label: Text("User",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              ),
              const DataColumn(
                label: Text("Master’s Course",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              ),
              const DataColumn(
                label: Text("Matriculation Year",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              ),
              const DataColumn(
                label: Text("Graduation Year",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              ),
              const DataColumn(
                label: Text("Access",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              ),
              const DataColumn(label: SizedBox(width: 24)),
            ],
            rows: docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final uid = doc.id;
              final name = data['name'] ?? '';
              final email = data['email'] ?? '';
              final master = data['mastercourse'] ?? '';
              final start = data['startYear'] ?? '';
              final grad = data['graduationYear'] ?? '';
              final roleOrAccess = data['access'] ?? [data['role'] ?? 'user'];
              final pic = data['profilePic'] ?? '';

              Widget avatar;
              if (pic.isNotEmpty) {
                avatar = CircleAvatar(
                  radius: 20,
                  backgroundImage: MemoryImage(base64Decode(pic)),
                );
              } else {
                avatar = CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey[300],
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(color: kWhite, fontSize: 13),
                  ),
                );
              }

              return DataRow(
                cells: [
                  DataCell(
                    Checkbox(
                      side: MaterialStateBorderSide.resolveWith(
                        (states) => const BorderSide(color: offBlack, width: 1.0),
                      ),
                      activeColor: offBlack,
                      value: _selectedUserIds.contains(uid),
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedUserIds.add(uid);
                          } else {
                            _selectedUserIds.remove(uid);
                          }
                        });
                      },
                    ),
                  ),
                  DataCell(
                    Row(
                      children: [
                        avatar,
                        const SizedBox(width: 8),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold)),
                            Text(email,
                                style: const TextStyle(
                                    fontSize: 12, color: kSubText)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  DataCell(Text(master, style: const TextStyle(fontSize: 13))),
                  DataCell(Text(start, style: const TextStyle(fontSize: 13))),
                  DataCell(Text(grad, style: const TextStyle(fontSize: 13))),
                  DataCell(_buildAccessChips(roleOrAccess)),
                  DataCell(_buildActionMenu(doc)),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    ),
  );
}

  // ================= MOBILE LIST =================
  Widget _buildMobileList(List<DocumentSnapshot> docs) {
    return ListView.separated(
      itemCount: docs.length,
      separatorBuilder: (_, __) => Divider(color: kBorderGray, height: 1),
      itemBuilder: (context, i) {
        final doc  = docs[i];
        final data = doc.data() as Map<String, dynamic>;
        final uid  = doc.id;
        final name = data['name'] ?? '';
        final email = data['email'] ?? '';
        final master = data['mastercourse'] ?? '';
        final start = data['startYear'] ?? '';
        final grad = data['graduationYear'] ?? '';
        final roleOrAccess = data['access'] ?? [data['role'] ?? 'user'];
        final pic = data['profilePic'] ?? '';

        Widget avatar;
        if (pic.isNotEmpty) {
          avatar = CircleAvatar(radius: 20, backgroundImage: MemoryImage(base64Decode(pic)));
        } else {
          avatar = CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey[300],
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(color: kWhite),
            ),
          );
        }

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          leading: Checkbox(
            value: _selectedUserIds.contains(uid),
            onChanged: (val) {
              setState(() {
                if (val == true) {
                  _selectedUserIds.add(uid);
                } else {
                  _selectedUserIds.remove(uid);
                }
              });
            },
          ),
          title: Row(
            children: [
              avatar,
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    Text(email, style: const TextStyle(fontSize: 12, color: kSubText)),
                  ],
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Master’s: $master", style: const TextStyle(fontSize: 12, color: kTextColor)),
              Text("Start: $start   Grad: $grad", style: const TextStyle(fontSize: 12, color: kTextColor)),
              const SizedBox(height: 4),
              _buildAccessChips(roleOrAccess),
            ],
          ),
          trailing: _buildActionMenu(doc),
        );
      },
    );
  }

  // ================= ACCESS CHIPS =================
  Widget _buildAccessChips(List<dynamic> accessList) {
    final uniqueAccess = accessList
        .map((e) => e.toString().trim().toLowerCase())
        .toSet()
        .toList();

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: uniqueAccess.map((text) {
        if (text == 'admin') {
          return _oneChip("Admin", kChipGreenBg, kChipGreenText, kChipGreenBgOutline );
        } else if (text == 'user') {
          return _oneChip("User", Colors.blue.shade50, kChipBlueText, kChipBlueBgOutline);
        } else {
          return _oneChip(text, Colors.grey[200]!, kTextColor, offBlack);
        }
      }).toList(),
    );
  }

Widget _oneChip(String label, Color bg, Color tx, Color bgoutline) {
  return Material(
    color: bg,
    shape: StadiumBorder(
      side: BorderSide(color: bgoutline),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: tx),
      ),
    ),
  );
}

  // ================= ACTION MENU (3-dot) =================
  Widget _buildActionMenu(DocumentSnapshot doc) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: kSubText, size: 20),
      onSelected: (value) {
        switch (value) {
          case 'view': _viewProfile(doc); break;
          case 'edit': _openEditUserModal(doc); break;
          case 'permission': _changePermission(doc); break;
          case 'delete': _deleteUser(doc.id); break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'view',
          child: Row(
            children: const [
              Icon(Icons.person_outline, size: 18),
              SizedBox(width: 6),
              Text("View profile", style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: const [
              Icon(Icons.edit_outlined, size: 18),
              SizedBox(width: 6),
              Text("Edit details", style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'permission',
          child: Row(
            children: const [
              Icon(Icons.lock_open, size: 18),
              SizedBox(width: 6),
              Text("Change permission", style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: const [
              Icon(Icons.delete_outline, color: Colors.red, size: 18),
              SizedBox(width: 6),
              Text("Delete user", style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }

  // =============== VIEW PROFILE ===============
  void _viewProfile(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final name = data['name'] ?? '';
    final email = data['email'] ?? '';
    final master = data['mastercourse'] ?? '';
    final start = data['startYear'] ?? '';
    final grad = data['graduationYear'] ?? '';
    final pic = data['profilePic'] ?? '';
    final roleList = data['access'] ?? [data['role'] ?? 'user'];

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: pic.isNotEmpty ? MemoryImage(base64Decode(pic)) : null,
                  child: pic.isEmpty ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?') : null,
                ),
                const SizedBox(height: 12),
                Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(email, style: const TextStyle(fontSize: 13, color: kSubText)),
                const SizedBox(height: 12),
                _profileRow("Master’s Course", Text(master, style: const TextStyle(fontSize: 13))),
                _profileRow("Matriculation Year", Text(start, style: const TextStyle(fontSize: 13))),
                _profileRow("Graduation Year", Text(grad, style: const TextStyle(fontSize: 13))),
                _profileRow("Access", _buildAccessChips(roleList)),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.bottomRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Close", style: TextStyle(fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _profileRow(String label, Widget child) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text("$label:", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
          Expanded(child: child),
        ],
      ),
    );
  }

  // =============== EDIT USER ===============
  void _openEditUserModal(DocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>;
  final nameC  = TextEditingController(text: data['name'] ?? '');
  final emailC = TextEditingController(text: data['email'] ?? '');
  final startC = TextEditingController(text: data['startYear'] ?? '');
  final gradC  = TextEditingController(text: data['graduationYear'] ?? '');
  final master = data['mastercourse'] ?? _masterCourses.first;
  String? selectedMaster = master;

  // Create a form key for validation
  final GlobalKey<FormState> _editFormKey = GlobalKey<FormState>();

  showDialog(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (ctx, ms) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          child: Container(
            width: 420,
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Form(
                key: _editFormKey,
                autovalidateMode: AutovalidateMode.always,
                child: Column(
                  children: [
                    // Header title
                    const Text(
                      "Edit User Profile",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    // Large centered profile picture
                    Center(
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: (data['profilePic'] ?? '').isNotEmpty
                            ? MemoryImage(base64Decode(data['profilePic']))
                            : null,
                        child: (data['profilePic'] ?? '').isEmpty
                            ? Text(
                                (data['name'] ?? '').isNotEmpty
                                    ? data['name'][0].toUpperCase()
                                    : '?',
                                style: const TextStyle(fontSize: 24, color: kWhite),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Form fields
                    Row(
                      children: [
                        Expanded(child: _editField("Name", nameC)),
                        const SizedBox(width: 8),
                        Expanded(child: _editFieldWithValidation("Email", emailC, false)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedMaster,
                      style: const TextStyle(fontSize: 12),
                      items: _masterCourses.map((mc) {
                        return DropdownMenuItem(
                          value: mc,
                          child: Text(
                            mc,
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) => ms(() => selectedMaster = val),
                      decoration: InputDecoration(
                        labelText: "Master’s course",
                        labelStyle: const TextStyle(fontSize: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                          borderSide: const BorderSide(color: kBorderGray),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                          borderSide: const BorderSide(color: kBorderGray),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                          borderSide: const BorderSide(color: offBlack),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _pickModalYear(startC, ms),
                            child: AbsorbPointer(child: _editField("Matriculation Year", startC)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _pickModalYear(gradC, ms),
                            child: AbsorbPointer(child: _editField("Graduation Year", gradC)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancel", style: TextStyle(fontSize: 13)),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () async {
                            // Validate the form first.
                            if (!_editFormKey.currentState!.validate()) {
                              // If validation fails, do not proceed.
                              return;
                            }
                            final nm = nameC.text.trim();
                            final em = emailC.text.trim(); 
                            final st = startC.text.trim();
                            final gr = gradC.text.trim();
                            if (nm.isEmpty || em.isEmpty || st.isEmpty || gr.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Please fill all fields.")),
                              );
                              return;
                            }
                            // Duplicate check for email change
                            if (em != (data['email'] ?? '')) {
                              final dup = await FirebaseFirestore.instance
                                  .collection('users')
                                  .where('email', isEqualTo: em)
                                  .get();
                              final others = dup.docs.where((d) => d.id != doc.id);
                              if (others.isNotEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Email already exists.")),
                                );
                                return;
                              }
                            }
                            await FirebaseFirestore.instance.collection('users').doc(doc.id).update({
                              'name': nm,
                              'email': em,
                              'mastercourse': selectedMaster,
                              'startYear': st,
                              'graduationYear': gr,
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("User updated.")),
                            );
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: offBlack,
                            foregroundColor: kWhite,
                            textStyle: const TextStyle(fontSize: 13),
                          ),
                          child: const Text("Update"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}



  Widget _editField(String label, TextEditingController c, {bool obscure = false}) {
  return TextField(
    controller: c,
    obscureText: obscure,
    style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: kBorderGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: kBorderGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: offBlack),
        ),
      ),
  );
}

Widget _editFieldWithValidation(String label, TextEditingController c, bool obscure) {
  return TextFormField(
    controller: c,
    readOnly: true,
    obscureText: obscure,
    autovalidateMode: AutovalidateMode.always,
    validator: (value) {
      if (label == "Email") {
        if (value != null && value.isNotEmpty && !_emailRegex.hasMatch(value)) {
          return "Invalid email format";
        }
      } else if (label == "Password") {
        if (value != null && value.isNotEmpty && !_passwordRegex.hasMatch(value)) {
          return "Your password needs to:\n"
                 "• include both lower and upper case characters\n"
                 "• include at least one number or symbol\n"
                 "• be at least 8 characters long";
        }
      }
      return null;
    },
    style: const TextStyle(fontSize: 12),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: const BorderSide(color: kBorderGray),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: const BorderSide(color: kBorderGray),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: const BorderSide(color: offBlack),
      ),
    ),
  );
}

 Widget _createField(String label, TextEditingController c, {bool obscure = false, String? errorText}) {
    return TextField(
      controller: c,
      obscureText: obscure,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12),
        errorText: errorText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: kBorderGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: kBorderGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: offBlack),
        ),
      ),
    );
  }


  // Real-time validation helper for Email and Password in the edit modal.
 Widget _createFieldWithValidation(String label, TextEditingController controller, {bool obscure = false}) {
  return TextFormField(
    controller: controller,
    obscureText: obscure,
    autovalidateMode: AutovalidateMode.always,
    validator: (value) {
      if (label == "Email") {
        if (value != null && value.isNotEmpty && !_emailRegex.hasMatch(value)) {
          return "Please enter a valid email address.";
        }
      } else if (label == "Password") {
       if (value != null && value.isNotEmpty && !_passwordRegex.hasMatch(value)) {
          return "Your password needs to:\n"
                "• include both lower and upper case characters\n"
                "• include at least one number and symbol\n"
                "• be at least 8 characters long";
}
      }
      return null;
    },
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: const BorderSide(color: kBorderGray),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: const BorderSide(color: kBorderGray),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: const BorderSide(color: offBlack),
      ),
    ),
     style: const TextStyle(fontSize: 12), // input text style
  );
}

  // ========== YEAR PICKER (EDIT MODAL) ==========
  Future<void> _pickModalYear(TextEditingController controller, void Function(VoidCallback) ms) async {
    final now = DateTime.now();
    int existing = int.tryParse(controller.text) ?? now.year;
    if (existing < 1970) existing = 1970;
    if (existing > 2100) existing = 2100;
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(existing, 1, 1),
      firstDate: DateTime(1970),
      lastDate: DateTime(2100),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      ms(() => controller.text = picked.year.toString());
    }
  }

  // ========== CHANGE PERMISSION ==========
  void _changePermission(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    final role = data['role'] ?? 'user';
    String newRole = role;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Change Permission", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: DropdownButtonFormField<String>(
          value: newRole,
          style: const TextStyle(fontSize: 12),
          items: const [
            DropdownMenuItem(value: 'user', child: Text("User")),
            DropdownMenuItem(value: 'admin', child: Text("Admin")),
          ],
          onChanged: (val) => newRole = val ?? 'user',
          decoration: InputDecoration(
          labelText: "Role",
          labelStyle: const TextStyle(fontSize: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: const BorderSide(color: kBorderGray),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: const BorderSide(color: kBorderGray),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: const BorderSide(color: offBlack),
          ),
        ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Save", selectionColor: offBlack,)),
        ],
      ),
    );
    if (confirm != true) return;
    await FirebaseFirestore.instance.collection('users').doc(doc.id).update({'role': newRole});
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Permission changed to $newRole.")));
  }

  // ========== ADD USER MODAL (CREATE & IMPORT) ==========
  void _openAddUserModal() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row: "New User" on left and Import Excel button on right
                Row(
                  children: [
                    const Text("Create New User", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _importExcelSheet,
                      icon: const Icon(Icons.upload_file, size: 14, color: lightGray),
                      label: const Text("Import Excel", style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(backgroundColor: darkCharcoal, foregroundColor: kWhite),
                    ),
                  ],
                ),
                Form(
                autovalidateMode: AutovalidateMode.always,
                child: Column(
                  children: [
                const SizedBox(height: 12),
               _createField("Name", _createNameController),
              const SizedBox(height: 12),
              _createFieldWithValidation("Email", _createEmailController),
              const SizedBox(height: 12),
              _createFieldWithValidation("Password",  _createPasswordController, obscure: true),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _createSelectedMasterCourse,
                  items: _masterCourses.map((mc) {
                    return DropdownMenuItem(value: mc, 
                    child: Text(
                      mc,
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis, // prevent overflow
                    ),);
                  }).toList(),
                  onChanged: (val) => setState(() => _createSelectedMasterCourse = val),
                  decoration: InputDecoration(
                    labelText: "Master’s course", 
                    labelStyle: TextStyle(fontSize: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide: const BorderSide(color: kBorderGray),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide: const BorderSide(color: kBorderGray),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide: const BorderSide(color: offBlack),
                    ),
                    ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _pickYear(_createStartYearController),
                        child: AbsorbPointer(
                          child: _createField("Matriculation Year", _createStartYearController),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _pickYear(_createGradYearController),
                        child: AbsorbPointer(
                          child: _createField("Graduations Year", _createGradYearController),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _cancelCreateForm,
                        style: OutlinedButton.styleFrom(foregroundColor: kTextColor),
                        child: const Text("Cancel", style: TextStyle(fontSize: 13)),
                      )
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _createUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: darkCharcoal,
                          foregroundColor: kWhite,
                          textStyle: const TextStyle(fontSize: 13),
                        ),
                        child: const Text("Create"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
              ]
        ),
      ),
        ),
      ),
    );
  }


  // ========== CREATE USER HANDLER ==========
  Future<void> _createUser() async {
    final name  = _createNameController.text.trim();
    final email = _createEmailController.text.trim();
    final pass  = _createPasswordController.text.trim();
    final start = _createStartYearController.text.trim();
    final grad  = _createGradYearController.text.trim();
    final master= _createSelectedMasterCourse;

    if (name.isEmpty || email.isEmpty || pass.isEmpty || start.isEmpty || grad.isEmpty || master == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields.")));
      return;
    }
    if (_emailErrorCreate != null || _passwordErrorCreate != null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fix errors first.")));
      return;
    }

    // Duplicate check based on email
    final existing = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: email).limit(1).get();
    if (existing.docs.isNotEmpty) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User already exists in DB.")));
      if (existing.docs.length == 1) {
        _openEditUserModal(existing.docs.first);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cannot open edit modal: duplicate user count is not exactly one.")));
      }
      return;
    }

    try {
      final userCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: pass);
      final uid = userCred.user!.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'name': name,
        'email': email,
        'mastercourse': master,
        'startYear': start,
        'graduationYear': grad,
        'role': 'user',
        'aboutme': '',
        'profilePic': '',
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User created successfully!")));
      _cancelCreateForm();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        Navigator.pop(context);
        final docCheck = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: email).limit(1).get();
        if (docCheck.docs.length == 1) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Email already in use. Opening edit...")));
          _openEditUserModal(docCheck.docs.first);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cannot open edit modal: duplicate user count is not exactly one.")));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.message}")));
      }
    }
  }

  void _cancelCreateForm() {
    _createNameController.clear();
    _createEmailController.clear();
    _createPasswordController.clear();
    _createStartYearController.clear();
    _createGradYearController.clear();
    _createSelectedMasterCourse = _masterCourses.first;
    setState(() {
      _emailErrorCreate = null;
      _passwordErrorCreate = null;
    });
    Navigator.pop(context);
  }

  // ========== PICK YEAR (CREATE) ==========
  Future<void> _pickYear(TextEditingController controller) async {
    final now = DateTime.now();
    int existingYear = int.tryParse(controller.text) ?? now.year;
    if (existingYear < 1970) existingYear = 1970;
    if (existingYear > 2100) existingYear = 2100;
    final initialDate = DateTime(existingYear, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1970),
      lastDate: DateTime(2100),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) setState(() => controller.text = picked.year.toString());
  }

  // ========== IMPORT EXCEL ==========
  Future<void> _importExcelSheet() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Import Excel", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: const Text("Importing will create multiple users. Proceed?", style: TextStyle(fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel", style: TextStyle(fontSize: 13))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: kBlack, foregroundColor: kWhite),
            child: const Text("Yes", style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        withData: true,
      );
      if (result == null) return;
      final fileBytes = result.files.first.bytes!;
      final excel = Excel.decodeBytes(fileBytes);
      if (excel.tables.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No sheets found in the Excel file.")));
        return;
      }
      final sheetName = excel.tables.keys.first;
      final sheet = excel.tables[sheetName];
      int createdCount = 0, invalidCount = 0;
      for (int i = 1; i < (sheet?.rows.length ?? 0); i++) {
        final row = sheet!.rows[i];
        if (row.isEmpty) continue;
        final name  = row[0]?.value?.toString() ?? '';
        final email = row.length > 1 ? row[1]?.value?.toString() ?? '' : '';
        final pass  = row.length > 2 ? row[2]?.value?.toString() ?? '' : '';
        final master = row.length > 3 ? row[3]?.value?.toString() ?? '' : '';
        final sYear = row.length > 4 ? row[4]?.value?.toString() ?? '' : '';
        final gYear= row.length > 5 ? row[5]?.value?.toString() ?? '' : '';
        if (name.isEmpty || email.isEmpty || pass.isEmpty || sYear.isEmpty || gYear.isEmpty || master.isEmpty) {
          invalidCount++;
          continue;
        }
        if (!_emailRegex.hasMatch(email) || !_passwordRegex.hasMatch(pass)) {
          invalidCount++;
          continue;
        }
        try {
          final userCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: pass);
          final uid = userCred.user!.uid;
          await FirebaseFirestore.instance.collection('users').doc(uid).set({
            'uid': uid,
            'name': name,
            'email': email,
            'password': pass,
            'startYear': sYear,
            'graduationYear': gYear,
            'mastercourse': master,
            'role': 'user',
            'profilePic': '',
            'aboutme': '',
          });
          createdCount++;
        } on FirebaseAuthException catch (e) {
           invalidCount++;
        } catch (err) {
          invalidCount++;
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Import complete: $createdCount successfully created, $invalidCount Accounts have already been registered.")),
      );
    } catch (e, st) {
      debugPrint("Import error: $e\n$st");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error importing Excel: $e")));
    }
  }

  // ========== DELETE SELECTED USERS ==========
  Future<void> _deleteSelectedUsers() async {
    if (_selectedUserIds.isEmpty) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Selected", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to delete ${_selectedUserIds.length} user(s)?", style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: kWhite),
            child: const Text("Delete", style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    for (final uid in _selectedUserIds) {
      await FirebaseFirestore.instance.collection('users').doc(uid).delete();
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${_selectedUserIds.length} user(s) deleted.")));
    _selectedUserIds.clear();
    setState(() {});
  }

  // ========== DELETE SINGLE USER ==========
  Future<void> _deleteUser(String uid) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete User", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to delete this user?", style: TextStyle(fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: kWhite),
            child: const Text("Delete", style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).delete();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User deleted.")));
    _selectedUserIds.remove(uid);
    setState(() {});
  }

  // ========== FILTER DIALOG ==========
  void _openFilterDialog() {
    showDialog(
      context: context,
      builder: (_) {
        String localRole = _filterRole;
        String localSort = _sortField;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: const Text("Filters", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: localRole,
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text("All",  style: const TextStyle(fontSize: 12),)),
                    DropdownMenuItem(value: 'admin', child: Text("Admin",  style: const TextStyle(fontSize: 12),)),
                    DropdownMenuItem(value: 'user', child: Text("User",  style: const TextStyle(fontSize: 12),)),
                  ],
                  onChanged: (val) => localRole = val ?? 'All',
                  decoration: InputDecoration(
                    labelText: "Filter by Role", 
                    labelStyle: TextStyle(fontSize: 12),
                    border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: const BorderSide(color: kBorderGray),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: const BorderSide(color: kBorderGray),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: const BorderSide(color: offBlack),
                  ),
                ),
               ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: localSort,
                  items: const [
                    DropdownMenuItem(value: 'none', child: Text("No Sort", style: TextStyle(fontSize:12, overflow:  TextOverflow.ellipsis))),
                    DropdownMenuItem(value: 'gradYearAsc', child: Text("Graduation Year (Ascending Order)", style: TextStyle(fontSize:12, overflow:  TextOverflow.ellipsis))),
                    DropdownMenuItem(value: 'startYearAsc', child: Text("Matriculation Year (Ascending Order)", style: TextStyle(fontSize:12, overflow: TextOverflow.ellipsis))),
                    DropdownMenuItem(value: 'courseAlpha', child: Text("Master’s Course (Alphabetical Order)", style: TextStyle(fontSize:12, overflow: TextOverflow.ellipsis))),
                  ],
                  onChanged: (val) => localSort = val ?? 'none',
                  decoration: InputDecoration(
                    labelText: "Sort By",
                    labelStyle: TextStyle(fontSize: 12),
                    border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: const BorderSide(color: kBorderGray),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide: const BorderSide(color: kBorderGray),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide: const BorderSide(color: offBlack),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(fontSize: 13))),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _filterRole = localRole;
                  _sortField  = localSort;
                  _currentPage = 1;
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: kBlack, foregroundColor: kWhite),
              child: const Text("Apply", style: TextStyle(fontSize: 13)),
            ),
          ],
        );
      },
    );
  }

  // ========== PAGINATION BAR ==========
  Widget _buildPagination(int totalPages) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text("Page $_currentPage of $totalPages", style: const TextStyle(fontSize: 13)),
          IconButton(
            onPressed: _currentPage < totalPages ? () => setState(() => _currentPage++) : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}
