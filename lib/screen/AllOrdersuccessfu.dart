import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:loginsystem/screen/MyReviews.dart';

class SuccessAndReviewPage extends StatefulWidget {
  const SuccessAndReviewPage({Key? key, required this.userEmail}) : super(key: key);

  final String userEmail;

  @override
  _SuccessAndReviewPageState createState() => _SuccessAndReviewPageState();
}

class _SuccessAndReviewPageState extends State<SuccessAndReviewPage> {
  List<dynamic> orders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchSuccessAndReviewOrders();
  }

  Future<void> fetchSuccessAndReviewOrders() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/SuccessAndReviewOrdersAdmin'), // ✅ URL ของ API
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          orders = data['orders'];
          isLoading = false;
        });
      } else {
        final error = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error['message'] ?? 'Failed to fetch orders.')),
        );
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
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
        title: const Text(
          'คำสั่งซื้อที่สำเร็จทั้งหมด',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
              ? const Center(child: Text('ไม่มีคำสั่งซื้อที่สำเร็จหรือให้คะแนน'))
              : ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return OrderCard(
                      order: order,
                      onOrderReceived: () {
                        if (order['status'] == 'ให้คะแนน') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MyReviewsPage(
                                userEmail: widget.userEmail,
                                orderRef: order['order_ref'],
                              ),
                            ),
                          );
                        }
                      },
                      showReviewButton: order['status'] == 'ให้คะแนน',
                    );
                  },
                ),
    );
  }
}

class OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onOrderReceived;
  final bool showReviewButton;

  const OrderCard({
    Key? key,
    required this.order,
    required this.onOrderReceived,
    this.showReviewButton = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formatter = new NumberFormat("#,##0.00", "th");
    return Card(
      margin: const EdgeInsets.all(8.0),
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
                const SizedBox(width: 8),
                Text(
                  order['ordered_by'] ?? 'Unknown',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                Text(
                  order['status'] == 'คำสั่งซื้อสำเร็จ'
                      ? 'คำสั่งซื้อสำเร็จ'
                      : 'ให้คะแนน',
                  style: const TextStyle(color: Colors.pink, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Image.network(
              order['product_image']?.startsWith('http') == true
                  ? order['product_image']
                  : 'https://via.placeholder.com/300', // รูปภาพสำรอง
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 16),
            Text(
              order['productName'] ?? 'No product name',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Divider(),
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text("x ${order['quantity']}"), // ✅ จำนวนสินค้า

    SizedBox(height: 4), // ✅ เพิ่มระยะห่าง

    Row(
      mainAxisAlignment: MainAxisAlignment.end, // ✅ ชิดขวา
      children: [
        Text(
          "${formatter.format(double.tryParse(order['product_price']?.toString() ?? '0') ?? 0.00)}",
          style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold),
        ), // ✅ ราคาสินค้า
      ],
    ),

    SizedBox(height: 4), // ✅ เพิ่มระยะห่าง

    Row(
      mainAxisAlignment: MainAxisAlignment.end, // ✅ ชิดขวา
      children: [
        Text(
          "รวมทั้งหมด: ${order['total'] != null ? formatter.format(double.tryParse(order['total'].toString()) ?? 0.00) : '0.00'}",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ), // ✅ ราคารวมทั้งหมด
      ],
    ),
  ],
),


            const SizedBox(height: 10),

            // ✅ เพิ่มส่วนแสดง Tracking Number
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("เลขพัสดุ:", style: TextStyle(color: Colors.grey)),
                Text(
                  order['trackingnumber'] ?? 'ยังไม่มีเลขพัสดุ',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
            
            // ✅ แสดงหมายเลขอ้างอิง (ref)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("หมายเลขคำสั่งซื้อ:", style: TextStyle(color: Colors.grey)),
                Text(
                  order['order_ref'] ?? 'ไม่มีหมายเลขอ้างอิง',
                  style: TextStyle(color: Colors.black),
                ),
              ],
            ),

            const SizedBox(height: 16),
            if (showReviewButton)
              Center(
                child: ElevatedButton(
                  onPressed: onOrderReceived,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text(
                    'ให้คะแนน',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
