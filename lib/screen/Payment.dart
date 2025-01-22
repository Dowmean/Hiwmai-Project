import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // สำหรับบันทึกรูปภาพ
import 'package:intl/intl.dart';
import 'package:loginsystem/screen/Profilepage.dart';

class PaymentPage extends StatefulWidget {
  final double total; // รับยอดรวมคำสั่งซื้อจากหน้าก่อนหน้า

  PaymentPage({required this.total, required orderId});

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  late DateTime _expirationTime;
  late Timer _timer;
  Duration _remainingTime = Duration(hours: 24); // กำหนดเวลาถอยหลัง 24 ชม.

  @override
  void initState() {
    super.initState();
    _expirationTime = DateTime.now().add(Duration(hours: 24)); // เวลาหมดอายุ
    _startCountdown(); // เริ่มนับเวลาถอยหลัง
  }

  @override
  void dispose() {
    _timer.cancel(); // ยกเลิก Timer เมื่อปิดหน้า
    super.dispose();
  }

  void _startCountdown() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _remainingTime = _expirationTime.difference(DateTime.now());
        if (_remainingTime.isNegative) {
          _timer.cancel(); // หยุด Timer เมื่อเวลาหมด
        }
      });
    });
  }

  String _formatRemainingTime(Duration duration) {
    return "${duration.inHours.toString().padLeft(2, '0')}:${(duration.inMinutes % 60).toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}";
  }

  void _saveQRImage() async {
    try {
      // โหลดรูปภาพจาก assets
      final ByteData imageData =
          await rootBundle.load('assets/images/bankqr.jpg');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('บันทึกรูปภาพ QR สำเร็จ')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ไม่สามารถบันทึกรูปภาพได้: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ข้อมูลการชำระเงิน'),
        backgroundColor: Colors.pink,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ยอดชำระเงินทั้งหมด',
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  '฿${widget.total.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'กรุณาชำระภายใน',
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  _formatRemainingTime(_remainingTime),
                  style: TextStyle(
                      fontSize: 16, color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 16),
            Divider(),
            Image.asset(
              'assets/images/bankqr.jpg',
              height: 450,
              width: 450,
              fit: BoxFit.contain,
            ),
            SizedBox(height: 16),
            Text(
              '฿${widget.total.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 16, color: Colors.red, fontWeight: FontWeight.bold),
            ),
            Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _saveQRImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: BorderSide(color: Colors.pink),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: Text(
                    'บันทึก QR',
                    style: TextStyle(color: Colors.pink),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ProfileScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: Text(
                    'ตกลง',
                    style: TextStyle(color: Colors.white),
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