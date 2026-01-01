import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:the_read_thread/Controller/friendsController.dart';
import 'package:the_read_thread/Model/UserModel.dart';
import 'package:the_read_thread/UI/FriendsDetails.dart';
import 'package:the_read_thread/utiles/buttons.dart';

class MyFriendsScreen extends StatelessWidget {
  final FriendsController controller = Get.put(FriendsController());

  void _showInviteDialog(BuildContext context) {
    final controller = Get.find<FriendsController>();
    controller.resetInvitedState();

    Get.dialog(
      Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'send_friend_request_title'.tr,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 16),

                  // Search Field
                  TextField(
                    autofocus: true,
                    onChanged: (value) {
                      controller.updateSearch(value.trim());
                    },
                    decoration: InputDecoration(
                      hintText: 'search_by_name_or_email'.tr,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          controller.updateSearch("");
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Search Results Area
                  SizedBox(
                    height: 350,
                    child: FutureBuilder<List<UserModel>>(
                      future: controller.getUsersForInvite(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(
                            child: Text('no_users_available_to_invite'.tr),
                          );
                        }

                        final allUsers = snapshot.data!;

                        return Obx(() {
                          final query = controller.searchQuery.value;
                          final filteredUsers = query.isEmpty
                              ? <UserModel>[]
                              : allUsers.where((user) {
                                  final name = (user.username ?? '')
                                      .toLowerCase();
                                  final email = (user.email ?? '')
                                      .toLowerCase();
                                  return name.contains(query) ||
                                      email.contains(query);
                                }).toList();

                          if (query.isEmpty) {
                            return Center(
                              child: Text(
                                'type_to_search_for_friends'.tr,
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                            );
                          }

                          if (filteredUsers.isEmpty) {
                            return Center(
                              child: Text(
                                'no_users_found'.tr,
                                style: TextStyle(color: Colors.grey),
                              ),
                            );
                          }

                          return ListView.builder(
                            itemCount: filteredUsers.length,
                            itemBuilder: (context, index) {
                              final user = filteredUsers[index];
                              final isInvited = controller.isInvited(user.id!);

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFFF2E6E6),
                                  child: Text(
                                    user.name?[0].toUpperCase() ?? "U",
                                    style: const TextStyle(
                                      color: Color(0xFFAE1B25),
                                    ),
                                  ),
                                ),
                                title: Text(user.name ?? "Unknown User"),
                                subtitle: user.email != null
                                    ? Text(
                                        user.email!,
                                        style: const TextStyle(fontSize: 12),
                                      )
                                    : null,
                                trailing: ElevatedButton(
                                  onPressed: isInvited
                                      ? null
                                      : () async {
                                          await controller.sendFriendRequest(
                                            user.id!,
                                            user.name ?? "Unknown",
                                          );
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isInvited
                                        ? Colors.grey[400]
                                        : const Color(0xFFAE1B25),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    minimumSize: const Size(80, 36),
                                  ),
                                  child: Text(
                                    isInvited ? 'sent'.tr : 'send'.tr,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              );
                            },
                          );
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextButton(
                    onPressed: () => Get.back(),
                    child: Text('close'.tr),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text('my_thread_connections'.tr,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          bottom: TabBar(
            labelColor: Color(0xFFAE1B25),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFFAE1B25),
            tabs: [
              Tab(text: 'friends'.tr),
              Tab(text: 'requests'.tr),
            ],
          ),
        ),
        body: TabBarView(
          children: [_buildFriendsTab(context), _buildRequestsTab(context)],
        ),
      ),
    );
  }

  Widget _buildFriendsTab(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: SizedBox(
            width: double.infinity,
            child: RedButtonContainer(
              text: 'send_friend_request'.tr,
              isBold: true,
              onTap: () => _showInviteDialog(context),
              preIcon: Icons.person_add_alt,
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<UserModel>>(
            stream: controller.myFriendsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'error_loading_friends'.tr,
                    style: TextStyle(color: Colors.red),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Text(
                    'no_friends_yet'.tr,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                );
              }

              final friends = snapshot.data!;

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: friends.length,
                itemBuilder: (context, index) {
                  final friend = friends[index];

                  return StreamBuilder<int>(
                    stream: controller.sharedThreadsCountStream(friend.id!),
                    builder: (context, countSnapshot) {
                      int count = countSnapshot.data ?? 0;

                      return Card(
                        color: Colors.white,
                        elevation: 1,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 16,
                          ),
                          onTap: () {
                            Get.to(() => FriendDetailsScreen(friend: friend));
                          },
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFF2E6E6),
                            child: Text(
                              friend.name?[0].toUpperCase() ?? "U",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          title: Text(
                            friend.name ?? "Unknown",
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            count > 0
                                ? '${'in'.tr} $count ${'shared_thread'.tr}${count > 1 ? 's' : ''}'
                                : 'no_shared_threads_yet'.tr,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRequestsTab(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: controller.pendingRequestsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'error_loading_requests'.tr,
              style: TextStyle(color: Colors.red),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              'no_pending_requests'.tr,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        final requests = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            final UserModel user = request['user'];
            final String sender = request['sender'];
            final String receiver = request['receiver'];
            final bool isSentByMe = sender == controller.currentUserId;

            return Card(
              color: Colors.white,
              elevation: 1,
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFFF2E6E6),
                      radius: 24,
                      child: Text(
                        user.name?[0].toUpperCase() ?? "U",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name ?? "Unknown",
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isSentByMe ? 'request_sent'.tr : 'wants_to_connect'.tr,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSentByMe)
                      TextButton(
                        onPressed: () async {
                          await controller.cancelFriendRequest(user.id!);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey[700],
                        ),
                        child: Text('cancel'.tr),
                      )
                    else
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () async {
                              await controller.acceptFriendRequest(user.id!);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFAE1B25),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                            child: Text('accept'.tr),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () async {
                              await controller.rejectFriendRequest(user.id!);
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey[700],
                            ),
                            child: Text('reject'.tr),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}