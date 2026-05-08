import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class SocietiesScreen extends StatefulWidget {
  const SocietiesScreen({super.key});

  @override
  State<SocietiesScreen> createState() => _SocietiesScreenState();
}

class _SocietiesScreenState extends State<SocietiesScreen> {
  List _societies = [];
  bool _isLoading = true;
  String _search = '';
  String _category = 'all';

  final List<String> _categories = [
    'all',
    'cultural',
    'academic',
    'religious',
    'sports',
    'extracurricular'
  ];

  @override
  void initState() {
    super.initState();
    _fetchSocieties();
  }

  Future<void> _fetchSocieties() async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthService>(context, listen: false);

    String url = 'http://127.0.0.1:8000/api/societies/?';
    if (_search.isNotEmpty) url += 'search=$_search&';
    if (_category != 'all') url += 'category=$_category';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer ${auth.token}'},
      );
      if (response.statusCode == 200) {
        setState(() => _societies = jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint('Error fetching societies: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _joinLeave(int id, bool isMember) async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final action = isMember ? 'leave' : 'join';

    await http.post(
      Uri.parse('http://127.0.0.1:8000/api/societies/$id/$action/'),
      headers: {'Authorization': 'Bearer ${auth.token}'},
    );
    _fetchSocieties();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search societies...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(vertical: 8),
            ),
            onChanged: (v) {
              _search = v;
              _fetchSocieties();
            },
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _categories.length,
            itemBuilder: (_, i) {
              final cat = _categories[i];
              final selected = cat == _category;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(cat[0].toUpperCase() + cat.substring(1)),
                  selected: selected,
                  onSelected: (_) {
                    setState(() => _category = cat);
                    _fetchSocieties();
                  },
                  selectedColor: const Color(0xFF6750A4).withOpacity(0.2),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _societies.isEmpty
                  ? const Center(child: Text('No societies found.'))
                  : ListView.builder(
                      itemCount: _societies.length,
                      itemBuilder: (_, i) {
                        final s = _societies[i];
                        final isMember = s['is_member'] ?? false;
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF6750A4),
                              child: Text(
                                s['name'][0],
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(s['name'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle: Text(
                                '${s['category']} • ${s['member_count']} members'),
                            trailing: ElevatedButton(
                              onPressed: () => _joinLeave(s['id'], isMember),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isMember
                                    ? Colors.grey[300]
                                    : const Color(0xFF6750A4),
                                foregroundColor:
                                    isMember ? Colors.black : Colors.white,
                              ),
                              child: Text(isMember ? 'Leave' : 'Join'),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
