import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'chat_screen.dart';

class MySocietiesScreen extends StatefulWidget {
  const MySocietiesScreen({super.key});

  @override
  State<MySocietiesScreen> createState() => _MySocietiesScreenState();
}

class _MySocietiesScreenState extends State<MySocietiesScreen> {
  List _memberships = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMemberships();
  }

  Future<void> _fetchMemberships() async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthService>(context, listen: false);
    try {
      final response = await http.get(Uri.parse('${AuthService.baseUrl}/my-societies/'), headers: auth.authHeaders);
      if (response.statusCode == 200) setState(() => _memberships = jsonDecode(response.body));
    } catch (e) {
      debugPrint('Error fetching memberships: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _leaveSociety(int societyId, String name) async {
    final auth = Provider.of<AuthService>(context, listen: false);
    await http.post(Uri.parse('${AuthService.baseUrl}/societies/$societyId/leave/'), headers: auth.authHeaders);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Left $name. Notifications for this society stopped.')));
    _fetchMemberships();
  }

  Future<void> _toggleNotifications(int societyId, bool current) async {
    final auth = Provider.of<AuthService>(context, listen: false);
    await http.patch(
      Uri.parse('${AuthService.baseUrl}/societies/$societyId/notification-preference/'),
      headers: auth.authHeaders,
      body: jsonEncode({'notifications_enabled': !current}),
    );
    _fetchMemberships();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _fetchMemberships,
      child: _memberships.isEmpty
          ? ListView(
              children: const [
                SizedBox(height: 200),
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.groups_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('You have not joined any societies yet.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                      SizedBox(height: 8),
                      Text('Go to Discover to find and join societies!', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _memberships.length,
              itemBuilder: (_, i) {
                final membership = _memberships[i];
                final society = membership['society'];
                final notifications = membership['notifications_enabled'] ?? true;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(radius: 28, backgroundColor: const Color(0xFF6750A4), child: Text(society['name'][0], style: const TextStyle(color: Colors.white, fontSize: 22))),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(society['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text('${society['category']} • ${society['member_count']} members', style: const TextStyle(color: Colors.grey)),
                                  if ((society['meeting_location'] ?? '').toString().isNotEmpty) Text('Meets at: ${society['meeting_location']}', style: const TextStyle(color: Colors.grey)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          value: notifications,
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Event notifications for this society'),
                          onChanged: (_) => _toggleNotifications(society['id'], notifications),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.chat),
                              label: const Text('Chat'),
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(societyId: society['id'], societyName: society['name']))),
                            ),
                            TextButton(
                              onPressed: () => _leaveSociety(society['id'], society['name']),
                              child: const Text('Leave', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
