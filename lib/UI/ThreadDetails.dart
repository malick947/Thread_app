import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:the_read_thread/Controller/ThreadController.dart';
import 'package:the_read_thread/Controller/friendsController.dart';
import 'package:the_read_thread/Model/UserModel.dart';
import 'package:the_read_thread/Model/activityModel.dart';
import 'package:the_read_thread/Model/threadModel.dart';
import 'package:the_read_thread/Model/sparkActivityModel.dart';
import 'package:the_read_thread/Services/authService.dart';
import 'package:the_read_thread/utiles/buttons.dart';
import 'package:the_read_thread/utiles/sparkActivitiesDetailsDialog.dart';
import 'package:the_read_thread/utiles/sparkActivityDailog.dart';

class ThreadDetailsScreen extends StatefulWidget {
  final Thread thread;

  const ThreadDetailsScreen({super.key, required this.thread});

  @override
  State<ThreadDetailsScreen> createState() => _ThreadDetailsScreenState();
}

class _ThreadDetailsScreenState extends State<ThreadDetailsScreen> {
  void showManageThreadDialog(BuildContext context, Thread thread) {
    final FriendsController friendsController = Get.find<FriendsController>();
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final RxSet<String> originalMembers = thread.members.toSet().obs;
    final RxSet<String> tempMembers = thread.members.toSet().obs;
    final RxString searchQuery = ''.obs;
    final TextEditingController searchController = TextEditingController();

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'manage_thread'.tr,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
                Text(
                  '${'add_people_to'.tr} "${thread.name}"',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Icon(Icons.people, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'current_members'.tr,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Obx(
                      () => Text(
                        " (${tempMembers.length})",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Obx(() {
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: tempMembers.map((uid) {
                      final user =
                          friendsController.friends.firstWhereOrNull(
                            (f) => f.id == uid,
                          ) ??
                          UserModel(id: uid, name: 'unknown'.tr, email: '');

                      return Chip(
                        avatar: CircleAvatar(
                          backgroundColor: _getColor(user.avatarColorIndex),
                          child: Text(
                            uid == currentUserId ? 'me'.tr.toUpperCase() : user.initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        label: Text(uid == currentUserId ? 'me'.tr.toUpperCase() : user.name),
                        backgroundColor: uid == currentUserId
                            ? const Color(0xFFAE1B25)
                            : Colors.grey[200],
                        labelStyle: TextStyle(
                          color: uid == currentUserId
                              ? Colors.white
                              : Colors.black87,
                        ),
                      );
                    }).toList(),
                  );
                }),
                const SizedBox(height: 24),
                 Row(
                  children: [
                    Icon(Icons.person_add, size: 20, color: Colors.grey),
                    SizedBox(width: 8),
                    Text(
                      'add_people'.tr,
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'search_friends'.tr,
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) => searchQuery.value = value.toLowerCase(),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 300,
                  child: Obx(() {
                    List<UserModel> filteredFriends = friendsController.friends
                        .where(
                          (friend) => friend.username!.toLowerCase().contains(
                            searchQuery.value,
                          ),
                        )
                        .toList();

                    if (filteredFriends.isEmpty) {
                      return Center(
                        child: Text(
                          'no_friends_found'.tr,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      );
                    }

                    filteredFriends.sort((a, b) {
                      final aIn = tempMembers.contains(a.id);
                      final bIn = tempMembers.contains(b.id);
                      if (aIn && !bIn) return -1;
                      if (!aIn && bIn) return 1;
                      return a.name.compareTo(b.name);
                    });

                    return ListView.builder(
                      itemCount: filteredFriends.length,
                      itemBuilder: (context, index) {
                        final friend = filteredFriends[index];
                        final isAdded = tempMembers.contains(friend.id);

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Color(0xFFE67C93),
                            child: Text(
                              friend.initials,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(friend.username!),
                          trailing: ElevatedButton(
                            onPressed: () {
                              if (isAdded) {
                                tempMembers.remove(friend.id);
                              } else {
                                tempMembers.add(friend.id);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isAdded
                                  ? Colors.grey[400]
                                  : const Color(0xFFAE1B25),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                            ),
                            child: Text(isAdded ? 'added'.tr : 'add'.tr),
                          ),
                        );
                      },
                    );
                  }),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final ThreadController threadController = Get.put(
                        ThreadController(),
                      );

                      for (String uid in originalMembers) {
                        if (!tempMembers.contains(uid)) {
                          await threadController.addFriendToThread(
                            thread.id,
                            uid,
                          );
                        }
                      }

                      for (String uid in tempMembers) {
                        if (!originalMembers.contains(uid)) {
                          await threadController.addFriendToThread(
                            thread.id,
                            uid,
                          );
                        }
                      }

                      Get.back();
                      Get.back();

                      Get.snackbar(
                        'saved'.tr,
                        'thread_members_updated'.tr,
                        backgroundColor: Color(0xFFAE1B25),
                        colorText: Colors.white,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFAE1B25),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      'save_changes'.tr,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getColor(int index) {
    const colors = [
      Color(0xFF8B1538),
      Color(0xFF5D4E6D),
      Color(0xFF3498DB),
      Color(0xFFE74C3C),
      Color(0xFF9B59B6),
      Color(0xFF1ABC9C),
      Color(0xFFF39C12),
    ];
    return colors[index % colors.length];
  }

  Future<void> addMembersInActivity({
    required BuildContext context,
    required Activity activity,
    required String threadId,
  }) async {
    List<String> selectedMembers = List.from(activity.assignTo);

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: Text('assign_members'.tr),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _members.length,
                  itemBuilder: (context, index) {
                    final user = _members[index];
                    final isSelected = selectedMembers.contains(user.id);

                    return CheckboxListTile(
                      title: Text(user.name),
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            selectedMembers.add(user.id);
                          } else {
                            selectedMembers.remove(user.id);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('cancel'.tr),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await ThreadController().updateActivityAssignedMembers(
                      threadId: threadId,
                      activityId: activity.id,
                      members: selectedMembers,
                    );
                    Navigator.pop(context);
                    Get.back();
                  },
                  child: Text('add'.tr),
                ),
              ],
            );
          },
        );
      },
    );
  }

  final ThreadController _threadController = ThreadController();
  List<UserModel> _members = [];
  bool _isLoadingMembers = true;
  late Stream<Thread?> _threadStream;

  @override
  void initState() {
    super.initState();
    _loadMembers();
    _initializeThreadStream();
  }

  void _initializeThreadStream() {
    _threadStream = _threadController.getThreadStream(widget.thread.id);
  }

  Future<void> _loadMembers() async {
    List<UserModel> members = await _threadController.getUsersByIds(
      widget.thread.members,
    );
    if (mounted) {
      setState(() {
        _members = members;
        _isLoadingMembers = false;
      });
    }
  }

  Future<void> _refreshData() async {
    await _loadMembers();
  }

  Widget _buildMembersAvatars() {
    if (_members.isEmpty) return const SizedBox();

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Icon(Icons.people, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        ...List.generate(_members.length > 3 ? 3 : _members.length, (index) {
          return Transform.translate(
            offset: Offset(index * -8.0, 0),
            child: _buildUserAvatar(_members[index]),
          );
        }),
        if (_members.length > 3)
          Transform.translate(
            offset: Offset(_members.length > 3 ? -8.0 * 3 : 0, 0),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: Text(
                  '+${_members.length - 3}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUserAvatar(UserModel user) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Color(0xFFE67C93),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Center(
        child: Text(
          user.initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2C3E50)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.thread.name,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C3E50),
          ),
        ),
        backgroundColor: Colors.grey[50],
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: StreamBuilder<Thread?>(
          stream: _threadStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            Thread displayThread = snapshot.data ?? widget.thread;

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 16,
                                      color: Color(0xFFAE1B25),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      DateFormat('MMMM yyyy').format(
                                        displayThread.createdAt.toDate(),
                                      ),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              _isLoadingMembers
                                  ? const SizedBox()
                                  : _buildMembersAvatars(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'progress'.tr,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  '${displayThread.completedActivities} ${'of'.tr} ${displayThread.totalActivities} ${'completed'.tr}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(width: 7),
                                Text(
                                  '(${displayThread.totalActivities > 0 ? ((displayThread.completedActivities / displayThread.totalActivities) * 100).toInt() : 0}%)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: displayThread.totalActivities > 0
                                ? displayThread.completedActivities /
                                    displayThread.totalActivities
                                : 0,
                            backgroundColor: const Color(0xFFE8D5D9),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF8B1538),
                            ),
                            minHeight: 10,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              showManageThreadDialog(context, displayThread);
                            },
                            icon: Icon(Icons.people, color: Colors.grey[700]),
                            label: Text(
                              'manage_thread'.tr,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: Colors.grey[300]!),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'bucket_list_activities'.tr,
                      style: const TextStyle(
                        fontSize: 20,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (displayThread.activities.isNotEmpty)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: displayThread.activities.length,
                      itemBuilder: (context, index) {
                        return ActivityCard(
                          activity: displayThread.activities[index],
                          members: _members,
                          threadId: displayThread.id,
                          onStatusChanged: () {},
                          onAssignMembers: () => addMembersInActivity(
                            context: context,
                            activity: displayThread.activities[index],
                            threadId: displayThread.id,
                          ),
                        );
                      },
                    )
                  else
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.checklist_outlined,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'no_activities_yet'.tr,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'tap_plus_to_add'.tr,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 80),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        onPressed: () {
          showAddActivityDialog(
            context: context,
            thread: widget.thread,
            myFriends: _members,
            currentUserId: AuthService().currentUser!.uid,
            currentUserName: AuthService().currentUser!.displayName ?? 'me'.tr,
          );
        },
        backgroundColor: const Color(0xFF8B1538),
        child: const Icon(Icons.add, size: 32, color: Colors.white),
      ),
    );
  }

  

  
}

// In ActivityCard widget, update the detection logic:

class ActivityCard extends StatelessWidget {
  final Activity activity;
  final List<UserModel> members;
  final String threadId;
  final VoidCallback onStatusChanged;
  final String currentUserId = AuthService().currentUser!.uid;
  final VoidCallback onAssignMembers;

  ActivityCard({
    super.key,
    required this.activity,
    required this.members,
    required this.threadId,
    required this.onStatusChanged,
    required this.onAssignMembers,
  });

  @override
  Widget build(BuildContext context) {
    bool isCompleted = activity.status == 'completed';
    bool isSpark = activity.isSpark;

    // FIXED: Check createdBy for both regular and spark activities
    String activityCreator = activity.createdBy;
    bool canDelete = activityCreator == currentUserId;

    return InkWell(
      // When clicking on the CARD BODY (not checkbox)
      onTap: () async {
        if (isSpark) {
          // Show the special spark details dialog
          final sparkActivity = await ThreadController()
              .getSparkActivityDetails(threadId, activity.id);

          if (sparkActivity != null) {
            final result = await showDialog<bool>(
              context: context,
              barrierDismissible: true,
              builder: (context) => SparkActivityDetailsDialog(
                threadId: threadId,
                activityId: activity.id,
                sparkActivity: sparkActivity,
                isCompleted: isCompleted,
              ),
            );

            if (result == true) {
              onStatusChanged();
            }
          }
        } else {
          // Show normal activity details dialog
          final result = await showDialog<bool>(
            context: context,
            barrierDismissible: true,
            builder: (context) => NormalActivityDetailsDialog(
              threadId: threadId,
              activityId: activity.id,
              activity: activity,
              isCompleted: isCompleted,
            ),
          );

          if (result == true) {
            onStatusChanged();
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isCompleted ? const Color(0xFFD4EDDA) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCompleted ? const Color(0xFF28A745) : Colors.grey[300]!,
            width: isCompleted ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Checkbox - ALWAYS SHOWS NORMAL DIALOG FOR BOTH TYPES
              GestureDetector(
                onTap: () async {
                  if (!isCompleted) {
                    // BOTH spark and regular activities show the NORMAL completion dialog
                    final bool? shouldComplete = await showDialog<bool>(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => MemoryCaptureDialog(
                        threadId: threadId,
                        activityId: activity.id,
                        activityName: activity.name,
                      ),
                    );

                    if (shouldComplete == true) {
                      await ThreadController().updateActivityStatus(
                        threadId,
                        activity.id,
                        'completed',
                      );
                      onStatusChanged();
                    }
                  }
                },
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isCompleted ? const Color(0xFF28A745) : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isCompleted
                          ? const Color(0xFF28A745)
                          : Colors.grey[400]!,
                      width: 2,
                    ),
                  ),
                  child: isCompleted
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: Icon(Icons.group_add),
                onPressed: onAssignMembers,
              ),

              // Activity content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              // Spark flame emoji indicator
                              if (isSpark) ...[
                                Text('🔥', style: TextStyle(fontSize: 18)),
                                SizedBox(width: 4),
                              ],
                              Expanded(
                                child: Text(
                                  activity.name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF2C3E50),
                                    decoration: isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                    decorationColor: Colors.grey[600],
                                    decorationThickness: 2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // DELETE BUTTON - NOW SHOWN FOR ALL ACTIVITIES (both regular and spark)
                        if (canDelete)
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Color(0xFFAE1B25),
                            ),
                            onPressed: () => _confirmDelete(context),
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                          ),
                      ],
                    ),

                    // Activity status
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? const Color(0xFF28A745)
                                : const Color(0xFFAE1B25),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isCompleted ? 'done'.tr : 'pending'.tr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        // Show spark category badge if it's a spark
                        if (isSpark && activity.sparkCategory != null) ...[
                          SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Color(0xFFB91C1C).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: Color(0xFFB91C1C),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              activity.sparkCategory!,
                              style: const TextStyle(
                                color: Color(0xFFB91C1C),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                        // Add "Tap to view" hint for spark activities
                        if (isSpark && !isCompleted) ...[
                          SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.touch_app,
                                  size: 12,
                                  color: Colors.blue[700],
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'tap_to_view_details'.tr,
                                  style: TextStyle(
                                    color: Colors.blue[700],
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        // Add "Tap to view" hint for regular activities too
                        if (!isSpark && !isCompleted) ...[
                          SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.purple[50],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 12,
                                  color: Colors.purple[700],
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'tap_for_details'.tr,
                                  style: TextStyle(
                                    color: Colors.purple[700],
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),

                    // Assigned members
                    if (activity.assignTo.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ...activity.assignTo.take(3).map((userId) {
                            UserModel? user = members.firstWhere(
                              (m) => m.id == userId,
                              orElse: () =>
                                  UserModel(id: userId, name: '', email: ''),
                            );
                            return Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: _buildSmallAvatar(user),
                            );
                          }).toList(),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text('delete_activity_question'.tr),
          content: Text(
            activity.isSpark
                ? 'delete_spark_activity_confirm'.tr
                : 'delete_activity_confirm'.tr,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('cancel'.tr),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFAE1B25),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'delete'.tr,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
        
      },
    );

    if (confirm == true) {
      await ThreadController().deleteActivity(threadId, activity.id);
    }
  }

  Widget _buildSmallAvatar(UserModel user) {
    return Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(
        color: Color(0xFFE67C93),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          user.initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// This dialog shows when clicking on a REGULAR ACTIVITY CARD (not the checkbox)
/// It displays activity details AND includes completion functionality
class NormalActivityDetailsDialog extends StatefulWidget {
  final String threadId;
  final String activityId;
  final Activity activity;
  final bool isCompleted;

  const NormalActivityDetailsDialog({
    Key? key,
    required this.threadId,
    required this.activityId,
    required this.activity,
    this.isCompleted = false,
  }) : super(key: key);

  @override
  State<NormalActivityDetailsDialog> createState() =>
      _NormalActivityDetailsDialogState();
}

class _NormalActivityDetailsDialogState
    extends State<NormalActivityDetailsDialog> {
  final TextEditingController _memoryController = TextEditingController();
  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  bool _showCompletionSection = false;

  @override
  void dispose() {
    _memoryController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images.map((xFile) => File(xFile.path)));
        });
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick images: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<List<String>> _uploadImages() async {
    List<String> downloadUrls = [];

    for (File imageFile in _selectedImages) {
      try {
        String fileName =
            'memories/${widget.threadId}/${DateTime.now().millisecondsSinceEpoch}_${_selectedImages.indexOf(imageFile)}.jpg';
        Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
        UploadTask uploadTask = storageRef.putFile(imageFile);
        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();
        downloadUrls.add(downloadUrl);
      } catch (e) {
        print('Error uploading image: $e');
      }
    }

    return downloadUrls;
  }

  Future<void> _completeActivity() async {
    setState(() => _isUploading = true);

    try {
      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        imageUrls = await _uploadImages();
      }

      await ThreadController().addToMemory(
        threadId: widget.threadId,
        activityId: widget.activityId,
        memoryDetails: _memoryController.text,
        imagesURL: imageUrls,
      );

      await ThreadController().updateActivityStatus(
        widget.threadId,
        widget.activityId,
        'completed',
      );

      Get.back(result: true);

      Get.snackbar(
        'Success! 🎉',
        'Activity completed and memory saved',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to complete activity: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activity = widget.activity;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with close button
              Row(
                children: [
                  Flexible(
                    child: Text(
                      activity.name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Get.back(result: false),
                  ),
                ],
              ),

              SizedBox(height: 8),

              // Status badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.isCompleted
                      ? Color(0xFFD4EDDA)
                      : Color(0xFFFFF5F5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: widget.isCompleted
                        ? Color(0xFF28A745)
                        : Color(0xFFAE1B25),
                  ),
                ),
                child: Text(
                  widget.isCompleted ? 'completed'.tr.toUpperCase() : 'pending'.tr.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.isCompleted
                        ? Color(0xFF28A745)
                        : Color(0xFFAE1B25),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              SizedBox(height: 16),

              // Activity Details Section
              if (activity.activityDetails.isNotEmpty) ...[
                Text(
                  'details'.tr,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    activity.activityDetails,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ),
                SizedBox(height: 16),
              ],

              // Date Section (if available)
              if (activity.activityDate != null) ...[
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    SizedBox(width: 8),
                    Text(
                      'scheduled_date'.tr,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  DateFormat(
                    'EEEE, MMMM d, yyyy',
                  ).format(activity.activityDate!),
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
                SizedBox(height: 16),
              ],

              // Created Date
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 8),
                  Text(
                    'created'.tr,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                DateFormat(
                  'MMMM d, yyyy - h:mm a',
                ).format(activity.createdAt.toDate()),
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),

              SizedBox(height: 16),

              // Assigned Members Section (if not empty)
              if (activity.assignTo.isNotEmpty) ...[
                Divider(),
                SizedBox(height: 16),
                Text(
                  'assigned_to'.tr,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '${activity.assignTo.length} ${'member_s'.tr}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                SizedBox(height: 16),
              ],

              if (widget.isCompleted) ...[
                Divider(),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFFD4EDDA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Color(0xFF28A745)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: Color(0xFF28A745)),
                          SizedBox(width: 12),
                          Text(
                            'activity_completed'.tr,
                            style: TextStyle(
                              color: Color(0xFF28A745),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      if (activity.completedAt != null) ...[
                        SizedBox(height: 8),
                        Text(
                          '${'completed_on'.tr} ${DateFormat('MMMM d, yyyy').format(activity.completedAt!.toDate())}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                      if (activity.isMemory &&
                          activity.memoryDetails.isNotEmpty) ...[
                        SizedBox(height: 12),
                        Divider(color: Color(0xFF28A745)),
                        SizedBox(height: 8),
                        Text(
                          'memory'.tr,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF28A745),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          activity.memoryDetails,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                      if (activity.imagesURL.isNotEmpty) ...[
                        SizedBox(height: 12),
                        Text(
                          '${activity.imagesURL.length} ${'photo_s_attached'.tr}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
