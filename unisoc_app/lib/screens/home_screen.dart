import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'societies_screen.dart';
import 'my_societies_screen.dart';
import 'events_screen.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';
import 'admin_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final screens = <Widget>[
      const SocietiesScreen(),
      const MySocietiesScreen(),
      const EventsScreen(),
      const NotificationsScreen(),
      const SettingsScreen(),
      if (auth.isAdmin) const AdminScreen(),
    ];
    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Discover'),
      const BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'My Societies'),
      const BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Events'),
      const BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Alerts'),
      const BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
      if (auth.isAdmin) const BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: 'Admin'),
    ];

    if (_currentIndex >= screens.length) _currentIndex = 0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6750A4),
        foregroundColor: Colors.white,
        title: Text('UniSoc${auth.isAdmin ? ' Admin' : ''}'),
        actions: [
          Row(
            children: [
              const Icon(Icons.person, size: 18),
              const SizedBox(width: 4),
              Text(auth.username ?? '', style: const TextStyle(fontSize: 14)),
              IconButton(icon: const Icon(Icons.logout), onPressed: () => auth.logout(), tooltip: 'Logout'),
            ],
          ),
        ],
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: const Color(0xFF6750A4),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: items,
      ),
    );
  }
}
