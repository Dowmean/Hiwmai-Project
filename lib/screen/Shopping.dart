import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class OrderPage extends StatefulWidget {
  final int productId; // รับ productId เท่านั้น

  OrderPage({required this.productId}); // ไม่มีพารามิเตอร์ product

  @override
  _OrderPageState createState() => _OrderPageState();
}
class _OrderPageState extends State<OrderPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController noteController = TextEditingController();
  int quantity = 1; // จำนวนสินค้าเริ่มต้น
  double total = 0.0; // ราคารวม
  String email = '';
  Map<String, dynamic>? product; // เก็บข้อมูลสินค้า
  final String baseUrl = 'http://10.0.2.2:3000'; // URL ของ backend

  @override
  void initState() {
    super.initState();
    _fetchEmail();
    _fetchProduct(); // ดึงข้อมูลสินค้าจาก API
  }

  Future<void> _fetchEmail() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        email = user.email ?? '';
        nameController.text = user.displayName ?? ''; // ชื่อจาก Firebase
      });
    }
  }

Future<void> _fetchProduct() async {
  try {
    final response =
        await http.get(Uri.parse('$baseUrl/product/${widget.productId}'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        product = data;
        final double price = double.tryParse(product!['price'].toString()) ?? 0.0;
        final double shipping = double.tryParse(product!['shipping'].toString()) ?? 0.0;
        final double carry = double.tryParse(product!['carry'].toString()) ?? 0.0;

        // คำนวณ total โดยรวมค่าขนส่งและค่าบริการ
        total = (price * quantity) + shipping + carry;
      });
    } else {
      print('Failed to fetch product: ${response.body}');
    }
  } catch (e) {
    print('Error fetching product: $e');
  }
}


void _updateTotal() {
  setState(() {
    final double price = double.tryParse(product!['price'].toString()) ?? 0.0;
    final double shipping = double.tryParse(product!['shipping'].toString()) ?? 0.0;
    final double carry = double.tryParse(product!['carry'].toString()) ?? 0.0;

    // คำนวณ total ใหม่
    total = (price * quantity) + shipping + carry;
  });
}



  Future<void> _createOrder(BuildContext context) async {
    if (product == null) return;

final double price = double.tryParse(product!['price'].toString()) ?? 0.0;
  final double shipping = double.tryParse(product!['shipping'].toString()) ?? 0.0;
  final double carry = double.tryParse(product!['carry'].toString()) ?? 0.0;

  // คำนวณ total อย่างถูกต้อง
  final double calculatedTotal = (price * quantity) + shipping + carry;

  final orderData = {
    'email': email,
    'name': nameController.text,
    'address': addressController.text,
    'phone_number': phoneController.text,
    'total': calculatedTotal, // ส่ง total เป็นตัวเลข
    'num': quantity,
    'note': noteController.text,
    'product_id': widget.productId,
    'image': product!['imageUrl'],
  };

  try {
    final response = await http.post(
      Uri.parse('$baseUrl/createOrder'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(orderData),
    );

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('คำสั่งซื้อสำเร็จ!')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ไม่สามารถสั่งซื้อได้: ${response.body}')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
    );
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('สั่งซื้อสินค้า'),
        backgroundColor: Colors.pink,
      ),
      body: product == null
          ? Center(child: CircularProgressIndicator()) // แสดง Loading ขณะโหลดข้อมูล
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // รายละเอียดสินค้า
                  Text(
                    product!['productName'] ?? '',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "฿${(double.tryParse(product!['price'].toString()) ?? 0.0).toStringAsFixed(2)}",
                    style: TextStyle(fontSize: 18, color: Colors.pink),
                  ),
                  SizedBox(height: 20),
                  SizedBox(height: 10),
Text(
  'ค่าขนส่ง: ฿${(double.tryParse(product!['shipping'].toString()) ?? 0.0).toStringAsFixed(2)}',
  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
),
SizedBox(height: 10),
Text(
  'ค่าบริการเพิ่มเติม: ฿${(double.tryParse(product!['carry'].toString()) ?? 0.0).toStringAsFixed(2)}',
  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
),
SizedBox(height: 20),


                  // ฟอร์มสำหรับกรอกข้อมูล
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: 'ชื่อผู้สั่งซื้อ'),
                  ),
                  TextField(
                    controller: addressController,
                    decoration: InputDecoration(labelText: 'ที่อยู่'),
                    maxLines: 3,
                  ),
                  TextField(
                    controller: phoneController,
                    decoration: InputDecoration(labelText: 'เบอร์โทรศัพท์'),
                    keyboardType: TextInputType.phone,
                  ),
                  SizedBox(height: 10),

                  // หมายเหตุ
                  TextField(
                    controller: noteController,
                    decoration:
                        InputDecoration(labelText: 'หมายเหตุถึงผู้ขาย (ถ้ามี)'),
                    maxLines: 2,
                  ),
                  SizedBox(height: 20),

                  // จำนวนสินค้า
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('จำนวนสินค้า', style: TextStyle(fontSize: 16)),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.remove_circle_outline),
                            onPressed: () {
                              if (quantity > 1) {
                                setState(() {
                                  quantity--;
                                  _updateTotal();
                                });
                              }
                            },
                          ),
                          Text('$quantity', style: TextStyle(fontSize: 18)),
                          IconButton(
                            icon: Icon(Icons.add_circle_outline),
                            onPressed: () {
                              setState(() {
                                quantity++;
                                _updateTotal();
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),

                  // ราคารวม
                  SizedBox(height: 10),
                  Text(
                    'ราคารวม: ฿${total.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  // ปุ่มสั่งซื้อ
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      if (addressController.text.isEmpty ||
                          phoneController.text.isEmpty ||
                          nameController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบถ้วน')),
                        );
                        return;
                      }
                      _createOrder(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                      padding:
                          EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    ),
                    child: Text(
                      'ยืนยันการสั่งซื้อ',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
