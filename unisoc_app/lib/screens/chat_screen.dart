import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class ChatScreen extends StatefulWidget {
  final int societyId;
  final String societyName;
  const ChatScreen({super.key, required this.societyId, required this.societyName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  List _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
  }

  Future<void> _fetchMessages() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final response = await http.get(
      Uri.parse('${AuthService.baseUrl}/societies/${widget.societyId}/chat/'),
      headers: auth.authHeaders,
    );
    if (response.statusCode == 200) setState(() => _messages = jsonDecode(response.body));
    setState(() => _isLoading = false);
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    final auth = Provider.of<AuthService>(context, listen: false);
    await http.post(
      Uri.parse('${AuthService.baseUrl}/societies/${widget.societyId}/chat/'),
      headers: auth.authHeaders,
      body: jsonEncode({'message': text}),
    );
    _messageController.clear();
    _fetchMessages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.societyName} chat')),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(child: Text('No chat messages yet.'))
                    : RefreshIndicator(
                        onRefresh: _fetchMessages,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _messages.length,
                          itemBuilder: (_, i) {
                            final m = _messages[i];
                            final isAdmin = m['sender_role'] == 'admin';
                            return Align(
                              alignment: isAdmin ? Alignment.centerLeft : Alignment.centerRight,
                              child: Card(
                                color: isAdmin ? Colors.grey.shade200 : const Color(0xFF6750A4).withOpacity(0.12),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('${m['sender_username']} (${m['sender_role']})', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      Text(m['message'] ?? ''),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(child: TextField(controller: _messageController, decoration: const InputDecoration(hintText: 'Message society admin...', border: OutlineInputBorder()))),
                const SizedBox(width: 8),
                IconButton(onPressed: _sendMessage, icon: const Icon(Icons.send), color: const Color(0xFF6750A4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
