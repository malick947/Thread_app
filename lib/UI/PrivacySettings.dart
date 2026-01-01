import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PrivacySettings extends StatelessWidget {
  const PrivacySettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('privacy_policy'.tr),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === Header ===
            Text(
              'privacy_policy'.tr,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'last_updated_dec_8_2025'.tr,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'privacy_intro'.tr,
              style: TextStyle(
                fontSize: 16,
                height: 1.7,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 32),

            // === Section 1 ===
            _sectionTitle('data_we_collect'.tr),
            _dataCard(
              title: 'account_identity'.tr,
              items: 'account_identity_items'.tr,
              purpose: 'account_identity_purpose'.tr,
            ),
            _dataCard(
              title: 'collaborative_content'.tr,
              items: 'collaborative_content_items'.tr,
              purpose: 'collaborative_content_purpose'.tr,
            ),
            _dataCard(
              title: 'usage_analytics'.tr,
              items: 'usage_analytics_items'.tr,
              purpose: 'usage_analytics_purpose'.tr,
            ),
            _dataCard(
              title: 'ai_prompts_spark'.tr,
              items: 'ai_prompts_spark_items'.tr,
              purpose: 'ai_prompts_spark_purpose'.tr,
            ),

            const SizedBox(height: 32),

            // === Section 2 ===
            _sectionTitle('data_sharing'.tr),
            _highlightBox(
              'no_sell_data'.tr,
              'data_sharing_details'.tr,
            ),

            const SizedBox(height: 32),

            // === Section 3 ===
            _sectionTitle('location_access'.tr),
            _highlightBox(
              'no_track_location'.tr,
              'location_access_details'.tr,
            ),

            const SizedBox(height: 32),

            // === Section 4 - Critical Safety Notice ===
            _sectionTitle(
              'safety_responsibility'.tr,
              color: const Color(0xFFE74C3C),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F0),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFAE1B25), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children:  [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFAE1B25),
                        size: 28,
                      ),
                      SizedBox(width: 10),
                      Text(
                        "important_safety_notice".tr,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFAE1B25),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'safety_notice_details'.tr,
                    style: TextStyle(fontSize: 15.5, height: 1.7),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // === Section 5 ===
            _sectionTitle('security'.tr),
            _infoText('security_details'.tr),

            const SizedBox(height: 40),

            // === Contact ===
            _sectionTitle('contact_us'.tr),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFFAE1B25).withOpacity(0.1),
                    child: const Icon(
                      Icons.email_outlined,
                      color: Color(0xFFAE1B25),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'contact_email'.tr,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'contact_message'.tr,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.bold,
          color: color ?? Colors.black87,
        ),
      ),
    );
  }

  Widget _dataCard({
    required String title,
    required String items,
    required String purpose,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(items, style: const TextStyle(height: 1.6)),
          const SizedBox(height: 10),
          Text(
            purpose,
            style: TextStyle(
              color: Colors.grey[700],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _highlightBox(String highlight, String description) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFAE1B25).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 16,
            height: 1.7,
            color: Colors.black87,
          ),
          children: [
            TextSpan(
              text: "$highlight ",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFFAE1B25),
                fontSize: 17,
              ),
            ),
            TextSpan(text: description),
          ],
        ),
      ),
    );
  }

  Widget _infoText(String text) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10),
        ],
      ),
      child: Text(text, style: const TextStyle(fontSize: 15.5, height: 1.7)),
    );
  }
}