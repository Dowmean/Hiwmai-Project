import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
String getFullImageUrl(String? imageUrl) {
  if (imageUrl == null || imageUrl.isEmpty) return '';
  if (imageUrl.startsWith('http')) {
    return imageUrl; // URL สมบูรณ์แล้ว
  }
  return 'http://10.0.2.2:3000$imageUrl'; // เพิ่ม Host และ Protocol
}


class _ChatPageState extends State<ChatPage> {
  late IO.Socket socket;
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final ImagePicker _picker = ImagePicker();
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
    //print('Connected to server');
    socket.emit('joinRoom', {
      'sender': FirebaseAuth.instance.currentUser!.email,
      'receiver': widget.receiverEmail,
    });
  });

  socket.on('receiveMessage', (data) {
  setState(() {
    _messages.add({
      ...data,
      'imageUrl': getFullImageUrl(data['imageUrl'] ?? data['image_url']),
    });
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
      //print('Failed to fetch receiver details: ${response.statusCode}');
    }
  } catch (e) {
    //print('Error fetching receiver details: $e');
  }
}



Future<void> _fetchChatMessages() async {
  final currentUserEmail = FirebaseAuth.instance.currentUser!.email!;
  try {
    final response = await http.get(Uri.parse(
        'http://10.0.2.2:3000/fetchChats?sender=$currentUserEmail&receiver=${widget.receiverEmail}'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      if (mounted) {
        setState(() {
          _messages.clear();
          _messages.addAll(data.map<Map<String, dynamic>>((message) {
            return {
              ...message,
              'imageUrl': getFullImageUrl(message['imageUrl'] ?? message['image_url']),
            };
          }).toList());
        });
      }
    } else {
      //print("Failed to fetch chat messages: ${response.body}");
    }
  } catch (e) {
    //print("Error fetching chat messages: $e");
  }
}



Future<void> _pickImage() async {
  final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
  if (pickedFile != null) {
    final file = File(pickedFile.path);
    final bytes = file.readAsBytesSync();
    final base64Image = base64Encode(bytes);

    // ส่งข้อความพร้อมรูปภาพ
    _sendMessageWithImage(base64Image);
  }
}
void _sendMessageWithImage(String base64Image) async {
  final senderEmail = FirebaseAuth.instance.currentUser!.email;

  final messageData = {
    'sender': senderEmail,
    'receiver': widget.receiverEmail,
    'message': null, // Explicitly set as null
    'imageBase64': base64Image,
  };

  // เพิ่มข้อความชั่วคราว (Temporary) พร้อม URL รูปภาพ
  final temporaryMessage = {
    'sender_email': senderEmail,
    'receiver_email': widget.receiverEmail,
    'message': null,
    'imageUrl': null, // Placeholder สำหรับ URL
    'timestamp': DateTime.now().toString(),
  };

  setState(() {
    _messages.add(temporaryMessage);
  });

  try {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:3000/sendMessage'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(messageData),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      // อัปเดต URL รูปภาพในข้อความชั่วคราว
      setState(() {
        _messages.last['imageUrl'] =
            getFullImageUrl(responseData['imageUrl']);
      });

      // ส่งข้อความไปยัง WebSocket
      socket.emit('sendMessage', {
        'sender_email': senderEmail,
        'receiver_email': widget.receiverEmail,
        'message': null,
        'imageUrl': responseData['imageUrl'],
        'timestamp': DateTime.now().toString(),
      });
    } else {
      //print('Failed to send image: ${response.body}');
    }
  } catch (e) {
    //print('Error sending image: $e');
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
      //print('Failed to send message: ${response.body}');
    }
  } catch (e) {
    //print('Error sending message: $e');
  }

  _messageController.clear(); // ล้างช่องข้อความ
}

Widget _buildMessageBubble(Map<String, dynamic> message, bool isSender) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
    child: Row(
      mainAxisAlignment: isSender ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isSender) CircleAvatar(
          radius: 20,
          backgroundImage: receiverProfilePicture != null
              ? NetworkImage(receiverProfilePicture!)
              : AssetImage('assets/avatar_placeholder.png') as ImageProvider,
        ),
        if (!isSender) SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment:
                isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (message['imageUrl'] != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Container(
                    width: 200, // กำหนดความกว้างให้พอดี
                    height: 150, // กำหนดความสูงให้เหมาะสม
                    child: Image.network(
                      message['imageUrl'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        //print("Error loading image URL: ${message['imageUrl']}, Error: $error");
                        return Icon(Icons.broken_image);
                      },
                    ),
                  ),
                ),
              if (message['message'] != null)
                Container(
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
                  child: Text(
                    message['message'] ?? '',
                    style: TextStyle(
                      fontSize: 16,
                      color: isSender ? Colors.pink : Colors.black87,
                    ),
                  ),
                ),
            ],
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
      preferredSize: Size.fromHeight(50), // ปรับขนาด AppBar
      child: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // ลบปุ่มย้อนกลับ
        centerTitle: true, // จัดกึ่งกลาง
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center, // จัดกึ่งกลางในแนวตั้ง
          children: [
            CircleAvatar(
              radius: 15, // ปรับขนาดรูปโปรไฟล์
              backgroundImage: receiverProfilePicture != null &&
                      receiverProfilePicture!.startsWith('http')
                  ? NetworkImage(receiverProfilePicture!)
                  : receiverProfilePicture != null &&
                          receiverProfilePicture!.isNotEmpty
                      ? MemoryImage(base64Decode(receiverProfilePicture!))
                      : null,
              backgroundColor: Colors.grey[30],
              child: receiverProfilePicture == null ||
                      receiverProfilePicture!.isEmpty
                  ? Icon(Icons.person, color: Colors.white)
                  : null,
            ),
            SizedBox(height:2), // ระยะห่างระหว่างรูปโปรไฟล์กับชื่อ
            Text(
              widget.firstName,
              style: TextStyle(
                fontSize: 20, // ขนาดตัวอักษร
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    ),
    body: Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: ListView.builder(
              reverse: false,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isSender =
                    message['sender_email'] == FirebaseAuth.instance.currentUser!.email;
                return _buildMessageBubble(message, isSender);
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.camera_alt, color: Colors.pink),
                onPressed: _pickImage,
              ),
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
