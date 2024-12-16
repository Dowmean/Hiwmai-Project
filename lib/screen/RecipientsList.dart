import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'RecipientDetail.dart';

class RecipientsScreen extends StatefulWidget {
  @override
  _RecipientsScreenState createState() => _RecipientsScreenState();
}

class _RecipientsScreenState extends State<RecipientsScreen> {
  Future<List<dynamic>>? _recipientsFuture;

  @override
  void initState() {
    super.initState();
    _recipientsFuture = fetchRecipients();
  }

  Future<List<dynamic>> fetchRecipients() async {
    final String apiUrl = 'http://10.0.2.2:3000/recipients'; // URL ของ API
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Fetched recipients: $data'); // Debug ข้อมูลที่ได้จาก API
        return data;
      } else {
        print('Failed to fetch recipients: ${response.body}');
        throw Exception('Failed to fetch recipients');
      }
    } catch (e) {
      print('Error fetching recipients: $e');
      throw Exception('Error fetching recipients');
    }
  }

  Widget _buildRecipientList(List<dynamic> recipients) {
    return ListView.builder(
      itemCount: recipients.length,
      itemBuilder: (context, index) {
        final recipient = recipients[index];
        print('Recipient: $recipient'); // Debug รายการแต่ละรายการ

        return ListTile(
          leading: CircleAvatar(
            backgroundImage: recipient['profilePicture'] != null
                ? MemoryImage(base64Decode(recipient['profilePicture']))
                : AssetImage('assets/default_profile.png') as ImageProvider,
          ),
          title: Text(recipient['firstName'] ?? 'Unknown'),
          onTap: () {
            // ตรวจสอบค่า firebaseUid ก่อนส่งไปยังหน้ารายละเอียด
            print('Selected firebaseUid: ${recipient['firebaseUid']}'); // Debug
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RecipientDetailPage(
                  firebaseUid: recipient['firebaseUid'], // ส่ง firebaseUid ไปยังหน้ารายละเอียด
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Recipients')),
      body: FutureBuilder<List<dynamic>>(
        future: _recipientsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No recipients found'));
          } else {
            return _buildRecipientList(snapshot.data!);
          }
        },
      ),
    );
  }
}
