import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NotificationsSettings extends StatelessWidget {
  const NotificationsSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('notifications'.tr),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: Text('push_notifications'.tr),
            subtitle: Text('receive_alerts_new_threads_messages'.tr),
            value: true,
            onChanged: (val) {},
          ),
          SwitchListTile(
            title: Text('new_thread_invites'.tr),
            value: true,
            onChanged: (val) {},
          ),
          SwitchListTile(
            title: Text('memory_reminders'.tr),
            value: false,
            onChanged: (val) {},
          ),
        ],
      ),
    );
  }
}