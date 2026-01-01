import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:the_read_thread/Controller/SnapController.dart';

class SnapPreviewAndUpload extends StatelessWidget {
  final String imagePath;
  final Future<void> Function(String) onUpload;
  final String? existingSnapId;

  const SnapPreviewAndUpload({
    Key? key,
    required this.imagePath,
    required this.onUpload,
    this.existingSnapId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          existingSnapId != null ? 'replace_snap'.tr : 'new_snap'.tr,
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFFAE1B25),
      ),
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.file(File(imagePath), fit: BoxFit.contain),
          ),

          // Button at bottom center
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFAE1B25),
                  minimumSize: Size(200, 50),
                ),
                onPressed: () => onUpload(imagePath),
                child: Text(
                  existingSnapId != null ? 'replace_snap'.tr : 'post_snap'.tr,
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}