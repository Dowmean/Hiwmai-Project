import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:loginsystem/screen/Refund.dart';
import 'dart:convert';

class OrdersCancelPage extends StatefulWidget {
  @override
  _OrdersCancelPageState createState() => _OrdersCancelPageState();
}

class _OrdersCancelPageState extends State<OrdersCancelPage> {
  List<dynamic> canceledOrders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCanceledOrders();
  }

  Future<void> fetchCanceledOrders() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/OrderscancleAdmin'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          canceledOrders = data['orders'];
          isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่พบคำสั่งซื้อที่ถูกยกเลิก')),
        );
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      //print('Error fetching canceled orders: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล')),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          'คำสั่งซื้อที่ถูกยกเลิก',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : canceledOrders.isEmpty
              ? Center(child: Text('ไม่มีคำสั่งซื้อที่ถูกยกเลิก'))
              : ListView.builder(
                  itemCount: canceledOrders.length,
                  itemBuilder: (context, index) {
                    final order = canceledOrders[index];
                    return OrderCard(
                      order: order,
                      onNavigateRefund: () {
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => RefundPage(order: order),
  ),
);

                      },
                    );
                  },
                ),
    );
  }
}

class OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onNavigateRefund;

  const OrderCard({required this.order, required this.onNavigateRefund});

  @override
  Widget build(BuildContext context) {
    final formatter = new NumberFormat("#,##0.00", "th");
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
                  "ถูกยกเลิก",
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
  "${formatter.format(double.tryParse(order['product_price']?.toString() ?? '0') ?? 0.00)}",
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
  "รวมทั้งหมด: ${order['total'] != null ? formatter.format(double.tryParse(order['total'].toString()) ?? 0.00) : '0.00'}",
  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
),
              ],
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: onNavigateRefund,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: Text("คืนเงิน", style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}