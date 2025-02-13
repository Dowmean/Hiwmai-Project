import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AddParcelPage extends StatelessWidget {
  final String ref;

  AddParcelPage({required this.ref});

  Future<void> submitTrackingNumber(String ref, String trackingNumber) async {
    final url = Uri.parse('http://10.0.2.2:3000/addTrackingNumber'); // เปลี่ยน URL ให้ถูกต้อง
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'ref': ref,
          'trackingNumber': trackingNumber,
        }),
      );

      if (response.statusCode == 200) {
     //   print('Data saved successfully: ${response.body}');
      } else {
        //print('Failed to save data: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to save data');
      }
    } catch (e) {
      //print('Error saving tracking number: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextEditingController trackingNumberController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: Text('เพิ่มหมายเลขพัสดุ'),
        actions: [
          TextButton(
onPressed: () async {
  final trackingNumber = trackingNumberController.text;
  if (trackingNumber.isNotEmpty) {
    await submitTrackingNumber(ref, trackingNumber);
    
    // แสดงข้อความสำเร็จ
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('หมายเลขพัสดุถูกเพิ่มเรียบร้อย')),
    );

    // เคลียร์ข้อความใน TextField
    trackingNumberController.clear();
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('กรุณากรอกหมายเลขพัสดุ')),
    );
  }
},

            child: Text(
              'ยืนยัน',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'หมายเลขคำสั่งซื้อ: $ref',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            TextField(
              controller: trackingNumberController,
              decoration: InputDecoration(
                hintText: 'กรอกเลขพัสดุ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            Spacer(),
            Center(
              // child: ElevatedButton(
              //   onPressed: () async {
              //     final trackingNumber = trackingNumberController.text;
              //     if (trackingNumber.isNotEmpty) {
              //       await submitTrackingNumber(ref, trackingNumber);
              //     } else {
              //       ScaffoldMessenger.of(context).showSnackBar(
              //         SnackBar(content: Text('กรุณากรอกหมายเลขพัสดุ')),
              //       );
              //     }
              //   },
              //   // child: Text('ยืนยัน'),
              //   style: ElevatedButton.styleFrom(
              //     padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              //     textStyle: TextStyle(fontSize: 16),
              //   ),
              // ),
            ),
          ],
        ),
      ),
    );
  }
}
