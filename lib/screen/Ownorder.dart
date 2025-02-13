//Recipt
import 'package:flutter/material.dart'; 
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';

import 'package:loginsystem/screen/AddParcel.dart';
import 'package:loginsystem/screen/Receiving.dart';
import 'package:loginsystem/screen/Review.dart';
import 'package:loginsystem/screen/Shipping.dart';

class OrdersPage extends StatefulWidget {
  @override
  _OrdersPageState createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> with SingleTickerProviderStateMixin {
  List<dynamic> orders = [];
  bool isLoading = true;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: 0);
    fetchOrders();
  }


Future<void> fetchOrders() async {
  final User? user = _auth.currentUser;
  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('กรุณาเข้าสู่ระบบเพื่อดูคำสั่งซื้อ')),
    );
    return;
  }

  final email = user.email;

  try {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:3000/getToshipOrdersByEmail?email=$email'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        orders = data['orders'];
        isLoading = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('การดึงข้อมูลคำสั่งซื้อไม่สำเร็จ')),
      );
      setState(() {
        isLoading = false;
      });
    }
  } catch (e) {
    //print('Error fetching to-ship orders: $e');
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(content: Text('เกิดข้อผิดพลาดในการดึงข้อมูลคำสั่งซื้อ')),
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
        automaticallyImplyLeading: false, // ลบปุ่มย้อนกลับ
        centerTitle: true, 
        title: Text('คำสั่งซื้อ', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
bottom: TabBar(
  controller: _tabController,
  labelColor: Colors.pink,
  unselectedLabelColor: Colors.grey,
  indicatorColor: Colors.pink,
  tabs: [
    Tab(text: 'ที่ต้องจัดส่ง'),
    Tab(text: 'กำลังจัดส่ง'),
    Tab(text: 'สำเร็จ'),
    Tab(text: 'ให้คะแนน'),
  ],
),

      ),
body: TabBarView(
  controller: _tabController,
  children: [
    buildOrderList(context, orders), // ดึงเฉพาะสถานะ "ที่ต้องจัดส่ง"
    ShippingPage(), // กำลังจัดส่ง
    ReceivingPage(), // สำเร็จ
    ReviewPage(), // ให้คะแนน
  ],
),




    );
  }

Widget buildOrderList(BuildContext context, List<dynamic> filteredOrders) {
  return isLoading
      ? Center(child: CircularProgressIndicator())
      : filteredOrders.isEmpty
          ? Center(child: Text('ไม่มีคำสั่งซื้อ'))
          : ListView.builder(
              itemCount: filteredOrders.length,
              itemBuilder: (context, index) {
                final order = filteredOrders[index];
                return OrderCard(
  order: order,
  onCancel: () {
    fetchOrders(); // รีเฟรชรายการคำสั่งซื้อ
  },
);

              },
            );
}

}

class OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onCancel;

  const OrderCard({required this.order, required this.onCancel});
String calculateDueDate(String? shopDate) {
  if (shopDate == null || shopDate.isEmpty) {
    return "ไม่พบวันที่ในการคำนวณ";
  }
  try {
    final date = DateTime.parse(shopDate);
    final dueDate = date.add(Duration(days: 7));
    final now = DateTime.now();
    final difference = dueDate.difference(now);

    if (difference.isNegative) {
      return "การจัดส่งล่าช้าจะทำให้ได้รับสินค้าช้ากว่ากำหนด";
    } else {
      final days = difference.inDays;
      final hours = difference.inHours % 24;
      final minutes = difference.inMinutes % 60;
      final seconds = difference.inSeconds % 60;

      return "กรุณาจัดส่งภายในอีก $days วัน $hours ชั่วโมง $minutes นาที $seconds วินาที";
    }
  } catch (e) {
    //print("Error parsing date: $e");
    return "วันที่ไม่ถูกต้อง";
  }
}
Future<bool> cancelOrder(String orderRef) async {
  try {
    final response = await http.put(
      Uri.parse('http://10.0.2.2:3000/cancelOrder'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'orderRef': orderRef}),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      //print('Failed to cancel order: ${response.body}');
      return false;
    }
  } catch (e) {
    //print('Error canceling order: $e');
    return false;
  }
}

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
                  "ที่ต้องจัดส่ง",
                  style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold),
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
                Text("1 ชิ้น"),
Text(
  "รวมทั้งหมด: ${order['total'] != null ? formatter.format(double.tryParse(order['total'].toString()) ?? 0.00) : '0.00'}",
  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
),
              ],
            ),
            SizedBox(height: 16),
Text(
  calculateDueDate(order['shopdate'] ?? ''),
  style: TextStyle(color: Colors.red, fontSize: 14),
),

            SizedBox(height: 16),
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    ElevatedButton(
      onPressed: () async {
        final result = await cancelOrder(order['order_ref']);
        if (result) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('คำสั่งซื้อถูกยกเลิกเรียบร้อย')),
          );
          onCancel(); // รีเฟรชคำสั่งซื้อ
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('การยกเลิกคำสั่งซื้อไม่สำเร็จ')),
          );
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      ),
      child: Text("ยกเลิก", style: TextStyle(fontSize: 16,color: Colors.red)),
    ),
ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddParcelPage(
          ref: order['order_ref'] ?? '', // ส่งค่า order_ref ไปยัง AddParcelPage
        ),
      ),
    );
  },
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.pink,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
  ),
  child: Text("จัดส่งสินค้า", style: TextStyle(fontSize: 16, color: Colors.white)),
),

  ],
),
            SizedBox(height: 16),
            Text(
              "หมายเลขคำสั่งซื้อ: ${order['order_ref'] ?? '-'}",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}