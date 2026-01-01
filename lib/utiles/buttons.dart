import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:the_read_thread/Controller/MemoryController.dart';
import 'package:the_read_thread/Controller/ShareMemory.dart';
import 'package:the_read_thread/Controller/ThreadController.dart';
import 'package:the_read_thread/Model/UserModel.dart';
import 'package:the_read_thread/Model/threadModel.dart';

class RedButtonContainer extends StatelessWidget {
  final String text;
  final bool isBold;
  final IconData? preIcon;
  final IconData? postIcon;
  final VoidCallback? onTap;

  const RedButtonContainer({
    Key? key,
    required this.text,
    this.isBold = false,
    this.preIcon,
    this.postIcon,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFAE1B25), // red color
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (preIcon != null) ...[
              Icon(preIcon, color: Colors.white),
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: TextStyle(
                color: Colors.white,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                fontSize: 16,
              ),
            ),
            if (postIcon != null) ...[
              const SizedBox(width: 8),
              Icon(postIcon, color: Colors.white),
            ],
          ],
        ),
      ),
    );
  }
}

Future<void> showCreateThreadDialog(
  BuildContext context,
  List<UserModel> friends,
) async {
  final titleController = TextEditingController();
  final descController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String priority = "High";
  DateTime? selectedDate;
  bool isShared = false;
  bool isLoading = false;
  List<String> selectedFriends = [];

  await showDialog(
    context: context,
    barrierDismissible: !isLoading,
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.85,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'weave_a_new_thread'.tr,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // TITLE
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'journey_title'.tr,
                        hintText: 'journey_title_hint'.tr,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // DESCRIPTION
                    TextField(
                      controller: descController,
                      decoration: InputDecoration(
                        labelText: 'description'.tr,
                        hintText: 'description_hint'.tr,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // DATE PICKER
                    Text('goal_date_optional'.tr),
                    InkWell(
                      onTap: isLoading
                          ? null
                          : () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2035),
                              );
                              if (picked != null) {
                                setState(() => selectedDate = picked);
                              }
                            },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              selectedDate == null
                                  ? 'pick_a_date'.tr
                                  : selectedDate!.toLocal().toString().split(
                                      " ",
                                    )[0],
                            ),
                            const Icon(Icons.calendar_today, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // PRIVACY SWITCH
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(isShared ? 'shared'.tr : 'private'.tr),
                        Switch(
                          value: isShared,
                          onChanged: isLoading
                              ? null
                              : (v) => setState(() => isShared = v),
                        ),
                      ],
                    ),

                    // FRIENDS SECTION
                    if (isShared) ...[
                      const SizedBox(height: 8),
                      Text(
                        'invite_friends'.tr,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Builder(
                        builder: (context) {
                          final visibleFriends = friends
                              .where(
                                (user) => user.id != _auth.currentUser!.uid,
                              )
                              .toList();

                          if (visibleFriends.isEmpty) {
                            return Text(
                              'no_friends_yet'.tr,
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            );
                          }

                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: visibleFriends.map((user) {
                              final isSelected = selectedFriends.contains(
                                user.id,
                              );

                              return ChoiceChip(
                                label: Text(user.name),
                                selected: isSelected,
                                onSelected: isLoading
                                    ? null
                                    : (_) {
                                        setState(() {
                                          if (isSelected) {
                                            selectedFriends.remove(user.id);
                                          } else {
                                            selectedFriends.add(user.id);
                                          }
                                        });
                                      },
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],

                    const SizedBox(height: 24),

                    // SUBMIT BUTTON
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFAE1B25),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      onPressed: isLoading
                          ? null
                          : () async {
                              setState(() => isLoading = true);

                              await ThreadController().addThread(
                                title: titleController.text.trim(),
                                description: descController.text.trim(),
                                priority: priority,
                                goalDate: selectedDate,
                                invitedMembers: selectedFriends,
                                isShared: isShared,
                              );

                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                            },
                      child: isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'weave_this_thread'.tr,
                              style: const TextStyle(color: Colors.white),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

void showAddActivityDialog({
  required BuildContext context,
  required Thread thread,
  required List<UserModel> myFriends, // Now using UserModel
  required String currentUserId,
  required String currentUserName,
  String? currentUserPhotoUrl,
}) {
  showDialog(
    context: context,
    builder: (context) => AddActivityDialog(
      thread: thread,
      myFriends: myFriends,
      currentUserId: currentUserId,
      currentUserName: currentUserName,
      currentUserPhotoUrl: currentUserPhotoUrl,
    ),
  );
}

class AddActivityDialog extends StatefulWidget {
  final Thread thread;
  final List<UserModel> myFriends;
  final String currentUserId;
  final String currentUserName;
  final String? currentUserPhotoUrl;

  const AddActivityDialog({
    Key? key,
    required this.thread,
    required this.myFriends,
    required this.currentUserId,
    required this.currentUserName,
    this.currentUserPhotoUrl,
  }) : super(key: key);

  @override
  State<AddActivityDialog> createState() => _AddActivityDialogState();
}

class _AddActivityDialogState extends State<AddActivityDialog> {
  bool isLoading = false;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  final FirebaseAuth auth = FirebaseAuth.instance;
  DateTime? selectedDate;

  String _selectedPriority = 'Medium';
  List<String> _selectedAssignees = [];

  late List<UserModel> threadMembers;

  @override
  void initState() {
    super.initState();

    // Filter friends who are actually in this thread (based on uid in thread.members)
    threadMembers = widget.myFriends
        .where((friend) => widget.thread.members.contains(friend.id))
        .toList();

    // Always assign to current user by default
    _selectedAssignees = [widget.currentUserId];
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Color(0xFFF9F7F5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'add_activity'.tr,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${'add_new_activity_to'.tr} ${widget.thread.name}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 20),

                // Activity Name
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'activity_name'.tr,
                    hintText: 'what_needs_to_be_done'.tr,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  validator: (v) =>
                      v?.trim().isEmpty ?? true ? 'required'.tr : null,
                ),

                const SizedBox(height: 16),

                // Notes
                TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: 'notes_optional'.tr,
                    hintText: 'add_any_details_or_notes'.tr,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  maxLines: 4,
                ),

                // Priority (no static text here)
                const SizedBox(height: 20),
                InkWell(
                  onTap: isLoading
                      ? null
                      : () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                          );
                          if (picked != null) {
                            setState(() => selectedDate = picked);
                          }
                        },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selectedDate == null
                              ? 'pick_a_date_optional'.tr
                              : selectedDate!.toLocal().toString().split(
                                  " ",
                                )[0],
                        ),
                        const Icon(Icons.calendar_today, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Assign To
                Text(
                  'assign_to_optional'.tr,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    // Current User - "You"
                    _buildAssigneeChip(
                      userId: widget.currentUserId,
                      displayName: 'you'.tr,
                      photoUrl: widget.currentUserPhotoUrl,
                      initials: widget.currentUserName.isNotEmpty
                          ? widget.currentUserName
                                .split(' ')
                                .map((e) => e[0])
                                .take(2)
                                .join()
                                .toUpperCase()
                          : 'me'.tr.toUpperCase(),
                      isSelected: true,
                    ),

                    // Other members in the thread
                    ...threadMembers
                        .where((user) => user.id != auth.currentUser!.uid)
                        .map(
                          (user) => _buildAssigneeChip(
                            userId: user.id,
                            displayName: user.name,
                            photoUrl: user.photoUrl,
                            initials: user.name.isNotEmpty
                                ? user.name
                                      .split(' ')
                                      .map((e) => e[0])
                                      .take(2)
                                      .join()
                                      .toUpperCase()
                                : '??',
                            isSelected: _selectedAssignees.contains(user.id),
                          ),
                        ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('cancel'.tr, style: TextStyle(color: Colors.grey[700])),
        ),
        ElevatedButton(
          onPressed: _submitActivity,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFAE1B25),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'add_activity'.tr,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildAssigneeChip({
    required String userId,
    required String displayName,
    required String? photoUrl,
    required String initials,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: userId == widget.currentUserId
          ? null
          : () {
              setState(() {
                if (isSelected) {
                  _selectedAssignees.remove(userId);
                } else {
                  _selectedAssignees.add(userId);
                }
              });
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFAE1B25) : Colors.grey[200],
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? const Color(0xFFAE1B25) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                  ? NetworkImage(photoUrl)
                  : null,
              backgroundColor: isSelected ? Colors.white : Color(0xFF293035),
              child: photoUrl == null || photoUrl.isEmpty
                  ? Text(
                      initials,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? const Color(0xFFAE1B25)
                            : Colors.white,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Text(
              displayName,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  final ThreadController _threadController = ThreadController();

  Future<void> _submitActivity() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await _threadController.addActivity(
        threadId: widget.thread.id,
        name: _nameController.text.trim(),
        activityDetails: _notesController.text.trim(),
        assignTo: _selectedAssignees,
        priority: _selectedPriority,
        selectedDate: selectedDate,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'activity_added_successfully'.tr,
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: const Color(0xFFAE1B25),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${'failed_to_add_activity'.tr}: $e',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: const Color(0xFFAE1B25),
          ),
        );
      }
    }
  }
}

class MemoryCaptureDialog extends StatefulWidget {
  final String threadId;
  final String activityId;
  final String activityName;

  const MemoryCaptureDialog({
    Key? key,
    required this.threadId,
    required this.activityId,
    required this.activityName,
  }) : super(key: key);

  @override
  State<MemoryCaptureDialog> createState() => _MemoryCaptureDialogState();
}

class _MemoryCaptureDialogState extends State<MemoryCaptureDialog> {
  final TextEditingController _memoryController = TextEditingController();
  final ThreadController _controller = ThreadController();
  final ImagePicker _picker = ImagePicker();

  List<File> _selectedImages = [];
  bool _isUploading = false;

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (photo != null) {
        setState(() {
          _selectedImages.add(File(photo.path));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${'error_accessing_camera'.tr}: $e')),
        );
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final List<XFile> photos = await _picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (photos.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(photos.map((photo) => File(photo.path)));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${'error_accessing_gallery'.tr}: $e')),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<List<String>> _uploadImagesToFirebase() async {
    List<String> downloadUrls = [];

    for (int i = 0; i < _selectedImages.length; i++) {
      try {
        final file = _selectedImages[i];
        final fileName =
            '${widget.threadId}_${widget.activityId}_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';

        final storageRef = FirebaseStorage.instance
            .ref()
            .child('memories')
            .child(widget.threadId)
            .child(fileName);

        final uploadTask = storageRef.putFile(file);
        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();
        downloadUrls.add(downloadUrl);
      } catch (e) {
        print("Error uploading image $i: $e");
      }
    }

    return downloadUrls;
  }

  Future<void> _saveMemory() async {
    setState(() {
      _isUploading = true;
    });

    try {
      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        imageUrls = await _uploadImagesToFirebase();
        print("We are getting these URLs:${imageUrls.toString()}");
      }

      final memoryText = _memoryController.text.trim();

      await _controller.addToMemory(
        threadId: widget.threadId,
        activityId: widget.activityId,
        memoryDetails: memoryText.isEmpty ? "No memory note added" : memoryText,
        imagesURL: imageUrls,
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${'error_saving_memory'.tr}: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Red Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFFAE1B25),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 36,
                        color: Color(0xFFAE1B25),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'thread_knotted'.tr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${'you_completed'.tr} "${widget.activityName}"',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Memory Note
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'add_a_memory_note'.tr,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _memoryController,
                decoration: InputDecoration(
                  hintStyle: const TextStyle(fontSize: 12),
                  hintText: 'memory_note_hint'.tr,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                maxLines: 4,
              ),

              const SizedBox(height: 20),

              // Capture the Moment
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'capture_the_moment'.tr,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isUploading ? null : _pickImageFromCamera,
                      icon: const Icon(
                        Icons.camera_alt,
                        color: Color(0xFFAE1B25),
                      ),
                      label: Text('take_photo'.tr),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFAE1B25),
                        side: const BorderSide(color: Color(0xFFAE1B25)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isUploading ? null : _pickImageFromGallery,
                      icon: const Icon(Icons.photo, color: Color(0xFFAE1B25)),
                      label: Text('upload_photo'.tr),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFAE1B25),
                        side: const BorderSide(color: Color(0xFFAE1B25)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Display selected images
              if (_selectedImages.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedImages.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _selectedImages[index],
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _removeImage(index),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFAE1B25),
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.check, color: Colors.green, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${_selectedImages.length} ${'photos_selected'.tr}',
                      style: const TextStyle(color: Colors.green),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 24),

              // Save Memory Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _saveMemory,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFAE1B25),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isUploading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'save_memory'.tr,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _memoryController.dispose();
    super.dispose();
  }
}

class MemoryDetailDialog extends StatelessWidget {
  final MemoryItem memory;
  const MemoryDetailDialog({Key? key, required this.memory}) : super(key: key);

  // -----------------------------------
  // 🔥 SHARE MEMORY WITH IMAGES
  // -----------------------------------
 Future<void> shareMemory() async {
  Get.dialog(
    const Center(child: CircularProgressIndicator(color: Color(0xFFAE1B25))),
    barrierDismissible: false,
  );

  try {
    // Format date
    final String date = memory.completedAt != null
        ? DateFormat('MMMM d, yyyy – h:mm a').format(memory.completedAt!)
        : "No date";

    // Fetch shared users
    final List<UserModel> users = await _fetchSharedUsers(memory.sharedWith);
    final String sharedNames = users.isNotEmpty
        ? users.map((e) => e.name).join(", ")
        : 'none'.tr;

    // Build message
    final StringBuffer message = StringBuffer();
    message.writeln('${'share_memory_intro'.tr}\n');
    message.writeln('${'memory_summary'.tr}\n');
    message.writeln("${'activity_label'.tr} ${memory.activityName}");
    message.writeln("${'thread_label'.tr} ${memory.threadName}");
    message.writeln("${'completed_on_label'.tr} $date");
    message.writeln("${'shared_with_label'.tr} $sharedNames\n");
    if (memory.memoryDetails.isNotEmpty) {
      message.writeln("${'notes_label'.tr} ${memory.memoryDetails}\n");
    }
    message.writeln('${'shared_via_footer'.tr}');

    final String text = message.toString();

    // Download images if any
    final List<XFile> xFiles = [];
    if (memory.imagesURL.isNotEmpty) {
      final tempDir = await getTemporaryDirectory();
      final dio = Dio();
      for (int i = 0; i < memory.imagesURL.length; i++) {
        final String url = memory.imagesURL[i];
        final String fileName = 'memory_share_$i.jpg';
        final String savePath = '${tempDir.path}/$fileName';
        await dio.download(url, savePath);
        xFiles.add(XFile(savePath));
      }
    }

    Get.back(); // Close loading

    if (xFiles.isNotEmpty) {
      await Share.shareXFiles(
        xFiles,
        text: text,
        subject: 'memory_share_subject'.tr,
      );
    } else {
      await Share.share(text, subject: 'memory_share_subject'.tr);
    }
  } catch (e) {
    Get.back();
    print("Error sharing memory: $e");
    Get.snackbar(
      'error'.tr,
      'failed_to_share_memory'.tr,
      backgroundColor: Color(0xFFAE1B25),
      colorText: Colors.white,
    );
  }
}

  // -----------------------------------
  // 💾 SAVE IMAGES TO GALLERY (Using Gal)
  // -----------------------------------
  Future<void> saveImagesToGallery() async {
    if (memory.imagesURL.isEmpty) {
      Get.snackbar(
        'no_images'.tr,
        'there_are_no_images_to_save'.tr,
        backgroundColor: Color(0xFFAE1B25),
        colorText: Colors.white,
      );
      return;
    }

    // Request permission
    if (!await Gal.hasAccess()) {
      final hasAccess = await Gal.requestAccess();
      if (!hasAccess) {
        Get.snackbar(
          'permission_denied'.tr,
          'please_grant_storage_permission_to_save_images'.tr,
          backgroundColor: Color(0xFFAE1B25),
          colorText: Colors.white,
        );
        return;
      }
    }

    Get.dialog(
      const Center(child: CircularProgressIndicator(color: Color(0xFFAE1B25))),
      barrierDismissible: false,
    );

    try {
      final tempDir = await getTemporaryDirectory();
      final dio = Dio();
      int savedCount = 0;

      for (int i = 0; i < memory.imagesURL.length; i++) {
        final String url = memory.imagesURL[i];
        final String fileName =
            'memory_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final String savePath = '${tempDir.path}/$fileName';
        await dio.download(url, savePath);
        await Gal.putImage(savePath);
        savedCount++;
      }

      Get.back();
      Get.snackbar(
        'success'.tr,
        '$savedCount ${'image_s_saved_to_gallery'.tr}',
        backgroundColor: const Color(0xFFAE1B25),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.back();
      print("Error saving images: $e");
      Get.snackbar(
        'error'.tr,
        'failed_to_save_images_to_gallery'.tr,
        backgroundColor: Color(0xFFAE1B25),
        colorText: Colors.white,
      );
    }
  }

  // -----------------------------------
  // 📋 SHOW ACTION SHEET
  // -----------------------------------
  void _showActionSheet(BuildContext context) {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            // Share option
            ListTile(
              leading: const Icon(Icons.share, color: Color(0xFFAE1B25)),
              title: Text('share_memory'.tr),
              subtitle: Text('share_with_images_and_details'.tr),
              onTap: () {
                Get.back();
                shareMemory();
              },
            ),
            // Save to gallery option
            if (memory.imagesURL.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.download, color: Color(0xFFAE1B25)),
                title: Text('save_to_gallery'.tr),
                subtitle: Text(
                  '${'save'.tr} ${memory.imagesURL.length} ${'image_s_to_your_device'.tr}',
                ),
                onTap: () {
                  Get.back();
                  saveImagesToGallery();
                },
              ),
            // Info about text sharing limitation
            if (memory.imagesURL.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  'note_some_apps_may_hide_text_when_sharing_images'.tr,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.close, color: Colors.grey),
              title: Text('cancel'.tr),
              onTap: () => Get.back(),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 750),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            // SHARE / MORE + CLOSE
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  padding: const EdgeInsets.only(left: 12, top: 12),
                  icon: const Icon(Icons.more_vert, color: Color(0xFFAE1B25)),
                  onPressed: () => _showActionSheet(context),
                ),
                IconButton(
                  padding: const EdgeInsets.only(right: 12, top: 12),
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title & Date
                    Center(
                      child: Text(
                        memory.activityName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: Text(
                        memory.completedAt != null
                            ? DateFormat(
                                'MMMM d, yyyy',
                              ).format(memory.completedAt!)
                            : 'no_date'.tr,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
  '${'from_label'.tr} ${memory.threadName}',
  style: TextStyle(
    fontSize: 13,
    color: Colors.grey[700],
    fontStyle: FontStyle.italic,
  ),
),
                    ),
                    const SizedBox(height: 24),

                    // IMAGES
                    if (memory.imagesURL.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox(
                          height: 280,
                          width: double.infinity,
                          child: PageView.builder(
                            itemCount: memory.imagesURL.length,
                            itemBuilder: (context, index) {
                              return Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.network(
                                    memory.imagesURL[index],
                                    fit: BoxFit.cover,
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                      if (loadingProgress == null)
                                        return child;
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    },
                                  ),
                                  if (memory.imagesURL.length > 1)
                                    Positioned(
                                      bottom: 8,
                                      right: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          "${index + 1}/${memory.imagesURL.length}",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                      )
                    else
                      Container(
                        height: 280,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.photo_library_outlined,
                            size: 60,
                            color: Colors.grey,
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),

                    // SHARED WITH
                    if (memory.sharedWith.isNotEmpty) ...[
                      Text(
                        'shared_with'.tr,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FutureBuilder<List<UserModel>>(
                        future: _fetchSharedUsers(memory.sharedWith),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData)
                            return const CircularProgressIndicator();
                          final users = snapshot.data!;
                          return Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: users.isNotEmpty
                                ? users.map((user) {
                                    return Chip(
                                      avatar: CircleAvatar(
                                        backgroundImage:
                                            user.photoUrl != null &&
                                                user.photoUrl!.isNotEmpty
                                            ? NetworkImage(user.photoUrl!)
                                            : null,
                                        child:
                                            user.photoUrl == null ||
                                                user.photoUrl!.isEmpty
                                            ? Text(user.name[0].toUpperCase())
                                            : null,
                                      ),
                                      label: Text(user.name.split(' ').first),
                                    );
                                  }).toList()
                                : [Text('none'.tr)],
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                    ],

                    // NOTES
                    if (memory.memoryDetails.isNotEmpty) ...[
                      Text(
                        'notes'.tr,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        memory.memoryDetails,
                        style: TextStyle(fontSize: 15, color: Colors.grey[800]),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Fetch user details from Firestore
Future<List<UserModel>> _fetchSharedUsers(List<String> userIds) async {
  if (userIds.isEmpty) return [];

  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where(
          FieldPath.documentId,
          whereIn: userIds.length > 10 ? userIds.sublist(0, 10) : userIds,
        )
        .get();

    return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
  } catch (e) {
    print("Error fetching shared users: $e");
    return [];
  }
}
