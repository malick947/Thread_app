import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:the_read_thread/Controller/ThreadController.dart';
import 'package:the_read_thread/Model/sparkActivityModel.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// This dialog shows when clicking on a SPARK ACTIVITY CARD (not the checkbox)
/// It displays all spark details AND includes completion functionality
class SparkActivityDetailsDialog extends StatefulWidget {
  final String threadId;
  final String activityId;
  final SparkActivityModel sparkActivity;
  final bool isCompleted;

  const SparkActivityDetailsDialog({
    Key? key,
    required this.threadId,
    required this.activityId,
    required this.sparkActivity,
    this.isCompleted = false,
  }) : super(key: key);

  @override
  State<SparkActivityDetailsDialog> createState() =>
      _SparkActivityDetailsDialogState();
}

class _SparkActivityDetailsDialogState
    extends State<SparkActivityDetailsDialog> {
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
        'error'.tr,
        '${'failed_to_pick_images'.tr}: $e',
        backgroundColor: Color(0xFFAE1B25),
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
        'success'.tr,
        'spark_activity_completed_and_memory_saved'.tr,
        backgroundColor: Color(0xFFAE1B25),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        '${'failed_to_complete_activity'.tr}: $e',
        backgroundColor: Color(0xFFAE1B25),
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _openActionButton() async {
    final spark = widget.sparkActivity;

    if (spark.category == 'Event') {
      final url = spark.websiteUrl ?? spark.googleMapsUrl;
      if (url != null && url.isNotEmpty) {
        try {
          if (await canLaunch(url)) {
            await launch(url);
          }
        } catch (e) {
          Get.snackbar(
            'error'.tr,
            'failed_to_open_link'.tr,
            backgroundColor: Color(0xFFAE1B25),
            colorText: Colors.white,
          );
        }
      }
    } else if (spark.category == 'Craft') {
      final url = 'https://www.google.com/search?q=craft+supplies+near+me';
      try {
        if (await canLaunch(url)) {
          await launch(url);
        }
      } catch (e) {
        Get.snackbar(
          'error'.tr,
          'failed_to_search'.tr,
          backgroundColor: Color(0xFFAE1B25),
          colorText: Colors.white,
        );
      }
    } else if (spark.category == 'Free') {
      if (spark.latitude != null && spark.longitude != null) {
        final url =
            'https://www.google.com/maps/dir/?api=1&destination=${spark.latitude},${spark.longitude}';
        try {
          if (await canLaunch(url)) {
            await launch(url);
          }
        } catch (e) {
          Get.snackbar(
            'error'.tr,
            'failed_to_open_directions'.tr,
            backgroundColor: Color(0xFFAE1B25),
            colorText: Colors.white,
          );
        }
      }
    }
  }

  String _getActionButtonLabel() {
    switch (widget.sparkActivity.category) {
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

  @override
  Widget build(BuildContext context) {
    final spark = widget.sparkActivity;
    final hasLocation = spark.latitude != null && spark.longitude != null;
    final showMap =
        spark.category == 'Event' || (spark.category == 'Free' && hasLocation);
    final showDate = spark.category != 'Free';

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
              // Header with close button - FIXED
              Row(
                children: [
                  Text('🔥', style: TextStyle(fontSize: 20)),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      spark.activityName,
                      style: TextStyle(
                        fontSize: 18,
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

              // Category and Mood badges
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color(0xFFFFF5F5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      spark.category,
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFFAE1B25),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color(0xFFE6F7FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${'mood'.tr} ${spark.mood}',
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

              // NOTE Section
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'note'.tr,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      spark.suggestion,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16),

              // LOCATION Section (for Event and Free with location)
              if (showMap) ...[
                Text(
                  'location'.tr,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(spark.latitude!, spark.longitude!),
                        zoom: 15,
                      ),
                      markers: {
                        Marker(
                          markerId: MarkerId('spark_location'),
                          position: LatLng(spark.latitude!, spark.longitude!),
                          infoWindow: InfoWindow(
                            title: spark.placeName,
                            snippet: spark.vicinity,
                          ),
                        ),
                      },
                      zoomControlsEnabled: false,
                      myLocationButtonEnabled: false,
                    ),
                  ),
                ),
                if (spark.vicinity != null) ...[
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: Color(0xFFAE1B25),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            spark.vicinity!,
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                SizedBox(height: 16),
              ],

              // Rating and Reviews
              if (spark.rating != null) ...[
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 20),
                    SizedBox(width: 4),
                    Text(
                      '${spark.rating}',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (spark.userRatingsTotal != null) ...[
                      SizedBox(width: 4),
                      Text(
                        '(${spark.userRatingsTotal} reviews)',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 16),
              ],

              // Action Button (BOOK / GET SUPPLIES / DIRECTIONS)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _openActionButton,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFAE1B25),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _getActionButtonLabel(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 16),

              // DATE Section (only for Event and Craft)
              if (showDate) ...[
                Text(
                  'date'.tr,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  spark.createdAt.toString().split(' ')[0],
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
                SizedBox(height: 16),
              ],

              // If already completed, show completion status
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
                  child: Row(
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
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
