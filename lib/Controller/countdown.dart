import 'dart:async';
import 'package:get/get.dart';

class CountdownController extends GetxController {
  RxString remainingTime = "00:00:00".obs;

  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    startCountdown();
  }

  void startCountdown() {
    _updateRemainingTime();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemainingTime();
    });
  }

  void _updateRemainingTime() {
    DateTime now = DateTime.now();
    DateTime endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    Duration diff = endOfDay.difference(now);

    remainingTime.value =
        "${diff.inHours.toString().padLeft(2, '0')}:"
        "${(diff.inMinutes % 60).toString().padLeft(2, '0')}:"
        "${(diff.inSeconds % 60).toString().padLeft(2, '0')}";
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}
