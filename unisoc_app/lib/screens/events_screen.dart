import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  List _events = [];
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthService>(context, listen: false);
    try {
      final response = await http.get(Uri.parse('${AuthService.baseUrl}/events/'), headers: auth.authHeaders);
      if (response.statusCode == 200) setState(() => _events = jsonDecode(response.body));
    } catch (e) {
      debugPrint('Error fetching events: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _rsvp(int eventId, bool currentStatus) async {
    final auth = Provider.of<AuthService>(context, listen: false);
    await http.post(
      Uri.parse('${AuthService.baseUrl}/events/$eventId/rsvp/'),
      headers: auth.authHeaders,
      body: jsonEncode({'is_attending': !currentStatus}),
    );
    _fetchEvents();
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr).toLocal();
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final visibleEvents = _events.where((e) {
      final date = DateTime.parse(e['start_time']).toLocal();
      return _sameDay(date, _selectedDate);
    }).toList();

    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              _calendarStrip(),
              Expanded(
                child: visibleEvents.isEmpty
                    ? const Center(child: Text('No events on this date. Join societies or select another date.'))
                    : RefreshIndicator(
                        onRefresh: _fetchEvents,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: visibleEvents.length,
                          itemBuilder: (_, i) => _eventCard(visibleEvents[i]),
                        ),
                      ),
              ),
            ],
          );
  }

  Widget _calendarStrip() {
    final days = List.generate(14, (i) => DateTime.now().add(Duration(days: i)));
    return Container(
      height: 92,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        itemBuilder: (_, i) {
          final day = days[i];
          final selected = _sameDay(day, _selectedDate);
          final count = _events.where((e) => _sameDay(DateTime.parse(e['start_time']).toLocal(), day)).length;
          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: ChoiceChip(
              selected: selected,
              selectedColor: const Color(0xFF6750A4).withOpacity(0.2),
              label: SizedBox(
                width: 58,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${day.day}/${day.month}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(count == 1 ? '1 event' : '$count events', style: const TextStyle(fontSize: 11)),
                  ],
                ),
              ),
              onSelected: (_) => setState(() => _selectedDate = day),
            ),
          );
        },
      ),
    );
  }

  Widget _eventCard(dynamic e) {
    final isAttending = e['user_rsvp'] == true;
    final isFull = e['is_full'] ?? false;
    final spaces = e['spaces_remaining'];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(e['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                Chip(label: Text(e['society_name'], style: const TextStyle(fontSize: 12))),
              ],
            ),
            if ((e['description'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(e['description']),
            ],
            const SizedBox(height: 8),
            Row(children: [const Icon(Icons.access_time, size: 14, color: Colors.grey), const SizedBox(width: 4), Text(_formatDate(e['start_time']), style: const TextStyle(color: Colors.grey, fontSize: 13))]),
            if ((e['location'] ?? '').toString().isNotEmpty) Row(children: [const Icon(Icons.location_on, size: 14, color: Colors.grey), const SizedBox(width: 4), Expanded(child: Text(e['location'], style: const TextStyle(color: Colors.grey, fontSize: 13)))]),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: e['capacity_limit'] == null || e['capacity_limit'] == 0 ? null : (e['rsvp_count'] / e['capacity_limit']).clamp(0.0, 1.0)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${e['rsvp_count']} attending${e['capacity_limit'] != null ? ' • $spaces spaces left' : ' • unlimited spaces'}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ElevatedButton(
                  onPressed: (isFull && !isAttending) ? null : () => _rsvp(e['id'], isAttending),
                  style: ElevatedButton.styleFrom(backgroundColor: isAttending ? Colors.green : isFull ? Colors.grey : const Color(0xFF6750A4), foregroundColor: Colors.white),
                  child: Text(isAttending ? '✓ Attending' : isFull ? 'Full' : 'I will attend'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
