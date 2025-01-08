import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:loginsystem/screen/ProfileView.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class ChatPage extends StatefulWidget {
  final String receiverEmail;
  final String firstName;

  const ChatPage({required this.receiverEmail, required this.firstName});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late IO.Socket socket;
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  String? receiverProfilePicture;

  @override
  void initState() {
    super.initState();
    _connectToSocket();
    _fetchReceiverDetails();
    _fetchChatMessages();
  }

  void _connectToSocket() {
    socket = IO.io('http://10.0.2.2:3000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket.onConnect((_) {
      print('Connected to server');
      socket.emit('joinRoom', {
        'sender': FirebaseAuth.instance.currentUser!.email,
        'receiver': widget.receiverEmail,
      });
    });

    socket.on('receiveMessage', (data) {
      setState(() {
        _messages.add(data);
      });
    });
  }

Future<void> _fetchReceiverDetails() async {
  try {
    final response = await http.get(
      Uri.parse(
          'http://10.0.2.2:3000/getUserDetails?email=${widget.receiverEmail}'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (mounted) {
        setState(() {
          receiverProfilePicture = data['profile_picture'];
        });
      }
    } else {
      print('Failed to fetch receiver details: ${response.statusCode}');
    }
  } catch (e) {
    print('Error fetching receiver details: $e');
  }
}


Future<void> _fetchChatMessages() async {
  final currentUserEmail = FirebaseAuth.instance.currentUser!.email!;
  try {
    final response = await http.get(Uri.parse(
        'http://10.0.2.2:3000/fetchChats?sender=$currentUserEmail&receiver=${widget.receiverEmail}'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      if (mounted) { // Check if the widget is still mounted
        setState(() {
          _messages.clear(); // Clear old messages
          _messages.addAll(data.cast<Map<String, dynamic>>());
        });
      }
    } else {
      print("Failed to fetch chat messages: ${response.body}");
    }
  } catch (e) {
    print("Error fetching chat messages: $e");
  }
}

void _sendMessage(String text) async {
  final senderEmail = FirebaseAuth.instance.currentUser!.email;
  final messageData = {
    'sender': senderEmail,
    'receiver': widget.receiverEmail,
    'message': text,
    'imageUrl': null,
  };

  // เพิ่มฟิลด์ sender_email ในข้อความใหม่
  setState(() {
    _messages.add({
      ...messageData,
      'timestamp': DateTime.now().toString(), // เพิ่ม timestamp ปัจจุบัน
      'sender_email': senderEmail, // ฟิลด์นี้ใช้ใน isSender
    });
  });

  try {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:3000/sendMessage'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(messageData),
    );

    if (response.statusCode != 200) {
      print('Failed to send message: ${response.body}');
    }
  } catch (e) {
    print('Error sending message: $e');
  }

  _messageController.clear(); // ล้างช่องข้อความ
}

Widget _buildMessageBubble(Map<String, dynamic> message, bool isSender) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
    child: Row(
      mainAxisAlignment: isSender ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!isSender)
          CircleAvatar(
            backgroundImage: receiverProfilePicture != null
                ? MemoryImage(base64Decode(receiverProfilePicture!))
                : null,
            backgroundColor: Colors.grey[300],
            child: receiverProfilePicture == null
                ? Icon(Icons.person, color: Colors.white)
                : null,
          ),
        if (!isSender) SizedBox(width: 10),
        Flexible(
          child: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSender ? Colors.pink[100] : Colors.grey[200],
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
                bottomLeft: isSender ? Radius.circular(15) : Radius.zero,
                bottomRight: isSender ? Radius.zero : Radius.circular(15),
              ),
            ),
            child: Column(
              crossAxisAlignment:
                  isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  message['message'] ?? '',
                  style: TextStyle(
                    fontSize: 16,
                    color: isSender ? Colors.pink : Colors.black87,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  _formatTimestamp(message['timestamp']),
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}


  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return '';
    final dateTime = DateTime.parse(timestamp);
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: PreferredSize(
      preferredSize: Size.fromHeight(80), // ปรับขนาด AppBar
      child: SafeArea(
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // รูปโปรไฟล์
              CircleAvatar(
                radius: 25, // ขนาดรูปโปรไฟล์
                backgroundImage: receiverProfilePicture != null
                    ? MemoryImage(base64Decode(receiverProfilePicture!))
                    : null,
                backgroundColor: Colors.grey[300],
                child: receiverProfilePicture == null
                    ? Icon(Icons.person, color: Colors.white)
                    : null,
              ),
              SizedBox(width: 10), // ระยะห่างระหว่างโปรไฟล์กับข้อความ
              // ข้อมูลชื่อและ "ดูโปรไฟล์"
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.firstName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      // Navigate to ProfileView เมื่อคลิก "ดูโปรไฟล์"
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileView(
                            email: widget.receiverEmail,
                          ),
                        ),
                      );
                    },
                    child: Text(
                      'ดูโปรไฟล์',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        
                    ),
                  ),
                  ),
                ],
              ),
            ],
          ),
          centerTitle: false, // ไม่ต้องจัดกึ่งกลาง
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
      ),
    ),
    body: Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 8.0), // เพิ่มระยะห่างจากด้านบน
            child: ListView.builder(
  reverse: false,
  itemCount: _messages.length,
  itemBuilder: (context, index) {
    final message = _messages[index];
    final isSender = message['sender_email'] == FirebaseAuth.instance.currentUser!.email;
    return _buildMessageBubble(message, isSender);
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: Colors.white,
                    border: Border.all(color: Colors.pinkAccent),
                  ),
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'พิมพ์ข้อความ...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10),
              GestureDetector(
                onTap: () {
                  if (_messageController.text.trim().isNotEmpty) {
                    _sendMessage(_messageController.text.trim());
                  }
                },
                child: CircleAvatar(
                  backgroundColor: Colors.pink,
                  child: Icon(Icons.send, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
}
