import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:the_read_thread/Controller/SnapController.dart';
import 'package:the_read_thread/Controller/countdown.dart';
import 'package:the_read_thread/Controller/friendsController.dart';
import 'package:the_read_thread/UI/SnapPreview.dart';
import 'package:the_read_thread/UI/SnapPreviewScreen.dart';

class SnapsScreen extends StatelessWidget {
  const SnapsScreen({super.key});

  String formatTime(DateTime dt) {
    return DateFormat('h:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    Get.put(FriendsController());
    Get.put(SnapsController());
    final countdown = Get.put(CountdownController());

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: () async {
          await Get.find<SnapsController>().refreshSnaps();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Center(
                child: Text(
                  "snaps".tr,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 6),
               Center(
                child: Text(
                  "the_shared_moment".tr,
                  style: TextStyle(color: Colors.grey),
                ),
              ),

              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Color(0xFFAE1B25),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'todays_challenge'.tr,
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'snap_something_that_made_you_smile'.tr,
                      style: TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 18),
                    Obx(
                      () => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'time_remaining'.tr,
                              style: TextStyle(color: Colors.white),
                            ),
                            Text(
                              countdown.remainingTime.value,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),

              GestureDetector(
                onTap: () => _showSnapSourceSelector(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFFAE1B25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt_outlined, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'capture_my_snap'.tr,
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 22),

              Text(
                'friends_snaps'.tr,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              GetX<SnapsController>(
                builder: (ctrl) {
                  if (ctrl.isLoading.value && ctrl.snaps.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (ctrl.snaps.isEmpty) {
                    return Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Center(
                        child: Text(
                          'no_snaps_yet_be_first'.tr,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    );
                  }

                  final myId = Get.find<FriendsController>().currentUserId;

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: ctrl.snaps.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.75,
                    ),
                    itemBuilder: (_, i) {
                      final snap = ctrl.snaps[i];

                      return GestureDetector(
                        onTap: () =>
                            Get.to(() => SnapPreviewScreen(snap: snap)),
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    snap.photoUrl,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                      if (loadingProgress == null)
                                        return child;
                                      return Container(
                                        width: 100,
                                        height: 100,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 100,
                                        height: 100,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: const Icon(Icons.broken_image),
                                      );
                                    },
                                  ),
                                ),

                                if (snap.userId == myId)
                                  Positioned(
                                    right: 4,
                                    top: 4,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Color(0xFFAE1B25),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'you'.tr,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),

                            const SizedBox(height: 4),

                            Text(
                              snap.username,
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            Text(
                              formatTime(snap.createdAt),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _showSnapSourceSelector(BuildContext context) {
  final snapsCtrl = Get.find<SnapsController>();

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text('take_photo'.tr),
              onTap: () {
                Navigator.pop(context);
                snapsCtrl.pickSnap(fromGallery: false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo),
              title: Text('choose_from_gallery'.tr),
              onTap: () {
                Navigator.pop(context);
                snapsCtrl.pickSnap(fromGallery: true);
              },
            ),
          ],
        ),
      );
    },
  );
}