import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:loginsystem/screen/Orderscancle.dart';

class RefundPage extends StatefulWidget {
  final Map<String, dynamic> order;

  RefundPage({required this.order});

  @override
  _RefundPageState createState() => _RefundPageState();
}

class _RefundPageState extends State<RefundPage> {
  Future<void> processRefund(String orderRef) async {
    bool confirmRefund = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ยืนยันคืนเงิน'),
        content: Text('คุณต้องการคืนเงินคำสั่งซื้อนี้ใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('ยืนยัน'),
          ),
        ],
      ),
    );

    if (!confirmRefund) return; // ถ้าไม่ยืนยัน ให้ออกไปเลย

    try {
      final response = await http.put(
        Uri.parse('http://10.0.2.2:3000/refundOrderAdmin'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'orderRef': orderRef}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('คืนเงินสำเร็จ')),
        );

        // กลับไปหน้า OrdersCancelPage และรีเฟรช
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => OrdersCancelPage()),
          (Route<dynamic> route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('คืนเงินไม่สำเร็จ')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการคืนเงิน')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('คืนเงินคำสั่งซื้อ', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefundOrderCard(
        order: order,
        onRefund: processRefund,
      ),
    );
  }
}

class RefundOrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final Function(String) onRefund;

  const RefundOrderCard({required this.order, required this.onRefund});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(
                    order['profile_picture'] ?? 'https://via.placeholder.com/150',
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  order['ordered_by'] ?? 'Unknown',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Spacer(),
                Text(
                  "ยกเลิกแล้ว",
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 16),
            Image.network(
              order['product_image'] ?? 'https://via.placeholder.com/300',
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            SizedBox(height: 16),
            Text(
              order['productName'] ?? 'ไม่มีชื่อสินค้า',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("x ${order['quantity']}"),
                Text(
                  "฿${double.tryParse(order['product_price']?.toString() ?? '0')?.toStringAsFixed(2) ?? '0.00'}",
                  style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("รวมคำสั่งซื้อ:"),
                Text(
                  "฿${(order['total'] != null ? double.tryParse(order['total'].toString())?.toStringAsFixed(2) : '0.00')}",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            Divider(),
            // 🔹 เพิ่มกรอบสีชมพูให้ข้อมูลบัญชีธนาคาร
            SizedBox(height: 16),
            Center(
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.pink, width: 2),
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.pink.shade50, // สีพื้นหลังอ่อน
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        "รายละเอียดข้อมูลชำระเงิน",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.pink),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text("ธนาคาร: ${order['bankname'] ?? 'ไม่พบข้อมูล'}"),
                    Text("ชื่อบัญชี: ${order['account_name'] ?? 'ไม่พบข้อมูล'}"),
                    Text("เลขบัญชี: ${order['banknumber'] ?? 'ไม่พบข้อมูล'}"),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Spacer(),
                ElevatedButton(
                  onPressed: () => onRefund(order['order_ref']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: Text("ยืนยันคืนเงิน", style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
