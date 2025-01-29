import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:loginsystem/screen/MyReviews.dart';
import 'package:loginsystem/screen/OrderReview.dart';
import 'package:loginsystem/screen/ShippingUser.dart'; // Import Service

class PendingPaymentPage extends StatefulWidget {
    final String userEmail;
  final int initialTabIndex; // เพิ่มพารามิเตอร์สำหรับกำหนด Tab เริ่มต้น
    const PendingPaymentPage({
    Key? key,
    required this.userEmail, // กำหนดให้เป็น required
    this.initialTabIndex = 0, // ค่าเริ่มต้นเป็น 0 สำหรับ Tab แรก
  }) : super(key: key);

  @override
  _PendingPaymentPageState createState() => _PendingPaymentPageState();
}

class _PendingPaymentPageState extends State<PendingPaymentPage> 
with SingleTickerProviderStateMixin {
  List<dynamic> unpaidOrders = [];
  List<dynamic> shippingOrders = [];
  bool isLoadingUnpaid = true;
  bool isLoadingShipping = true;
  List<dynamic> successOrders = [];
  bool isLoadingSuccess = true;
  List<dynamic> reviewOrders = [];
  bool isLoadingReviewOrders = true;
  String userEmail = '';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // ใช้ค่า initialTabIndex ที่รับมา
    _tabController = TabController(
      length: 4, // จำนวน Tab ทั้งหมด
      vsync: this,
      initialIndex: widget.initialTabIndex, // ค่า Tab เริ่มต้น
    );
    fetchUserEmail();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

Future<void> fetchUserEmail() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        userEmail = user.email ?? '';
      });
      await fetchUnpaidOrders();
      await fetchShippingOrders();
      await fetchSuccessOrders(); // เรียกฟังก์ชันสำหรับคำสั่งซื้อสำเร็จ
      await fetchReviewOrders();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No user logged in.')),
      );
    }
  } catch (e) {
  }
}

//ยังไม่ชำระ
  Future<void> fetchUnpaidOrders() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/TopayOrdersByEmail?email=$userEmail'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          unpaidOrders = data['orders'];
          isLoadingUnpaid = false;
        });
      } else {
        final error = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error['message'] ?? 'Failed to fetch unpaid orders.')),
        );
        setState(() {
          isLoadingUnpaid = false;
        });
      }
    } catch (e) {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('An error occurred while fetching orders.')),
      // );
      setState(() {
        isLoadingUnpaid = false;
      });
    }
  }
//กำลังจัดส่ง
  Future<void> fetchShippingOrders() async {
    try {
      final ordersData = await ShippingService.fetchShippingOrders(userEmail);
      setState(() {
        shippingOrders = ordersData;
        isLoadingShipping = false;
      });
    } catch (e) {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text(e.toString())),
      // );
      setState(() {
        isLoadingShipping = false;
      });
    }
  }
//ยืนยันได้ระบสินค้า
Future<void> updateOrderStatus(String orderRef) async {
  try {
    final response = await http.put(
      Uri.parse('http://10.0.2.2:3000/updateSuccessOrderStatus'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'orderRef': orderRef}),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order status updated successfully.')),
      );

      // ลบคำสั่งซื้อที่อัปเดตแล้วออกจากรายการ "กำลังจัดส่ง"
      setState(() {
        shippingOrders.removeWhere((order) => order['order_ref'] == orderRef);
      });

      // รีเฟรชข้อมูล
      await fetchShippingOrders();
    } else {
      final error = json.decode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error['message'] ?? 'Failed to update order status.')),
      );
    }
  } catch (e) {
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(content: Text('An error occurred while updating the order status.')),
    // );
  }
}
//สำเร็จ
Future<void> fetchSuccessOrders() async {
  try {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:3000/SuccessOrdersByEmailUser?email=$userEmail'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        successOrders = data['orders'];
        isLoadingSuccess = false;
      });
    } else {
      final error = json.decode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error['message'] ?? 'Failed to fetch success orders.')),
      );
      setState(() {
        isLoadingSuccess = false;
      });
    }
  } catch (e) {
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(content: Text('An error occurred while fetching success orders.')),
    // );
    setState(() {
      isLoadingSuccess = false;
    });
  }
}
//รีวิว
Future<void> fetchReviewOrders() async {
  try {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:3000/ReviewsOrdersByEmailUser?email=$userEmail'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        reviewOrders = data['orders'];
        isLoadingReviewOrders = false;
      });
    } else {
      final error = json.decode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error['message'] ?? 'Failed to fetch review orders.')),
      );
      setState(() {
        isLoadingReviewOrders = false;
      });
    }
  } catch (e) {
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(content: Text('An error occurred while fetching review orders.')),
    // );
    setState(() {
      isLoadingReviewOrders = false;
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
          'คำสั่งซื้อของฉัน',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.pink,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.pink,
          tabs: [
            Tab(text: 'ที่ต้องชำระ'),
            Tab(text: 'กำลังจัดส่ง'),
            Tab(text: 'สำเร็จ'),
            Tab(text: 'ให้คะแนน'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: "ที่ต้องชำระ"
isLoadingUnpaid
    ? Center(child: CircularProgressIndicator())
    : unpaidOrders.isEmpty
        ? Center(child: Text('No unpaid orders available.'))
        : ListView.builder(
            itemCount: unpaidOrders.length,
            itemBuilder: (context, index) {
              final order = unpaidOrders[index];
              return OrderCard(
                order: order,
                onOrderReceived: () {}, // ส่ง Callback เปล่า
              );
            },
          ),


          // Tab 2: "กำลังจัดส่ง"
isLoadingShipping
    ? Center(child: CircularProgressIndicator())
    : shippingOrders.isEmpty
        ? Center(child: Text('No shipping orders available.'))
        : ListView.builder(
            itemCount: shippingOrders.length,
            itemBuilder: (context, index) {
              final order = shippingOrders[index];
              return OrderCard(
                order: order,
                onOrderReceived: () => updateOrderStatus(order['order_ref']),
              );
            },
          ),


// Tab 3: "สำเร็จ"
isLoadingSuccess
    ? Center(child: CircularProgressIndicator())
    : successOrders.isEmpty
        ? Center(child: Text('ไม่มีคำสั่งซื้อสำเร็จ'))
        : ListView.builder(
            itemCount: successOrders.length,
            itemBuilder: (context, index) {
              final order = successOrders[index];
              return OrderCard(
                order: order,
                onOrderReceived: () {}, // ไม่ต้องการ Callback ใน Tab นี้
              );
            },
          ),



// Tab 4: "ให้คะแนน"
isLoadingReviewOrders
    ? Center(child: CircularProgressIndicator())
    : reviewOrders.isEmpty
        ? Center(child: Text('ไม่มีคำสั่งซื้อให้คะแนน'))
        : ListView.builder(
            itemCount: reviewOrders.length,
            itemBuilder: (context, index) {
              final order = reviewOrders[index];
              return OrderCard(
                order: order,
                onOrderReceived: () {
                  // Navigate to MyReviewsPage
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MyReviewsPage(
                        userEmail: order['order_email'], // ส่งอีเมลผู้ใช้
                        orderRef: order['order_ref'], // ส่งหมายเลขคำสั่งซื้อ
                      ),
                    ),
                  );
                },
                showReviewButton: true, // แสดงปุ่ม "ให้คะแนน" ใน Tab นี้
              );
            },
          ),



        ],
      ),
    );
  }
}

class OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onOrderReceived; // เพิ่ม Callback สำหรับอัปเดตสถานะ
  final bool showReviewButton; // ควบคุมการแสดงปุ่ม "ให้คะแนน"
  final bool showDueDate; 


  const OrderCard({
    Key? key,
    required this.order,
    required this.onOrderReceived,
    this.showReviewButton = false,
    this.showDueDate = false, // ค่าเริ่มต้นคือไม่แสดงวันที่
  }) : super(key: key);

  String calculateDueDate(String? shopDate) {
    if (shopDate == null || shopDate.isEmpty) {
      return "No date available";
    }
    try {
      final date = DateTime.parse(shopDate);
      final dueDate = date.add(Duration(days: 7));
      final now = DateTime.now();
      final difference = dueDate.difference(now);

      if (difference.isNegative) {
        return "Past due date";
      } else {
        final days = difference.inDays;
        final hours = difference.inHours % 24;
        final minutes = difference.inMinutes % 60;

        return "$days days $hours hours $minutes minutes remaining";
      }
    } catch (e) {
      return "Invalid date";
    }
    
  }

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
  order['status'] == 'ยังไม่ชำระ'
      ? "กรุณาชำระเงิน"
      : order['status'] == 'กำลังจัดส่ง'
          ? "กำลังจัดส่งสินค้า"
          : order['status'] == 'สำเร็จ'
              ? "คำสั่งซื้อสำเร็จ"
              : order['status'] == 'ให้คะแนน'
                  ? "ให้คะแนนแล้ว"
                  : "สถานะไม่ทราบ",
  style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold),
),

              ],
            ),
            SizedBox(height: 16),
Image.network(
  order['product_image']?.startsWith('http') == true
      ? order['product_image']
      : 'https://via.placeholder.com/300', // ใช้รูปภาพสำรองหาก URL ไม่ถูกต้อง
  height: 150,
  width: double.infinity,
  fit: BoxFit.cover,
),

            SizedBox(height: 16),
            Text(
              order['productName'] ?? 'No product name',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text("Option: ${order['product_option'] ?? 'None'}"),
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
                Text("Total:"),
                Text(
                  "฿${(order['total'] != null ? double.tryParse(order['total'].toString())?.toStringAsFixed(2) : '0.00')}",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              "Order Ref: ${order['order_ref'] ?? '-'}",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
                        Divider(),
            // ปุ่ม "ให้คะแนน" แสดงเฉพาะใน Tab ให้คะแนน
            if (showReviewButton)
              Center(
                child: ElevatedButton(
                  onPressed: onOrderReceived, // Navigate ไป MyReviewsPage
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Text(
                    "คะแนน",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold,color: Colors.white),
                  ),
                ),
              ),

            SizedBox(height: 16),
if (order['status'] == 'ยังไม่ชำระ')
  Text(
    calculateDueDate(order['shopdate']),
    style: TextStyle(color: Colors.red, fontSize: 14),
  ),


if (order['status'] == 'กำลังจัดส่ง')
  ElevatedButton(
    onPressed: onOrderReceived, // เรียก Callback เมื่อกดปุ่ม
    child: Text("ได้รับสินค้าแล้ว"),
    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
  ),
if (order['status'] == 'คำสั่งซื้อสำเร็จ')
ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderReview(
          ref: order['order_ref'], // รหัสคำสั่งซื้อ
          productName: order['productName'], // ชื่อสินค้า
          productImage: order['product_image'], // URL รูปภาพสินค้า
          email: order['order_email'], // อีเมลของผู้ใช้
        ),
      ),
    );
  },
  child: Text("ให้คะแนน"),
  style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
),


          ],
        ),
      ),
    );
  }
}

