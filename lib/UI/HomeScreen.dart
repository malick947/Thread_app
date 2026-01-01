import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:the_read_thread/Controller/ProfileController.dart';
import 'package:the_read_thread/UI/FriendsDetails.dart';
import 'package:the_read_thread/UI/MemoriesScreen.dart';
import 'package:the_read_thread/UI/MyFriendsScreen.dart';
import 'package:the_read_thread/UI/ProfileScreen.dart';
import 'package:the_read_thread/UI/SnapScreen.dart';
import 'package:the_read_thread/UI/SparkScreen.dart';
import 'package:the_read_thread/UI/ThreadScreen.dart';
import 'package:the_read_thread/UI/moviesScreen.dart';

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    ThreadsScreen(),
    MemoriesScreen(),
    SparkScreen(),
    MoviesScreen(),
    SnapsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: const Text(
          ' ',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C3E50),
          ),
        ),
        // backgroundColor: const Color.fromARGB(255, 117, 102, 102),
        elevation: 0,
        actions: [
          CircleAvatar(
            backgroundColor: Color(0xFFE8EAF0),
            child: IconButton(
              icon: const Icon(Icons.group_outlined, color: Color(0xFF2C3E50)),
              onPressed: () {
                // Add friend action
                Get.to(
                  MyFriendsScreen(),
                  transition: Transition.fadeIn,
                  duration: Duration(microseconds: 400),
                );
              },
            ),
          ),
          SizedBox(width: 10),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: CircleAvatar(
              backgroundColor: Color(0xFFE8EAF0),
              child: IconButton(
                icon: const Icon(
                  Icons.person_outlined,
                  color: Color(0xFF2C3E50),
                ),
                onPressed: () async {
                  final controller = Get.put(ProfileController());

                  await controller.fetchCurrentUserProfile(); // wait for data

                  Get.to(
                    () => ProfileScreen(),
                    transition: Transition.fadeIn,
                    duration: const Duration(milliseconds: 400),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: SafeArea(
        top: false, // Important: don't apply top safe area here
        child: Container(
          color: Colors.white,
          child: BottomNavigationBar(
            backgroundColor: Colors.white,
            currentIndex: _currentIndex,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: const Color(0xFFAE1B25),
            unselectedItemColor: Colors.black87,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.layers_outlined),
                label: 'Threads',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.photo_camera_outlined),
                label: 'Memories',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.lightbulb_outline),
                label: 'Spark',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.local_movies_outlined),
                label: 'Movies',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.whatshot_outlined),
                label: 'Snaps',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Separate screens for each tab (You can later design them individually)
