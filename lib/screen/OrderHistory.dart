import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class OrderHistoryPage extends StatefulWidget {
  @override
  _OrderHistoryPageState createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  List<dynamic> orders = [];
  bool isLoading = true;
  String? userRole;
  String? userEmail;

  @override
  void initState() {
    super.initState();
    fetchUserRoleAndOrders();
  }

  // ✅ ฟังก์ชันดึง `role` และ `email` ของผู้ใช้
  Future<void> fetchUserRoleAndOrders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    userEmail = user.email;

    if (userEmail != null) {
      final role = await fetchUserRole(userEmail!);
      setState(() {
        userRole = role;
      });

      // ✅ เมื่อได้ role แล้ว เรียก API ตามบทบาท
      fetchOrdersByRole();
    }
  }

  // ✅ ฟังก์ชันดึง `role` ของผู้ใช้จาก API
  Future<String?> fetchUserRole(String email) async {
    final response = await http.get(Uri.parse('http://10.0.2.2:3000/getUserRole?email=$email'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['role'];
    } else {
      return null;
    }
  }

  // ✅ ฟังก์ชันดึงข้อมูลคำสั่งซื้อ ตาม `role`
  Future<void> fetchOrdersByRole() async {
    if (userRole == null || userEmail == null) return;

    String apiUrl = '';

    if (userRole == 'Admin') {
      apiUrl = 'http://10.0.2.2:3000/OrderHistoryAdmin';
    } else if (userRole == 'User') {
      apiUrl = 'http://10.0.2.2:3000/OrderHistoryUser?email=$userEmail';
    } else if (userRole == 'Recipient') {
      apiUrl = 'http://10.0.2.2:3000/OrderHistoryRecipient?email=$userEmail';
    }

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          orders = data['orders'];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch orders.')),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred while fetching orders.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          'คำสั่งซื้อทั้งหมด',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : orders.isEmpty
              ? Center(child: Text('No orders available.'))
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

// ✅ UI สำหรับแสดงรายการคำสั่งซื้อ
class OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

                // ✅ แสดง "สถานะ" สีชมพู
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.pink.withOpacity(0.1), // สีพื้นหลังอ่อนๆ
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    order['status'] ?? 'ไม่มีสถานะ',
                    style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold),
                  ),
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
          ],
        ),
      ),
    );
  }
}
