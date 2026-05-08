import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthService>(context, listen: false);
    final response = await http.get(Uri.parse('${AuthService.baseUrl}/notifications/'), headers: auth.authHeaders);
    if (response.statusCode == 200) setState(() => _notifications = jsonDecode(response.body));
    setState(() => _isLoading = false);
  }

  Future<void> _markRead(int id) async {
    final auth = Provider.of<AuthService>(context, listen: false);
    await http.post(Uri.parse('${AuthService.baseUrl}/notifications/$id/read/'), headers: auth.authHeaders);
    _fetchNotifications();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_notifications.isEmpty) return const Center(child: Text('No notifications yet.'));
    return RefreshIndicator(
      onRefresh: _fetchNotifications,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _notifications.length,
        itemBuilder: (_, i) {
          final n = _notifications[i];
          return Card(
            child: ListTile(
              leading: Icon(n['read'] == true ? Icons.notifications_none : Icons.notifications_active, color: const Color(0xFF6750A4)),
              title: Text(n['title'] ?? ''),
              subtitle: Text('${n['society_name'] ?? ''}\n${n['message'] ?? ''}'),
              isThreeLine: true,
              trailing: n['read'] == true ? null : TextButton(onPressed: () => _markRead(n['id']), child: const Text('Read')),
            ),
          );
        },
      ),
    );
  }
}
