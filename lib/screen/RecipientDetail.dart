import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RecipientDetailPage extends StatelessWidget {
  final String firebaseUid;

  const RecipientDetailPage({Key? key, required this.firebaseUid}) : super(key: key);

  Future<Map<String, dynamic>> fetchRecipientDetails() async {
    print('Fetching details for firebaseUid: $firebaseUid'); // Debug
    try {
      final response = await http
          .get(Uri.parse('http://10.0.2.2:3000/recipients/$firebaseUid'))
          .timeout(Duration(seconds: 10)); // กำหนด timeout

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Fetched recipient details: $data'); // Debug ข้อมูลที่ได้จาก API
        if (data is Map<String, dynamic>) {
          return data;
        } else {
          throw Exception('Unexpected data format');
        }
      } else {
        print('Failed to fetch recipient details: ${response.body}');
        throw Exception('Failed to fetch recipient details');
      }
    } catch (e) {
      print('Error fetching recipient details: $e');
      throw Exception('Error fetching recipient details');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Recipient Details')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchRecipientDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No data found'));
          } else {
            final recipient = snapshot.data!;
            print('Recipient details: $recipient'); // Debug ข้อมูล recipient
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 16),
                  _buildFormField('Bank Name', recipient['bankName']),
                  SizedBox(height: 10),
                  _buildFormField('Account Name', recipient['accountName']),
                  SizedBox(height: 10),
                  _buildFormField('Account Number', recipient['accountNumber']),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildFormField(String label, dynamic value) {
    // ตรวจสอบค่า null และความว่างเปล่า
    final displayValue = (value != null && value is String && value.isNotEmpty)
        ? value
        : 'Not provided';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        SizedBox(height: 5),
        Container(
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            displayValue,
            style: TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
}
