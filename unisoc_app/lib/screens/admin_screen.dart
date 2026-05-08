import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List _societies = [];
  List _events = [];
  List _logs = [];
  bool _isLoading = true;

  final _societyName = TextEditingController();
  final _societyDescription = TextEditingController();
  final _societyLocation = TextEditingController();
  final _societyEmail = TextEditingController();
  String _societyCategory = 'extracurricular';

  final _eventTitle = TextEditingController();
  final _eventDescription = TextEditingController();
  final _eventLocation = TextEditingController();
  final _eventCapacity = TextEditingController();
  int? _eventSocietyId;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthService>(context, listen: false);
    final societies = await http.get(Uri.parse('${AuthService.baseUrl}/societies/'), headers: auth.authHeaders);
    final events = await http.get(Uri.parse('${AuthService.baseUrl}/events/?all=true'), headers: auth.authHeaders);
    final logs = await http.get(Uri.parse('${AuthService.baseUrl}/admin/audit-logs/'), headers: auth.authHeaders);
    if (societies.statusCode == 200) _societies = jsonDecode(societies.body);
    if (events.statusCode == 200) _events = jsonDecode(events.body);
    if (logs.statusCode == 200) _logs = jsonDecode(logs.body);
    if (_societies.isNotEmpty) _eventSocietyId ??= _societies.first['id'];
    setState(() => _isLoading = false);
  }

  Future<void> _createSociety() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    await http.post(
      Uri.parse('${AuthService.baseUrl}/societies/'),
      headers: auth.authHeaders,
      body: jsonEncode({
        'name': _societyName.text.trim(),
        'description': _societyDescription.text.trim(),
        'category': _societyCategory,
        'meeting_location': _societyLocation.text.trim(),
        'contact_email': _societyEmail.text.trim(),
      }),
    );
    _societyName.clear();
    _societyDescription.clear();
    _societyLocation.clear();
    _societyEmail.clear();
    _loadAdminData();
  }

  Future<void> _updateSociety(dynamic society) async {
    final auth = Provider.of<AuthService>(context, listen: false);
    await http.patch(
      Uri.parse('${AuthService.baseUrl}/societies/${society['id']}/'),
      headers: auth.authHeaders,
      body: jsonEncode({'description': '${society['description'] ?? ''}\nUpdated by admin.'}),
    );
    _loadAdminData();
  }

  Future<void> _createEvent() async {
    if (_eventSocietyId == null) return;
    final auth = Provider.of<AuthService>(context, listen: false);
    final now = DateTime.now().toUtc().add(const Duration(days: 7));
    final end = now.add(const Duration(hours: 2));
    await http.post(
      Uri.parse('${AuthService.baseUrl}/events/create/'),
      headers: auth.authHeaders,
      body: jsonEncode({
        'society': _eventSocietyId,
        'title': _eventTitle.text.trim(),
        'description': _eventDescription.text.trim(),
        'location': _eventLocation.text.trim(),
        'start_time': now.toIso8601String(),
        'end_time': end.toIso8601String(),
        'capacity_limit': int.tryParse(_eventCapacity.text.trim()),
        'is_public': true,
      }),
    );
    _eventTitle.clear();
    _eventDescription.clear();
    _eventLocation.clear();
    _eventCapacity.clear();
    _loadAdminData();
  }

  Future<void> _deleteEvent(int id) async {
    final auth = Provider.of<AuthService>(context, listen: false);
    await http.delete(Uri.parse('${AuthService.baseUrl}/events/$id/delete/'), headers: auth.authHeaders);
    _loadAdminData();
  }

  Future<void> _quickEditEvent(dynamic event) async {
    final auth = Provider.of<AuthService>(context, listen: false);
    await http.patch(
      Uri.parse('${AuthService.baseUrl}/events/${event['id']}/edit/'),
      headers: auth.authHeaders,
      body: jsonEncode({'description': '${event['description'] ?? ''}\nUpdated event information.'}),
    );
    _loadAdminData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _loadAdminData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Admin Dashboard', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const Text('Manage societies, events, attendance evidence and audit logs.'),
          const SizedBox(height: 16),
          _sectionTitle('Create / manage society'),
          TextField(controller: _societyName, decoration: const InputDecoration(labelText: 'Society name', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          TextField(controller: _societyDescription, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _societyCategory,
            decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
            items: const ['cultural', 'academic', 'religious', 'sports', 'extracurricular'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setState(() => _societyCategory = v ?? 'extracurricular'),
          ),
          const SizedBox(height: 8),
          TextField(controller: _societyLocation, decoration: const InputDecoration(labelText: 'Meeting location', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          TextField(controller: _societyEmail, decoration: const InputDecoration(labelText: 'Contact email', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          ElevatedButton.icon(onPressed: _createSociety, icon: const Icon(Icons.add), label: const Text('Create society')),
          ..._societies.take(4).map((s) => Card(child: ListTile(title: Text(s['name']), subtitle: Text('${s['category']} • ${s['member_count']} members'), trailing: TextButton(onPressed: () => _updateSociety(s), child: const Text('Quick edit'))))),
          const Divider(height: 32),
          _sectionTitle('Create / edit / remove events'),
          if (_societies.isNotEmpty)
            DropdownButtonFormField<int>(
              value: _eventSocietyId,
              decoration: const InputDecoration(labelText: 'Society', border: OutlineInputBorder()),
              items: _societies.map<DropdownMenuItem<int>>((s) => DropdownMenuItem(value: s['id'], child: Text(s['name']))).toList(),
              onChanged: (v) => setState(() => _eventSocietyId = v),
            ),
          const SizedBox(height: 8),
          TextField(controller: _eventTitle, decoration: const InputDecoration(labelText: 'Event title', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          TextField(controller: _eventDescription, decoration: const InputDecoration(labelText: 'Event description', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          TextField(controller: _eventLocation, decoration: const InputDecoration(labelText: 'Location', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          TextField(controller: _eventCapacity, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Capacity limit', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          ElevatedButton.icon(onPressed: _createEvent, icon: const Icon(Icons.event), label: const Text('Create event')),
          ..._events.map((e) => Card(child: ListTile(title: Text(e['title']), subtitle: Text('${e['society_name']} • ${e['rsvp_count']} attending'), trailing: Wrap(spacing: 4, children: [TextButton(onPressed: () => _quickEditEvent(e), child: const Text('Edit')), TextButton(onPressed: () => _deleteEvent(e['id']), child: const Text('Delete', style: TextStyle(color: Colors.red)))])))),
          const Divider(height: 32),
          _sectionTitle('Attendance report and audit logs'),
          const SelectableText('${AuthService.baseUrl}/admin/attendance-report/'),
          const SizedBox(height: 8),
          ..._logs.take(8).map((l) => ListTile(dense: true, leading: Icon(l['success'] == true ? Icons.check_circle : Icons.error), title: Text(l['action']), subtitle: Text(l['details'] ?? ''))),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      );
}
