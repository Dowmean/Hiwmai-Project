import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:loginsystem/screen/Payment.dart';

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
      //print('Failed to fetch product: ${response.body}');
    }
  } catch (e) {
    //print('Error fetching product: $e');
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
      // หลังจากสร้างคำสั่งซื้อสำเร็จ นำข้อมูลคำสั่งซื้อไปยังหน้า PaymentPage
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('คำสั่งซื้อสำเร็จ!')),
      );

      // เปลี่ยนไปหน้า PaymentPage พร้อมส่งข้อมูล orderData
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentPage(
            orderId: json.decode(response.body)['orderId'], // สมมติ response ส่ง orderId กลับมา
            total: calculatedTotal,
          ),
        ),
      );
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
      title: Text('รายละเอียดคำสั่งซื้อ'),
      backgroundColor: Colors.pink,
    ),
    body: product == null
        ? Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // หัวข้อที่อยู่จัดส่ง
                Card(
                  margin: EdgeInsets.only(bottom: 16.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ที่อยู่ในการจัดส่ง',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        SizedBox(height: 8),
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
                      ],
                    ),
                  ),
                ),
                // รายละเอียดสินค้า
                Card(
                  margin: EdgeInsets.only(bottom: 16.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        // รูปภาพสินค้า
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8.0),
                            image: DecorationImage(
                              image: NetworkImage(product!['imageUrl']),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        // ข้อมูลสินค้า
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product!['productName'],
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '฿${(double.tryParse(product!['price'].toString()) ?? 0.0).toStringAsFixed(2)}',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.pink),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'ค่าขนส่ง: ฿${(double.tryParse(product!['shipping'].toString()) ?? 0.0).toStringAsFixed(2)}',
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey[600]),
                              ),
                              Text(
                                'ค่าบริการเพิ่มเติม: ฿${(double.tryParse(product!['carry'].toString()) ?? 0.0).toStringAsFixed(2)}',
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
                SizedBox(height: 16),
                // ราคารวม
                Text(
                  'รวมคำสั่งซื้อ: ฿${total.toStringAsFixed(2)}',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.pink),
                ),
                SizedBox(height: 16),
                // ปุ่มยืนยันคำสั่งซื้อ
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
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'ยืนยันคำสั่งซื้อ',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
  );
}

}
