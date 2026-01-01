import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'package:the_read_thread/Controller/ProfileController.dart';

import 'package:the_read_thread/Controller/ThreadController.dart';

import 'package:the_read_thread/Controller/friendsController.dart';

import 'package:the_read_thread/Model/UserModel.dart';

import 'package:the_read_thread/Model/threadModel.dart';

import 'package:the_read_thread/Services/authService.dart';

import 'package:the_read_thread/Services/notification_service.dart';

import 'package:the_read_thread/UI/ThreadDetails.dart';
import 'package:the_read_thread/UI/notiScreen.dart';

import 'package:the_read_thread/utiles/buttons.dart';

class ThreadsScreen extends StatefulWidget {
  const ThreadsScreen({super.key});

  @override
  State<ThreadsScreen> createState() => _ThreadsScreenState();
}

class _ThreadsScreenState extends State<ThreadsScreen> {
  final ProfileController controller = Get.put(ProfileController());
  final ThreadController _threadController = ThreadController();
  final FriendsController friendsController = Get.put(FriendsController());
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final NotificationService notificationService = NotificationService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          ElevatedButton(
            onPressed: () async {
              Get.to(NotificationScreen());
            },
            child: Text("get sending screen"),
          ),

          ElevatedButton(
            onPressed: () async {
              await notificationService.getToken();
            },
            child: Text("get sending screen"),
          ),
          const SizedBox(height: 12),
          Text(
            'my_threads_and_journeys'.tr,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<List<Thread>>(
              stream: _threadController.getUserThreads(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF8B1538)),
                  );
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.explore_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'no_threads_yet'.tr,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'create_your_first_journey'.tr,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                List<Thread> threads = snapshot.data!;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: threads.length,
                  itemBuilder: (context, index) {
                    return ThreadCard(thread: threads[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Obx(() {
        if (friendsController.isLoading.value) {
          return const Padding(
            padding: EdgeInsets.only(left: 14.0, right: 14),
            child: SizedBox(
              width: double.infinity,
              height: 60,
              child: FloatingActionButton.extended(
                onPressed: null,
                backgroundColor: Color(0xFF8B1538),
                label: Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            ),
          );
        }

        final List<UserModel> friendsList = friendsController.friends.toList();

        return FloatingActionButton(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          onPressed: () {
            showCreateThreadDialog(context, friendsList);
          },
          backgroundColor: const Color(0xFF8B1538),
          child: const Icon(Icons.add, size: 32, color: Colors.white),
        );
      }),
    );
  }
}

class ThreadCard extends StatelessWidget {
  final Thread thread;
  final FriendsController friendsController = Get.find<FriendsController>();

  ThreadCard({super.key, required this.thread});

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text('delete_thread'.tr),
          content: Text('delete_thread_confirm'.tr),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('cancel'.tr),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFAE1B25),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                await ThreadController().deleteThread(thread.id);

                Get.snackbar(
                  'thread_deleted'.tr,
                  "${thread.name} ${'thread_deleted_message'.tr}",
                  backgroundColor: const Color(0xFFAE1B25),
                  colorText: Colors.white,
                );
              },
              child: Text(
                'delete'.tr,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Color cardColor = _getCardColor();
    String subtitle = _getSubtitle();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildAvatarSection(),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        thread.memberCount == 1
                            ? 'my_solo_journey'.tr
                            : thread.memberCount == 2
                            ? 'shared_journey_with_one_person'.tr
                            : 'group_journey'.tr,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        thread.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${thread.completedActivities} ${'of'.tr} ${thread.totalActivities} ${'goals_completed'.tr}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: thread.totalActivities > 0
                        ? thread.completedActivities / thread.totalActivities
                        : 0,
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF8B1538),
                    ),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (AuthService().currentUser!.uid == thread.createdBy)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Color(0xFFAE1B25)),
                    onPressed: () => _confirmDelete(context),
                  )
                else
                  const SizedBox(width: 48),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () {
                      Get.to(
                        () => ThreadDetailsScreen(thread: thread),
                        transition: Transition.rightToLeft,
                        duration: const Duration(milliseconds: 400),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B1538),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'view_thread'.tr,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    final friendIdsInThread = thread.members
        .where((id) => id != currentUserId)
        .toList();

    final matchedFriends = friendsController.friends
        .where((friend) => friendIdsInThread.contains(friend.id))
        .toList();

    if (thread.memberCount == 1 || friendIdsInThread.isEmpty) {
      return _buildCircleAvatar('ME', const Color(0xFF293035));
    }

    if (matchedFriends.isNotEmpty && matchedFriends.length == 1) {
      final friend = matchedFriends[0];
      final initials = friend.name.isNotEmpty
          ? friend.name.split(' ').map((e) => e[0]).take(2).join().toUpperCase()
          : '??';

      return Row(
        children: [
          _buildCircleAvatar('ME', const Color(0xFF2C3E50)),
          Transform.translate(
            offset: const Offset(-12, 0),
            child: _buildCircleAvatar(initials, const Color(0xFF8B1538)),
          ),
        ],
      );
    }

    if (matchedFriends.length >= 2) {
      final friend1 = matchedFriends[0];
      final friend2 = matchedFriends[1];
      final initials1 = friend1.name.isNotEmpty
          ? friend1.name
                .split(' ')
                .map((e) => e[0])
                .take(2)
                .join()
                .toUpperCase()
          : '??';
      final initials2 = friend2.name.isNotEmpty
          ? friend2.name
                .split(' ')
                .map((e) => e[0])
                .take(2)
                .join()
                .toUpperCase()
          : '??';

      return SizedBox(
        width: 80,
        height: 50,
        child: Stack(
          children: [
            _buildCircleAvatar('ME', const Color(0xFF293035)),
            Positioned(
              left: 24,
              child: _buildCircleAvatar(initials1, const Color(0xFF293035)),
            ),
            Positioned(
              left: 48,
              child: _buildCircleAvatar(initials2, const Color(0xFFAE1B25)),
            ),
          ],
        ),
      );
    }

    return _buildCircleAvatar('ME', const Color(0xFF2C3E50));
  }

  Widget _buildCircleAvatar(String text, Color color, {double size = 40}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFAE1B25), width: 3),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Color _getCardColor() {
    return const Color(0xFFF2E6E6); // same for all cases as in original
  }

  String _getSubtitle() {
    if (thread.isSolo) return '${thread.totalActivities} goals';
    if (thread.memberCount == 2)
      return '${thread.activities.length} Journeys Weaving';
    return '${thread.totalActivities} Adventures Planned';
  }
}
