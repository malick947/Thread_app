import 'dart:async';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_read_thread/Controller/SnapController.dart';
import 'package:the_read_thread/Controller/countdown.dart';
import 'package:the_read_thread/Controller/friendsController.dart';
import 'package:the_read_thread/Services/TranslationService.dart';
import 'package:the_read_thread/Services/authCheckService.dart';
import 'package:the_read_thread/Services/notification_service.dart';
import 'package:the_read_thread/UI/landingScreen.dart';

import 'firebase_options.dart';

void printDebugToken() async {
  if (kDebugMode) {
    try {
      // Force refresh and get the token
      String? debugToken = await FirebaseAppCheck.instance.getToken(true);
      
      if (debugToken != null && debugToken.isNotEmpty) {
        print('══════════════════════════════════════════════════════════════');
        print('🔥 APP CHECK DEBUG TOKEN 🔥');
        print('Token: $debugToken');
        print('══════════════════════════════════════════════════════════════');
        
        // Show in Snackbar or Dialog for easy copying
        
      } else {
        print('No debug token received. Trying again in 2 seconds...');
        await Future.delayed(Duration(seconds: 2));
        
        // Try one more time
        debugToken = await FirebaseAppCheck.instance.getToken();
        if (debugToken != null) {
          print('Debug Token (second try): $debugToken');
        }
      }
    } catch (e) {
      print('Error getting debug token: $e');
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensures binding before Firebase initialization
  final prefs = await SharedPreferences.getInstance();
  final lang = prefs.getString('languageCode') ?? 'en';
  final country = prefs.getString('countryCode') ?? 'US';
  Get.updateLocale(Locale(lang, country));
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  
  
  await NotificationService().init();
  FirebaseMessaging.onBackgroundMessage(_BackgroundMessageHander);

  runApp(const MyApp());
}

@pragma('vm:entry-point')
Future<void> _BackgroundMessageHander(RemoteMessage message) async {
  await Firebase.initializeApp();
}




class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'The Read Thread',
      translations: AppTranslations(), // ← Your translations
    
      theme: ThemeData(
        textTheme: GoogleFonts.openSansTextTheme(Theme.of(context).textTheme),
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFFAE1B25)),
      ),
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Timer(Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AuthCheck()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/thread_logo.png'),
                  fit: BoxFit.cover, // or BoxFit.contain / BoxFit.fill
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              "The Red Thread",
              style: TextStyle(fontSize: 30, color: Color(0xFFAE1B25)),
            ),
          ],
        ),
      ),
    );
  }
}
