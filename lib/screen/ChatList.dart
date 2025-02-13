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
    _fetchMessagesForReceiver(); // ดึงข้อความจาก `/getMessagesForReceiver`
  }

  Future<void> _fetchMessageSenders() async {
    final currentUserEmail = FirebaseAuth.instance.currentUser!.email!;

    try {
      final response = await http.get(
        Uri.parse(
            'http://10.0.2.2:3000/getMessageSenders?email=$currentUserEmail'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        setState(() {
          _senders = data.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      } else {
        //print('Failed to fetch message senders: ${response.body}');
      }
    } catch (e) {
      //print('Error fetching message senders: $e');
    }
  }

  Future<void> _fetchMessagesForReceiver() async {
    final currentUserEmail = FirebaseAuth.instance.currentUser!.email!;

    try {
      final response = await http.get(
        Uri.parse(
            'http://10.0.2.2:3000/getMessagesForReceiver?receiver=$currentUserEmail'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        setState(() {
          // เพิ่มผู้ส่งจาก API นี้ไปยัง `_senders`
          for (var message in data) {
            final senderEmail = message['sender_email'];
            // ตรวจสอบว่าผู้ส่งยังไม่ได้อยู่ใน `_senders`
            if (!_senders.any((sender) => sender['sender_email'] == senderEmail)) {
              _senders.add({
                'sender_email': senderEmail,
                'first_name': message['first_name'] ?? 'Unknown User',
                'profile_picture': message['profile_picture'],
              });
            }
          }
          _isLoading = false;
        });
      } else {
        //print('Failed to fetch messages for receiver: ${response.body}');
      }
    } catch (e) {
      //print('Error fetching messages for receiver: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'ข้อความของฉัน',
          style: TextStyle(fontSize: 20,color: Colors.white, fontWeight: FontWeight.bold,),
        ),
        backgroundColor: Colors.pink,
        centerTitle: true, // จัดข้อความให้อยู่ตรงกลาง
        automaticallyImplyLeading: false, // ลบปุ่มย้อนกลับ
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _senders.length,
              itemBuilder: (context, index) {
                final sender = _senders[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: sender['profile_picture'] != null &&
                            sender['profile_picture'].startsWith('http')
                        ? NetworkImage(sender[
                            'profile_picture']) // ใช้ NetworkImage สำหรับ URL
                        : AssetImage('assets/avatar_placeholder.png')
                            as ImageProvider, // กรณีไม่มีรูป ใช้ภาพเริ่มต้น
                    backgroundColor: Colors.grey[300],
                    child: sender['profile_picture'] == null ||
                            !sender['profile_picture'].startsWith('http')
                        ? Icon(Icons.person, color: Colors.white)
                        : null,
                  ),
                  title: Text(
                    sender['first_name'] ?? 'Unknown User',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
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
