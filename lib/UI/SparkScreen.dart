import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:the_read_thread/Controller/ThreadController.dart';
import 'package:the_read_thread/Controller/sparkController.dart';
import 'package:the_read_thread/Model/sparkActivityModel.dart';
import 'package:the_read_thread/Model/threadModel.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SparkScreen extends StatelessWidget {
  final SparkController controller = Get.put(SparkController());
  final ThreadController threadController = ThreadController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Color(0xFFAE1B25)),
                SizedBox(height: 16),
                Text(
                  'initializing'.tr,
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.only(bottom: 80),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Center(
                        child: Text(
                          'the_spark'.tr,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      Center(
                        child: Text(
                          'discover_your_next_adventure'.tr,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                AISparkGeneratorCard(controller: controller),

                SizedBox(height: 16),

                Obx(() {
                  if (controller.showSparkResult.value &&
                      controller.generatedSpark.value != null) {
                    return GeneratedSparkResultCard(
                      controller: controller,
                      result: controller.generatedSpark.value!,
                      onAddToJourney: () => _showThreadSelectionDialog(context),
                    );
                  }
                  return SizedBox.shrink();
                }),

                SizedBox(height: 20),
              ],
            ),
          ),
        );
      }),
      bottomSheet: Obx(() {
        final hasResult = controller.generatedSpark.value != null;

        return Container(
          color: Colors.white,
          padding: EdgeInsets.all(20),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton.icon(
              onPressed: hasResult ? () => controller.rerollSpark() : null,
              icon: Icon(Icons.refresh),
              label: Text('re_roll_spark'.tr),
              style: OutlinedButton.styleFrom(
                foregroundColor: Color(0xFFAE1B25),
                side: BorderSide(
                  color: hasResult ? Color(0xFFAE1B25) : Colors.grey[300]!,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Future<void> _showThreadSelectionDialog(BuildContext context) async {
    final spark = controller.generatedSpark.value;
    if (spark == null) return;

    Get.dialog(
      Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      final threadsStream = threadController.getUserThreads();
      final threads = await threadsStream.first;
      Get.back();

      if (threads.isEmpty) {
        Get.snackbar(
          'no_journeys'.tr,
          'create_a_journey_first_to_add_activities'.tr,
          backgroundColor: Color(0xFFAE1B25),
          colorText: Colors.white,
        );
        return;
      }

      Get.bottomSheet(
        ThreadSelectionBottomSheet(
          threads: threads,
          spark: spark,
          onThreadSelected: (thread) async =>
              await _addSparkToThread(thread, spark),
        ),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        isScrollControlled: true,
      );
    } catch (e) {
      Get.back();
      Get.snackbar(
        'error'.tr,
        '${'failed_to_load_journeys'.tr}: $e',
        backgroundColor: Color(0xFFAE1B25),
        colorText: Colors.white,
      );
    }
  }

  Future<void> _addSparkToThread(
    Thread thread,
    GeneratedSparkResult spark,
  ) async {
    try {
      Get.dialog(
        Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final activityId = FirebaseFirestore.instance
          .collection('threads')
          .doc(thread.id)
          .collection('Activities')
          .doc()
          .id;

      final sparkActivity = controller.createSparkActivityModel(
        activityId: activityId,
        threadId: thread.id,
        assignedTo: [threadController.currentUserId!],
        priority: 'medium',
      );

      if (sparkActivity == null) {
        throw Exception('Failed to create spark activity');
      }

      await FirebaseFirestore.instance
          .collection('threads')
          .doc(thread.id)
          .collection('Activities')
          .doc(activityId)
          .set(sparkActivity.toFirestore());

      await FirebaseFirestore.instance
          .collection('threads')
          .doc(thread.id)
          .update({'totalActivities': FieldValue.increment(1)});

      Get.back();
      Get.back();
      controller.clearSparkResult();

      Get.snackbar(
        'success'.tr,
        '${spark.place.name} ${'added_to'.tr} ${thread.name}',
        backgroundColor: Color(0xFFAE1B25),
        colorText: Colors.white,
        duration: Duration(seconds: 3),
      );
    } catch (e) {
      Get.back();
      Get.snackbar(
        'error'.tr,
        '${'failed_to_add_activity'.tr}: $e',
        backgroundColor: Color(0xFFAE1B25),
        colorText: Colors.white,
      );
      print('Error adding spark to thread: $e');
    }
  }
}

// AI Spark Generator Card Widget
class AISparkGeneratorCard extends StatefulWidget {
  final SparkController controller;

  const AISparkGeneratorCard({Key? key, required this.controller})
      : super(key: key);

  @override
  State<AISparkGeneratorCard> createState() => _AISparkGeneratorCardState();
}

class _AISparkGeneratorCardState extends State<AISparkGeneratorCard> {
  final TextEditingController locationController = TextEditingController();
  final TextEditingController moodController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Color(0xFFFFF5F5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Color(0xFFAE1B25).withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'activity_spark_generator'.tr,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFAE1B25),
                  ),
                ),
                SizedBox(width: 8),
              ],
            ),
            SizedBox(height: 4),
            Text(
              'leave_location_empty_to_use_current'.tr,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            SizedBox(height: 16),
            TextField(
              controller: locationController,
              decoration: InputDecoration(
                labelText: 'location_optional_uses_current'.tr,
                hintText: 'location_hint_example'.tr,
                prefixIcon: Icon(Icons.location_on, color: Color(0xFFAE1B25)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: moodController,
              decoration: InputDecoration(
                labelText: 'current_mood_vibe'.tr,
                hintText: 'mood_hint_example'.tr,
                prefixIcon: Icon(Icons.mood, color: Color(0xFFAE1B25)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: Obx(
                () => ElevatedButton(
                  onPressed: widget.controller.isGeneratingSpark.value
                      ? null
                      : () {
                          if (moodController.text.isEmpty) {
                            Get.snackbar(
                              'missing_information'.tr,
                              'please_enter_your_mood_vibe'.tr,
                              backgroundColor: Color(0xFFAE1B25),
                              colorText: Colors.white,
                            );
                            return;
                          }

                          final locationInput = locationController.text.trim();
                          if (locationInput.isEmpty &&
                              !widget.controller.locationEnabled.value) {
                            Get.snackbar(
                              'location_required'.tr,
                              'please_enter_location_or_enable_access'.tr,
                              backgroundColor: Color(0xFFAE1B25),
                              colorText: Colors.white,
                              duration: Duration(seconds: 4),
                            );
                            return;
                          }

                          widget.controller.generateAISpark(
                            locationInput,
                            moodController.text.trim(),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFAE1B25),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: widget.controller.isGeneratingSpark.value
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'generating'.tr,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          'generate_spark'.tr,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    locationController.dispose();
    moodController.dispose();
    super.dispose();
  }
}

// Generated Spark Result Card
class GeneratedSparkResultCard extends StatefulWidget {
  final SparkController controller;
  final GeneratedSparkResult result;
  final VoidCallback onAddToJourney;

  const GeneratedSparkResultCard({
    Key? key,
    required this.controller,
    required this.result,
    required this.onAddToJourney,
  }) : super(key: key);

  @override
  State<GeneratedSparkResultCard> createState() =>
      _GeneratedSparkResultCardState();
}

class _GeneratedSparkResultCardState extends State<GeneratedSparkResultCard> {
  late GoogleMapController mapController;
  final Set<Marker> markers = {};

  @override
  void initState() {
    super.initState();
    final place = widget.result.place;
    if (place.lat != null && place.lng != null) {
      markers.add(
        Marker(
          markerId: MarkerId('spark_location'),
          position: LatLng(place.lat!, place.lng!),
          infoWindow: InfoWindow(
            title: place.name,
            snippet: place.vicinity ?? 'location_not_available'.tr,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }
  }

  void _openActionButton() async {
    final category = widget.result.category;
    final place = widget.result.place;

    if (category == 'Event') {
      final url = widget.result.websiteUrl ?? place.googleMapsUrl;
      if (url != null && url.isNotEmpty) {
        try {
          if (await canLaunch(url)) {
            await launch(url);
          } else {
            Get.snackbar(
              'error'.tr,
              'cannot_open_link'.tr,
              backgroundColor: Color(0xFFAE1B25),
              colorText: Colors.white,
            );
          }
        } catch (e) {
          Get.snackbar(
            'error'.tr,
            '${'failed_to_open_link'.tr}: $e',
            backgroundColor: Color(0xFFAE1B25),
            colorText: Colors.white,
          );
        }
      } else {
        Get.snackbar(
          'info'.tr,
          'no_booking_link_available'.tr,
          backgroundColor: Color(0xFFAE1B25),
          colorText: Colors.white,
        );
      }
    } else if (category == 'Craft') {
      final searchQuery = Uri.encodeComponent('craft supplies near me');
      final url = 'https://www.google.com/search?q=$searchQuery';
      try {
        if (await canLaunch(url)) {
          await launch(url);
        }
      } catch (e) {
        Get.snackbar(
          'error'.tr,
          '${'failed_to_search'.tr}: $e',
          backgroundColor: Color(0xFFAE1B25),
          colorText: Colors.white,
        );
      }
    } else if (category == 'Free') {
      if (place.lat != null && place.lng != null) {
        final url =
            'https://www.google.com/maps/dir/?api=1&destination=${place.lat},${place.lng}';
        try {
          if (await canLaunch(url)) {
            await launch(url);
          }
        } catch (e) {
          Get.snackbar(
            'error'.tr,
            '${'failed_to_open_directions'.tr}: $e',
            backgroundColor: Color(0xFFAE1B25),
            colorText: Colors.white,
          );
        }
      } else {
        Get.snackbar(
          'error'.tr,
          'location_not_available'.tr,
          backgroundColor: Color(0xFFAE1B25),
          colorText: Colors.white,
        );
      }
    }
  }

  String _getActionButtonLabel() {
    switch (widget.result.category) {
      case 'Event':
        return 'book'.tr;
      case 'Craft':
        return 'get_supplies'.tr;
      case 'Free':
        return 'directions'.tr;
      default:
        return 'view'.tr;
    }
  }

  IconData _getActionButtonIcon() {
    switch (widget.result.category) {
      case 'Event':
        return Icons.event_available;
      case 'Craft':
        return Icons.shopping_bag;
      case 'Free':
        return Icons.directions;
      default:
        return Icons.open_in_browser;
    }
  }

  @override
  Widget build(BuildContext context) {
    final place = widget.result.place;
    final hasLocation = place.lat != null && place.lng != null;
    final hasReviews =
        widget.result.reviews != null && widget.result.reviews!.isNotEmpty;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        margin: EdgeInsets.only(bottom: 20),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Color(0xFFAE1B25), width: 3),
          boxShadow: [
            BoxShadow(
              color: Color(0xFFAE1B25).withOpacity(0.2),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'your_activity_spark'.tr,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFAE1B25),
                  ),
                ),
                SizedBox(width: 8),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.grey),
                  onPressed: () => widget.controller.clearSparkResult(),
                ),
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(0xFFFFF5F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${widget.result.category}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFFAE1B25),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(0xFFE6F7FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${'mood'.tr} ${widget.result.mood}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF1E88E5),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'suggestion'.tr,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              widget.result.suggestion,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 16),

            Container(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _openActionButton,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1E88E5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(_getActionButtonIcon(), color: Colors.white),
                label: Text(
                  _getActionButtonLabel(),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            SizedBox(height: 12),

            Container(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: widget.onAddToJourney,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFAE1B25),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(Icons.add_task, color: Colors.white),
                label: Text(
                  'add_to_journey'.tr,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            SizedBox(height: 16),
            Divider(),
            SizedBox(height: 8),
            Text(
              'location_details'.tr,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),

            if (hasLocation && widget.result.category != 'Craft') ...[
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(place.lat!, place.lng!),
                      zoom: 15,
                    ),
                    markers: markers,
                    mapType: MapType.normal,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    zoomControlsEnabled: true,
                    onMapCreated: (GoogleMapController controller) {
                      mapController = controller;
                    },
                  ),
                ),
              ),
              SizedBox(height: 16),
            ],

            Row(
              children: [
                Icon(Icons.location_on, color: Color(0xFFB91C1C), size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        place.vicinity ?? 'address_not_available'.tr,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                if (place.rating != null) ...[
                  Icon(Icons.star, color: Colors.amber, size: 20),
                  SizedBox(width: 4),
                  Text(
                    '${place.rating}',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (place.userRatingsTotal != null) ...[
                    SizedBox(width: 4),
                    Text(
                      '(${place.userRatingsTotal})',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                  SizedBox(width: 8),
                ],
                if (place.priceLevel != null &&
                    place.priceLevel!.isNotEmpty) ...[
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Text(
                      place.getPriceLevelDisplay(),
                      style: TextStyle(
                        color: Colors.green[800],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),

            if (hasReviews) ...[
              SizedBox(height: 16),
              Divider(),
              SizedBox(height: 8),
              Text(
                'reviews'.tr,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              ...widget.result.reviews!.take(2).map((review) {
                return Container(
                  margin: EdgeInsets.only(bottom: 12),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            review.authorName,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Spacer(),
                          Row(
                            children: [
                              Icon(Icons.star, color: Colors.amber, size: 16),
                              SizedBox(width: 4),
                              Text('${review.rating}'),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        review.text,
                        style: TextStyle(fontSize: 13),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (review.relativeTimeDescription != null) ...[
                        SizedBox(height: 4),
                        Text(
                          review.relativeTimeDescription!,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }
}

// Thread Selection Bottom Sheet
class ThreadSelectionBottomSheet extends StatelessWidget {
  final List<Thread> threads;
  final GeneratedSparkResult spark;
  final Function(Thread) onThreadSelected;

  const ThreadSelectionBottomSheet({
    Key? key,
    required this.threads,
    required this.spark,
    required this.onThreadSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'add_to_journey'.tr,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      spark.place.name,
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              IconButton(icon: Icon(Icons.close), onPressed: () => Get.back()),
            ],
          ),
          SizedBox(height: 20),
          Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: threads.length,
              itemBuilder: (context, index) {
                final thread = threads[index];
                return Card(
                  margin: EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(12),
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: _getThreadColor(thread.type),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _getThreadIcon(thread.type),
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      thread.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 4),
                        Text(
                          thread.description.isEmpty
                              ? 'no_description'.tr
                              : thread.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.task_alt, size: 14, color: Colors.grey),
                            SizedBox(width: 4),
                            Text(
                              '${thread.completedActivities}/${thread.totalActivities}',
                              style: TextStyle(fontSize: 12),
                            ),
                            SizedBox(width: 12),
                            Icon(Icons.people, size: 14, color: Colors.grey),
                            SizedBox(width: 4),
                            Text(
                              '${thread.members.length}',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => onThreadSelected(thread),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getThreadColor(String type) {
    switch (type.toLowerCase()) {
      case 'solo':
        return Color(0xFF3B82F6);
      case 'dual':
        return Color(0xFF8B5CF6);
      case 'group':
        return Color(0xFFEC4899);
      default:
        return Color(0xFF6B7280);
    }
  }

  IconData _getThreadIcon(String type) {
    switch (type.toLowerCase()) {
      case 'solo':
        return Icons.person;
      case 'dual':
        return Icons.people;
      case 'group':
        return Icons.groups;
      default:
        return Icons.fiber_dvr;
    }
  }
}