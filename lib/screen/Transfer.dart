import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class TransferPage extends StatefulWidget {
  final String firebaseUid;
  final String totalIncome; // รับข้อมูลรายได้มาจากหน้า RecipientDetailPage

  const TransferPage({
    Key? key,
    required this.firebaseUid,
    required this.totalIncome,
    required amount,
  }) : super(key: key);

  @override
  _TransferPageState createState() => _TransferPageState();
}

class _TransferPageState extends State<TransferPage> {
  final TextEditingController _referenceController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _transferIncome() async {
    if (_referenceController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Reference number cannot be empty';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse(
            'http://10.0.2.2:3000/recipients/${widget.firebaseUid}/transfer'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'reference_number': _referenceController.text}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Transfer successful')),
        );
        Navigator.pop(context);
      } else {
        setState(() {
          _errorMessage =
              'Error: ${response.statusCode} - ${response.reasonPhrase}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = new NumberFormat("#,##0.00", "th");
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text('โอนรายได้ให้กับนักหิ้ว'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
Text(
  'รอดำเนินการทั้งหมด: ${formatter.format(double.tryParse(widget.totalIncome?.toString() ?? '0') ?? 0.00)} บาท',
  style: TextStyle(fontSize: 18),
),
            SizedBox(height: 20),
            TextField(
              controller: _referenceController,
              decoration: InputDecoration(
                labelText: 'Reference Number',
              ),
            ),
            SizedBox(height: 20),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red),
              ),
            SizedBox(height: 20),
            if (_isLoading)
              Center(child: CircularProgressIndicator())
            else
Row(
  mainAxisAlignment: MainAxisAlignment.end, // ✅ จัดปุ่มไปด้านขวา
  children: [
    ElevatedButton(
      onPressed: _transferIncome,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.pink, // ✅ ปุ่มสีชมพู
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10), // ✅ ปุ่มโค้งมน
        ),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12), // ✅ ปรับขนาดปุ่ม
      ),
      child: Text(
        'บันทึก',
        style: TextStyle(
          fontSize: 16, 
          color: Colors.white, 
        ),
      ),
    ),
  ],
),



          ],
        ),
      ),
    );
  }
}
