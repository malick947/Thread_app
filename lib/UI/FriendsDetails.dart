import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:the_read_thread/Controller/friendsController.dart';
import 'package:the_read_thread/Model/UserModel.dart';

class FriendDetailsScreen extends StatelessWidget {
  final UserModel friend;
  FriendDetailsScreen({required this.friend});

  final FriendsController controller = Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(" ")),
      body: FutureBuilder(
        future: controller.getSharedThreads(friend.id!),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final sharedThreads = snapshot.data as List<DocumentSnapshot>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Friend Image Placeholder
                Center(
                  child: CircleAvatar(
                    radius: 40,
                    child: Text(
                      friend.name![0].toUpperCase(),
                      style: const TextStyle(fontSize: 26),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                Center(
                  child: Text(
                    friend.name ?? "",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 30),
                Text(
                  'shared_threads'.tr,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                ...sharedThreads.map((thread) {
                  return FutureBuilder(
                    future: controller.getSharedActivitiesForThread(thread.id),
                    builder: (context, actSnap) {
                      int memoryCount = actSnap.data?.length ?? 0;

                      return ListTile(
                        leading: const Icon(Icons.people_alt),
                        title: Text(thread["name"]),
                        subtitle: Text('$memoryCount ${'memories'.tr}'),
                      );
                    },
                  );
                }).toList(),

                const SizedBox(height: 30),

                Text(
                  'shared_memories'.tr,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                FutureBuilder(
                  future: controller.getAllSharedActivities(friend.id!),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final allActivities =
                        snapshot.data as List<Map<String, dynamic>>;

                    List<String> allImages = [];
                    for (var a in allActivities) {
                      List imgs = a["activity"]["imagesURL"] ?? [];
                      allImages.addAll(imgs.cast<String>());
                    }

                    if (allImages.isEmpty) {
                      return Text('no_shared_images_found'.tr);
                    }

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: allImages.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                      ),
                      itemBuilder: (context, index) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            allImages[index],
                            fit: BoxFit.cover,
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}