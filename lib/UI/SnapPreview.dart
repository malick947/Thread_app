import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:the_read_thread/Controller/SnapController.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gal/gal.dart';
import 'package:the_read_thread/Model/snapModel.dart';

class SnapPreviewScreen extends StatelessWidget {
  final SnapModel snap;

  const SnapPreviewScreen({super.key, required this.snap});

  // -----------------------------
  // SHARE SNAP (Image + Text)
  // -----------------------------
  Future<void> _shareSnap(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    try {
      final String formattedTime = DateFormat(
        'h:mm a, MMM d yyyy',
      ).format(snap.createdAt);

      final String message = """
📸 *${'shared_snap'.tr}*

${'user_label'.tr} ${snap.username}
${'time_label'.tr} $formattedTime

${'shared_via_footer'.tr}
""";

      print("Starting image download from: ${snap.photoUrl}");

      final response = await http
          .get(Uri.parse(snap.photoUrl))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception(
          "Failed to download image (HTTP ${response.statusCode})",
        );
      }

      print(
        "Image downloaded successfully (${response.bodyBytes.length} bytes)",
      );

      final tempDir = await getTemporaryDirectory();
      final filePath =
          '${tempDir.path}/snap_share_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      print("Image saved to temp: $filePath");

      if (context.mounted) Navigator.pop(context);

      final result = await Share.shareXFiles(
        [XFile(filePath)],
        text: message,
        subject: 'shared_snap_subject'.tr,
      );

      print("Share result: ${result.status}");

      if (result.status == ShareResultStatus.dismissed) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('share_cancelled'.tr)),
          );
        }
      }
    } catch (e, stack) {
      print("ERROR sharing snap: $e");
      print(stack);

      if (context.mounted) Navigator.pop(context);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'failed_to_share'.tr}: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }

  // -----------------------------
  // SAVE TO GALLERY (using Gal)
  // -----------------------------
  Future<void> _saveToGallery(BuildContext context) async {
    if (!await Gal.hasAccess()) {
      final granted = await Gal.requestAccess();
      if (!granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('gallery_permission_denied'.tr),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    try {
      final response = await http.get(Uri.parse(snap.photoUrl));
      if (response.statusCode != 200) {
        throw Exception("Download failed");
      }

      final tempDir = await getTemporaryDirectory();
      final filePath =
          '${tempDir.path}/snap_gallery_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      await Gal.putImage(filePath);

      if (context.mounted) Navigator.pop(context);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('snap_saved_to_gallery'.tr),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'save_failed'.tr}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // -----------------------------
  // SHOW MORE OPTIONS MENU
  // -----------------------------
  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.share, color: Colors.white),
                title: Text(
                  'share_snap'.tr,
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _shareSnap(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.download, color: Colors.white),
                title: Text(
                  'save_to_gallery'.tr,
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _saveToGallery(context);
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () => _showMoreOptions(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Image.network(
                snap.photoUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const CircularProgressIndicator(color: Colors.white);
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.error, color: Colors.red, size: 60);
                },
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      snap.username[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      snap.username,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    Text(
                      DateFormat('h:mm a').format(snap.createdAt),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}