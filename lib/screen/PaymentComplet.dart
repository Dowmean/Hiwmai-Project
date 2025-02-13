import 'package:flutter/material.dart'; 
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:intl/intl.dart';

class PaymentCompletedPage extends StatefulWidget {
  @override
  _PaymentCompletedPageState createState() => _PaymentCompletedPageState();
}

class _PaymentCompletedPageState extends State<PaymentCompletedPage> {
  List<dynamic> orders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPaymentCompletedOrders();
  }

  Future<void> fetchPaymentCompletedOrders() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/TranfercompletedOrders'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          orders = data['orders'];
          isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch payment completed orders.')),
        );
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      //print('Error fetching payment completed orders: $e');
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('An error occurred while fetching orders.')),
      // );
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
        title: Text('ทำการจ่ายเรียบร้อยแล้ว', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : orders.isEmpty
              ? Center(child: Text('No payment completed orders available.'))
              : ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return OrderCard(order: order);
                  },
                ),
    );
  }
}

class OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderCard({required this.order});

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
                  "สำเร็จ",
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
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
              order['productName'] ?? 'No product name',
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
                        // ✅ เพิ่มส่วนแสดง Tracking Number
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("เลขพัสดุ:", style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  order['trackingnumber'] ?? 'ยังไม่มีเลขพัสดุ',
                  style: TextStyle(color: Colors.blue),
                ),
              ],
            ),
            
            // ✅ แสดงหมายเลขอ้างอิง (ref)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("หมายเลขคำสั่งซื้อ:", style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  order['order_ref'] ?? 'ไม่มีหมายเลขอ้างอิง',
                  style: TextStyle(color: Colors.black),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
