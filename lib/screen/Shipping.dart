import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:loginsystem/screen/Chat.dart';

class ShippingPage extends StatefulWidget {
  @override
  _ShippingPageState createState() => _ShippingPageState();
}

class _ShippingPageState extends State<ShippingPage>
    with SingleTickerProviderStateMixin {
  List<dynamic> shippingOrders = [];
  bool isLoading = true;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this, initialIndex: 0);
    fetchShippingOrders(); // เรียกใช้ API สำหรับดึงข้อมูลคำสั่งซื้อที่สถานะ "กำลังจัดส่ง"
  }

  Future<void> fetchShippingOrders() async {
    final User? user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please log in to view your orders')),
      );
      return;
    }

    final email = user.email;

    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/getShippingOrdersByEmailRecipient?email=$email'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          shippingOrders = data['orders'];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching shipping orders')),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : shippingOrders.isEmpty
              ? Center(child: Text('ไม่มีคำสั่งซื้อที่กำลังจัดส่ง'))
              : ListView.builder(
                  itemCount: shippingOrders.length,
                  itemBuilder: (context, index) {
                    final order = shippingOrders[index];
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
                    order['profile_picture'] ?? '',
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  order['ordered_by'] ?? 'Unknown',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Spacer(),
                Text(
                  "กำลังจัดส่ง",
                  style: TextStyle(
                      color: Colors.pink, fontWeight: FontWeight.bold),
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
            Text("ตัวเลือก: ${order['product_option'] ?? 'ไม่มี'}"),
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
    Text(
      "จำนวน: x${order['quantity'] ?? '1'}",
      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
    ),
Text(
  "รวมทั้งหมด: ${order['total'] != null ? formatter.format(double.tryParse(order['total'].toString()) ?? 0.00) : '0.00'}",
  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
),
              ],
            ),
            SizedBox(height: 16),
            Text(
              "หมายเลขคำสั่งซื้อ: ${order['order_ref'] ?? '-'}",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
                         SizedBox(height: 16),
            Text(
              "เลขพัสดุ: ${order['trackingnumber'] ?? 'ยังไม่มีเลขพัสดุ'}",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),           // ✅ เพิ่มส่วนแสดง Tracking Number

            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatPage(
                          receiverEmail: order['email'] ?? '',
                          firstName: order['ordered_by'] ?? 'Unknown',
                        ),
                      ),
                    );
                  },
                  
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                  ),
                  child: Text("ติดต่อ", style: TextStyle(color: Colors.white,fontSize: 16)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
