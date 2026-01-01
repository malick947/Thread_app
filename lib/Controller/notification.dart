import 'package:cloud_functions/cloud_functions.dart';

Future<void> sendNotification({
  required String token,
  required String title,
  required String body,
}) async {
  final callable = FirebaseFunctions.instance.httpsCallable('sendNotification');

  final result = await callable.call({
    'token': token,
    'title': title,
    'body': body,
  });

  print(result.data);
}
