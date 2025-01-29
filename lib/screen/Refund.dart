import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RefundPage extends StatefulWidget {
  @override
  _RefundPageState createState() => _RefundPageState();
}

class _RefundPageState extends State<RefundPage> {
  List<dynamic> canceledOrders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCanceledOrders();
  }

  // ดึงข้อมูลคำสั่งซื้อที่ถูกยกเลิก
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
          SnackBar(content: Text('Failed to fetch canceled orders')),
        );
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      //print('Error fetching canceled orders: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred while fetching data.')),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  // อัปเดตสถานะคำสั่งซื้อเป็น "คืนเงินแล้ว"
  Future<void> processRefund(String orderRef) async {
    try {
      final response = await http.put(
        Uri.parse('http://10.0.2.2:3000/refundOrderAdmin'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'orderRef': orderRef}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Refund processed successfully')),
        );
        fetchCanceledOrders(); // รีเฟรชข้อมูลหลังจากคืนเงินแล้ว
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to process refund')),
        );
      }
    } catch (e) {
      //print('Error processing refund: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred while processing refund')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('คืนเงินคำสั่งซื้อ', style: TextStyle(fontWeight: FontWeight.bold)),
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
                    return RefundOrderCard(
                      order: order,
                      onRefund: processRefund,
                    );
                  },
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
            SizedBox(height: 16),
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
      ),
    );
  }
}
