import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RecipientsDetailReqPage extends StatefulWidget {
  final String firebaseUid;

  const RecipientsDetailReqPage({Key? key, required this.firebaseUid}) : super(key: key);

  @override
  _RecipientsDetailReqPageState createState() => _RecipientsDetailReqPageState();
}

class _RecipientsDetailReqPageState extends State<RecipientsDetailReqPage> {
  Map<String, dynamic>? recipientData;

  @override
  void initState() {
    super.initState();
    fetchRecipientDetail();
  }

  Future<void> fetchRecipientDetail() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/detailrecipients/${widget.firebaseUid}'),
      );

      if (response.statusCode == 200) {
        setState(() {
          recipientData = json.decode(response.body);
        });
      } else {
        throw Exception('Failed to load recipient details');
      }
    } catch (e) {
      print('Error fetching recipient details: $e');
    }
  }

  Widget buildDetailItem(String title, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: Colors.black87,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ข้อมูลส่วนตัว'),
        backgroundColor: Colors.pink,
      ),
      body: recipientData == null
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ส่วนที่ 1: ข้อมูลของผู้ใช้
                  Text(
                    'ข้อมูลของผู้รับผลประโยชน์',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.pink),
                  ),
                  Divider(color: Colors.pink),
                  buildDetailItem('คำนำหน้า', recipientData!['title'] ?? 'ไม่ระบุ'),
                  buildDetailItem('ชื่อจริง', recipientData!['first_name'] ?? 'ไม่ระบุ', isBold: true),
                  buildDetailItem('นามสกุล', recipientData!['last_name'] ?? 'ไม่ระบุ', isBold: true),
                  buildDetailItem('เบอร์โทรศัพท์', recipientData!['phone_number'] ?? 'ไม่ระบุ'),

                  SizedBox(height: 16),

                  // ส่วนที่ 2: ที่อยู่
                  Text(
                    'ที่อยู่',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.pink),
                  ),
                  Divider(color: Colors.pink),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      recipientData!['address'] ?? 'ไม่ระบุ',
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                  ),

                  SizedBox(height: 16),

                  // ส่วนที่ 3: ข้อมูลธนาคาร
                  Text(
                    'ข้อมูลธนาคารและภาษี',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.pink),
                  ),
                  Divider(color: Colors.pink),
                  buildDetailItem('ธนาคาร', recipientData!['bank_name'] ?? 'ไม่ระบุ'),
                  buildDetailItem('ชื่อบัญชีธนาคาร', recipientData!['account_name'] ?? 'ไม่ระบุ'),
                  buildDetailItem('เลขบัญชี', recipientData!['account_number'] ?? 'ไม่ระบุ'),
                ],
              ),
            ),
    );
  }
}
