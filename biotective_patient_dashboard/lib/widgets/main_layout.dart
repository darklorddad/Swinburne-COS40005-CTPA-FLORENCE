import 'package:flutter/material.dart';
import '../screens/overview.dart';
import '../screens/chatbot.dart';
import '../screens/profile.dart';
import '../screens/auth/front_page.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  // A variable to keep track of the currently selected screen
  int _selectedIndex = 0;

  // A list of the screens to navigate between
  static const List<Widget> _screens = <Widget>[
    OverviewScreen(),
    ChatbotScreen(),
    ProfileScreen(),
  ];

  // Function to handle navigation button taps
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Remove the individual AppBars from each screen
    // and manage a single, centralized AppBar here.
    return Scaffold(
      appBar: _buildAppBar(),
      body: IndexedStack(
        // IndexedStack keeps all screens in the widget tree, preserving their state
        index: _selectedIndex,
        children: _screens,
      ),
    );
  }

  // The main, shared AppBar for the entire application
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          color: Colors.grey[900],
          child: const Center(child: Text('LOGO')),
        ),
      ),
      leadingWidth: 70,
      title: Row(
        children: [
          const Text('BioTective Care'),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildNavButton('Overview', Icons.bar_chart, 0),
                _buildNavButton('Chatbot', Icons.chat_bubble_outline, 1),
                _buildNavButton('Profile', Icons.person, 2),
              ],
            ),
          ),
        ],
      ),
      centerTitle: false,
      actions: [
        Row(
          children: [
            IconButton(icon: Icon(Icons.notifications_none), onPressed: () {}),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Chip(label: Row(children: [Text('PROFILE')])),
            ),
            IconButton(icon: Icon(Icons.logout), onPressed: () {
              // Show a confirmation dialog before logging out
        showDialog(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: const Text('Confirm Logout'),
              content: const Text('Are you sure you want to log out?'),
              actions: <Widget>[
                // "Cancel" button
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    // Just close the dialog
                    Navigator.of(dialogContext).pop();
                  },
                ),
                // "Logout" button
                TextButton(
                  child: const Text('Logout'),
                  onPressed: () {
                    // This is the core navigation logic.
                    // It pushes the FrontPage and removes all routes behind it.
                    Navigator.of(dialogContext).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const FrontPage()),
                      (Route<dynamic> route) => false,
                    );
                  },
                ),
              ],
            );
          },
        );
            },
            ),
            SizedBox(width: 20),
          ],
        ),
      ],
    );
  }

  // The navigation button now takes an index to control the state
  Widget _buildNavButton(String title, IconData icon, int index) {
    final bool isActive = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: TextButton.icon(
        style: TextButton.styleFrom(
          backgroundColor: isActive ? Colors.grey[200] : Colors.transparent,
          foregroundColor: Colors.black87,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () => _onItemTapped(index),
        icon: Icon(icon, size: 18),
        label: Text(title),
      ),
    );
  }
}
