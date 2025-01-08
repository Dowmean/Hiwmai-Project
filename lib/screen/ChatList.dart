import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:loginsystem/screen/Chat.dart';
import 'Chat.dart'; // Import ChatPage here
import 'package:http/http.dart' as http;

class ChatListPage extends StatefulWidget {
  @override
  _ChatListPageState createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  List<Map<String, dynamic>> _senders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMessageSenders();
  }

  Future<void> _fetchMessageSenders() async {
    final currentUserEmail = FirebaseAuth.instance.currentUser!.email!;

    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/getMessageSenders?email=$currentUserEmail'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        setState(() {
          _senders = data.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      } else {
        print('Failed to fetch message senders: ${response.body}');
      }
    } catch (e) {
      print('Error fetching message senders: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Messages'),
        backgroundColor: Colors.pink,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _senders.length,
              itemBuilder: (context, index) {
                final sender = _senders[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: sender['profile_picture'] != null
                        ? MemoryImage(base64Decode(sender['profile_picture']))
                        : null,
                    child: sender['profile_picture'] == null
                        ? Icon(Icons.person)
                        : null,
                  ),
                  title: Text(sender['first_name'] ?? 'Unknown User'),
                  onTap: () {
                    // Navigate to ChatPage
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatPage(
                          receiverEmail: sender['sender_email'],
                          firstName: sender['first_name'],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
