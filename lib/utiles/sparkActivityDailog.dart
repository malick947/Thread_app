import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:the_read_thread/Controller/ThreadController.dart';
import 'package:the_read_thread/Model/sparkActivityModel.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class SparkActivityCompletionDialog extends StatefulWidget {
  final String threadId;
  final String activityId;
  final SparkActivityModel sparkActivity;

  const SparkActivityCompletionDialog({
    Key? key,
    required this.threadId,
    required this.activityId,
    required this.sparkActivity,
  }) : super(key: key);

  @override
  State<SparkActivityCompletionDialog> createState() =>
      _SparkActivityCompletionDialogState();
}

class _SparkActivityCompletionDialogState
    extends State<SparkActivityCompletionDialog> {
  final TextEditingController _memoryController = TextEditingController();
  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

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
        'Success! 🎉',
        'Spark activity completed and memory saved',
      backgroundColor: Color(0xFFAE1B25),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to complete activity: $e',
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
            'Error',
            'Failed to open link',
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
          'Error',
          'Failed to search',
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
            'Error',
            'Failed to open directions',
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
        return 'BOOK';
      case 'Craft':
        return 'GET SUPPLIES';
      case 'Free':
        return 'DIRECTIONS';
      default:
        return 'VIEW';
    }
  }

  @override
  Widget build(BuildContext context) {
    final spark = widget.sparkActivity;
    final hasLocation = spark.latitude != null && spark.longitude != null;
    final showMap =
        spark.category == 'Event' || (spark.category == 'Free' && hasLocation);
    final showDate = spark.category != 'Free'; // Show date for Event and Craft

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Container(
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      spark.activityName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Get.back(result: false),
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
                      'NOTE',
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
                  'LOCATION',
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
                  'DATE',
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

              Divider(),

              SizedBox(height: 16),

              // Memory Section
              Text(
                'Add Your Memory',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 12),

              TextField(
                controller: _memoryController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Describe your experience...',
                  filled: true,
                  fillColor: Color(0xFFF5F5F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              SizedBox(height: 16),

              // Image Selection
              if (_selectedImages.isNotEmpty) ...[
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedImages.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          Container(
                            margin: EdgeInsets.only(right: 8),
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: FileImage(_selectedImages[index]),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 12,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedImages.removeAt(index);
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                SizedBox(height: 16),
              ],

              OutlinedButton.icon(
                onPressed: _isUploading ? null : _pickImages,
                icon: Icon(Icons.add_photo_alternate),
                label: Text('Add Photos'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Color(0xFFAE1B25),
                  side: BorderSide(color: Color(0xFFAE1B25)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              SizedBox(height: 20),

              // Complete Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _completeActivity,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF28A745),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isUploading
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
                              'Uploading...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          'Complete Activity',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
