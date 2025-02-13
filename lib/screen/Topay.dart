import 'package:flutter/material.dart'; 
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class ToPayOrdersPage extends StatefulWidget {
  @override
  _ToPayOrdersPageState createState() => _ToPayOrdersPageState();
}

class _ToPayOrdersPageState extends State<ToPayOrdersPage> {
  List<dynamic> orders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchToPayOrders();
  }

  Future<void> fetchToPayOrders() async {
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2:3000/ToPayOrders'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        setState(() {
          orders = data['orders'] ?? []; // ✅ ป้องกันกรณี `null`
          isLoading = false;
        });
      } else {
        setState(() {
          orders = [];
          isLoading = false;
        });
      }
    } catch (e) {
      print("❌ Error fetching orders: $e");
      setState(() {
        orders = [];
        isLoading = false;
      });
    }
  }

  Future<void> updateOrderStatus(String orderRef) async {
    try {
      final response = await http.put(
        Uri.parse('http://10.0.2.2:3000/updateOrderStatus'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'orderRef': orderRef}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order status updated successfully.')),
        );

        fetchToPayOrders(); // ✅ รีเฟรชรายการหลังอัปเดต
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update order status.')),
        );
      }
    } catch (e) {
      print("❌ Error updating order status: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          'คำสั่งซื้อที่ยังไม่ชำระเงิน',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : orders.isEmpty
              ? Center(
                  child: Text(
                    'ไม่มีรายการสั่งซื้อ',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return OrderCard(
                      order: order,
                      onRefresh: fetchToPayOrders,
                      onUpdateStatus: updateOrderStatus,
                    );
                  },
                ),
    );
  }
}

class OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onRefresh;
  final Function(String) onUpdateStatus;

  const OrderCard({required this.order, required this.onRefresh, required this.onUpdateStatus});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat("#,##0.00", "th");
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
                  "รอตรวจสอบ",
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
                  "฿${formatter.format(double.tryParse(order['product_price']?.toString() ?? '0') ?? 0.00)}",
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
                  "฿${formatter.format(double.tryParse(order['total']?.toString() ?? '0') ?? 0.00)}",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                try {
                  final response = await http.put(
                    Uri.parse('http://10.0.2.2:3000/updateOrderStatus'),
                    headers: {'Content-Type': 'application/json'},
                    body: json.encode({'orderRef': order['order_ref']}),
                  );

                  if (response.statusCode == 200) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Order status updated successfully.')),
                    );

                    onRefresh(); // ✅ รีเฟรชข้อมูล
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update order status.')),
                    );
                  }
                } catch (e) {
                  print("❌ Error updating order status: $e");
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: Text("ยืนยันการชำระเงิน", style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
