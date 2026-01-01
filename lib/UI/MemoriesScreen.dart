// screens/memories_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:the_read_thread/Controller/MemoryController.dart';
import 'package:the_read_thread/Controller/friendsController.dart';
import 'package:the_read_thread/utiles/buttons.dart';

import 'byJourneyDetailsScreen.dart';

void showMemoryDetailDialog(BuildContext context, MemoryItem memory) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) => MemoryDetailDialog(memory: memory),
  );
}

class MemoriesScreen extends StatefulWidget {
  const MemoriesScreen({super.key});

  @override
  State<MemoriesScreen> createState() => _MemoriesScreenState();
}

class _MemoriesScreenState extends State<MemoriesScreen> {
  final MemoryController controller = Get.put(MemoryController());

  @override
  void initState() {
    super.initState();
    controller.refreshMemories();
  }

  void _showFriendFilterBottomSheet(BuildContext context) {
    final friendsController = Get.find<FriendsController>();

    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'show_memories_shared_with'.tr,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Obx(() {
              if (friendsController.isLoading.value) {
                return CircularProgressIndicator();
              }
              return ListTile(
                leading: CircleAvatar(child: Icon(Icons.all_inclusive)),
                title: Text('all_friends_show_all'.tr),
                onTap: () {
                  controller.selectedFriendFilter.value = null;
                  Navigator.pop(context);
                },
              );
            }),
            Divider(),
            Expanded(
              child: Obx(
                () => ListView.builder(
                  itemCount: friendsController.friends.length,
                  itemBuilder: (context, i) {
                    final friend = friendsController.friends[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(
                          friend.photoUrl ?? friend.name[0],
                        ),
                      ),
                      title: Text(friend.name),
                      subtitle: FutureBuilder<int>(
                        future: friendsController.getSharedThreadsCount(
                          friend.id,
                        ),
                        builder: (context, snapshot) {
                          final count = snapshot.data ?? 0;
                          return Text(
                            '$count ${'journeys_together'.tr}',
                          );
                        },
                      ),
                      onTap: () {
                        controller.selectedFriendFilter.value = friend;
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          SizedBox(height: 10),
          Text("Memories".tr, style: TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold)),
          SizedBox(height: 3),
          Text(
            'the_timeline'.tr,
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          ),

          // Sorted by Friend Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: GestureDetector(
              onTap: () => _showFriendFilterBottomSheet(context),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.filter_list, size: 18, color: Colors.grey[700]),
                    SizedBox(width: 8),
                    Obx(() {
                      final friend = controller.selectedFriendFilter.value;
                      final text = friend == null
                          ? 'all_memories'.tr
                          : '${'with'.tr} ${friend.name.split(' ').first}';
                      return Text(
                        '${'sorted_by'.tr} $text',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFAE1B25),
                        ),
                      );
                    }),
                    if (controller.selectedFriendFilter.value != null) ...[
                      SizedBox(width: 8),
                      GestureDetector(
                        onTap: () =>
                            controller.selectedFriendFilter.value = null,
                        child: Icon(Icons.clear, size: 18),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Tabs (Timeline / By Journey)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Obx(
              () => Row(
                children: [
                  _tabButton('timeline'.tr, 0, controller),
                  _tabButton('by_journey'.tr, 1, controller),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Content
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.memories.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.photo_library_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'no_memories_yet'.tr,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'complete_activities_add_photos'.tr,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: controller.selectedTab.value == 0
                    ? _buildTimelineView(controller)
                    : _buildByJourneyView(controller),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _tabButton(String title, int index, MemoryController controller) {
    bool isSelected = controller.selectedTab.value == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.selectedTab.value = index,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.black87 : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  // Timeline Tab - Grid View
  Widget _buildTimelineView(MemoryController controller) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.78,
      ),
      itemCount: controller.filteredMemories.length,
      itemBuilder: (context, index) {
        final memory = controller.filteredMemories[index];
        return _MemoryGridCard(memory: memory);
      },
    );
  }

  // By Journey Tab - Grouped by Thread
  Widget _buildByJourneyView(MemoryController controller) {
    final grouped = <String, List<MemoryItem>>{};
    for (var m in controller.filteredMemories) {
      grouped.putIfAbsent(m.threadName, () => []).add(m);
    }

    final sortedKeys = grouped.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final threadName = sortedKeys[index];
        final items = grouped[threadName]!;
        final coverImages = items.take(3).map((e) => e.coverImageUrl).toList();

        return Card(
          color: Colors.white,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                children: [
                  _coverPhoto(coverImages, 0),
                  if (coverImages.length > 1)
                    Positioned(left: 28, child: _coverPhoto(coverImages, 1)),
                  if (coverImages.length > 2)
                    Positioned(left: 56, child: _coverPhoto(coverImages, 2)),
                ],
              ),
            ),
            title: Text(threadName, style: const TextStyle(fontSize: 17)),
            subtitle: Text(
              "${items.length} ${'memories'.tr}${items.length > 1 ? 's' : ''}",
              style: TextStyle(color: Colors.grey[600]),
            ),
            trailing: const Icon(Icons.chevron_right, color: Color(0xFFAE1B25)),
            onTap: () {
              Get.to(
                () => ByJourneyDetailsScreen(
                  journeyName: threadName,
                  memories: items,
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _coverPhoto(List<String> images, int index) {
    if (images.length <= index) return const SizedBox();
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          images[index],
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(color: Colors.grey[300]),
        ),
      ),
    );
  }
}

// Updated Grid Card with Multiple Photos Indicator
class _MemoryGridCard extends StatelessWidget {
  final MemoryItem memory;

  const _MemoryGridCard({required this.memory});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showMemoryDetailDialog(context, memory);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    memory.coverImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.broken_image,
                        size: 40,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                if (memory.hasMultiplePhotos)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.collections,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "+${memory.imagesCount - 1}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            memory.activityName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            memory.completedAt != null
                ? DateFormat('MMM d, yyyy').format(memory.completedAt!)
                : 'no_date'.tr,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          Text(
            "• ${memory.threadName}",
            style: TextStyle(color: Colors.grey[500], fontSize: 11),
          ),
        ],
      ),
    );
  }
}