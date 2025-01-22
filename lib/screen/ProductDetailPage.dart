import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:loginsystem/screen/ProfileView.dart';
import 'package:loginsystem/screen/Shopping.dart';
import 'package:loginsystem/screen/PostService.dart';

class ProductDetailPage extends StatefulWidget {
  final Map<String, dynamic> product;
  final Function(Map<String, dynamic>) onFavoriteUpdate;

  ProductDetailPage({
    required this.product,
    required this.onFavoriteUpdate,
  });

  @override
  _ProductDetailPageState createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  String? updatedImagePath; // ใช้เก็บ path ของภาพที่เลือก
  late Map<String, dynamic> product;
  bool isFavorite = false;
  String email = ''; // Will fetch from Firebase Authentication
  String? currentUserRole;
  final String baseUrl = 'http://10.0.2.2:3000';

  String? get imageUrl => null; // API Base URL
@override
void initState() {
  super.initState();
  product = widget.product;
  _fetchProductDetails(); // เรียก API เพื่อดึงข้อมูลล่าสุด
  isFavorite = product['isFavorite'] ?? false;
  _fetchEmail();
  _checkFavoriteStatus();
}

  Future<void> _fetchUserRole() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/getUserRole?email=$email'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          currentUserRole = data['role'];
        });
      } else {
        print('Failed to fetch user role: ${response.body}');
      }
    } catch (e) {
      print('Error fetching user role: $e');
    }
  }
Future<void> _fetchProductDetails() async {
  try {
    final response = await http.get(Uri.parse('$baseUrl/product/${product['id']}'));

    if (response.statusCode == 200) {
      final updatedProduct = json.decode(response.body);

      setState(() {
        product = {
          ...updatedProduct,
          'profilePicture': updatedProduct['profilePicture'] ??
              'assets/avatar.png', // กำหนดค่าเริ่มต้นสำหรับ profilePicture
        };
      });
    } else {
      print('Failed to fetch product details: ${response.body}');
    }
  } catch (e) {
    print('Error fetching product details: $e');
  }
}



  Future<void> _fetchEmail() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        email = user.email ?? '';
      });
      print('Fetched email from Firebase: $email');
    } else {
      print('No user is currently logged in.');
    }
  }

  Future<void> toggleFavoriteStatus({
    required String email,
    required int productId,
    required bool isFavorite,
  }) async {
    final String apiUrl = '$baseUrl/toggleFavorite';
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          'email': email,
          'product_id': productId,
          'is_favorite': isFavorite,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to toggle favorite status: ${response.body}');
      }
    } catch (e) {
      print("Error toggling favorite status: $e");
      throw Exception('Error toggling favorite status');
    }
  }

  Future<void> _checkFavoriteStatus() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/favorites?email=$email'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          // ตรวจสอบว่ารายการสินค้านี้อยู่ในรายการโปรดหรือไม่
          isFavorite = data.any((fav) => fav['product_id'] == product['id']);
        });
      } else {
        print('Failed to fetch favorite status: ${response.body}');
      }
    } catch (e) {
      print('Error fetching favorite status: $e');
    }
  }

  Future<bool> _canEditOrDelete(String email, int productId) async {
    final String apiUrl = '$baseUrl/checkRoleAndOwnership';
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          'email': email,
          'product_id': productId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['canEditOrDelete'] == true;
      } else {
        print('Failed to check role: ${response.body}');
        return false;
      }
    } catch (e) {
      print("Error checking role: $e");
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(product['productName'] ?? 'Product Details'),
        actions: [
          FutureBuilder<bool>(
            future: _canEditOrDelete(email, product['id']),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SizedBox(); // รอโหลดข้อมูล
              }

              if (snapshot.hasData && snapshot.data == true) {
                return PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') showEditDialog(context);
                    if (value == 'delete') _confirmDelete(context);
                  },
                  itemBuilder: (BuildContext context) {
                    return [
                      PopupMenuItem(value: 'edit', child: Text('แก้ไข')),
                      PopupMenuItem(value: 'delete', child: Text('ลบ')),
                    ];
                  },
                );
              }

              // ซ่อนเมนูถ้าผู้ใช้ไม่มีสิทธิ์
              return SizedBox.shrink();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Profile Picture
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileView(email: product['email'] ?? ''),
                      ),
                    );
                  },
                  child: CircleAvatar(
  backgroundImage: product['profilePicture'] != null &&
          product['profilePicture'].isNotEmpty
      ? (product['profilePicture'].startsWith('http')
          ? NetworkImage(product['profilePicture'])
          : MemoryImage(base64Decode(product['profilePicture'])))
      : AssetImage('assets/avatar.png') as ImageProvider,
  radius: 24,
)
,
                ),
                SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileView(email: product['email'] ?? ''),
                      ),
                    );
                  },
                  child: Text(
                    product['firstName'] ?? 'Unknown',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            _buildProductImage(product['imageUrl']),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    product['productName'] ?? '',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : Colors.grey,
                  ),
                  onPressed: () async {
                    try {
                      setState(() {
                        isFavorite = !isFavorite;
                      });

                      await toggleFavoriteStatus(
                        email: email,
                        productId: product['id'],
                        isFavorite: isFavorite,
                      );

                      widget.onFavoriteUpdate(product);
                    } catch (e) {
                      setState(() {
                        isFavorite = !isFavorite;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to update favorite status: $e'),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
            Text(
              "฿${product['price']}",
              style: TextStyle(fontSize: 18, color: Colors.pink),
            ),
            SizedBox(height: 10),
            Text(
              product['category'] ?? '',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            SizedBox(height: 20),
            Text(
              "รายละเอียด " ?? '',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
Text(
  product['productDescription'] ?? 'ไม่มีรายละเอียดสินค้า', // หากไม่มีค่าให้แสดงข้อความเริ่มต้น
  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
),

Text(
  "ค่าขนส่ง: ฿${double.tryParse(product['shipping']?.toString() ?? '0')?.toStringAsFixed(2) ?? '0.00'}",
  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
),
SizedBox(height: 10),
Text(
  "ค่าบริการเพิ่มเติม: ฿${double.tryParse(product['carry']?.toString() ?? '0')?.toStringAsFixed(2) ?? '0.00'}",
  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
),


          ],
        ),
      ),
      bottomNavigationBar: currentUserRole != 'Recipient' &&
              currentUserRole != 'Admin'
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: Colors.pink,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          OrderPage(productId: product['id']),
                    ),
                  );
                },
                child: Text(
                  'สั่งซื้อสินค้า',
                  style: TextStyle(fontSize: 18, color: Colors.white),
              ),
              ),
            )
          : SizedBox.shrink(), // กรณีที่ปุ่มถูกซ่อน
    );
  }

Widget _buildProductImage(String? imageUrl) {
  if (imageUrl == null || imageUrl.isEmpty) {
    return Container(
      color: Colors.grey[200],
      height: 300,
      width: double.infinity,
      child: Icon(Icons.broken_image, size: 100),
    );
  }

  try {
    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        height: 300,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) {
  return Container(
    color: Colors.grey[200],
    child: Icon(Icons.broken_image, size: 50),
  );
}
,
      );
    } else {
      return Image.memory(
        base64Decode(imageUrl),
        fit: BoxFit.cover,
        height: 300,
        width: double.infinity,
      );
    }
  } catch (e) {
    print('Error loading image: $e');
    return Container(
      color: Colors.grey[200],
      height: 300,
      width: double.infinity,
      child: Icon(Icons.broken_image, size: 100),
    );
  }
}


  // Helper function to pick an image and return it as Base64
  Future<void> _pickImage() async {
    try {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          var updatedImagePath = pickedFile.path; // บันทึก path ของรูปที่เลือก
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
    return null;
  }

void showEditDialog(BuildContext context) {
  final TextEditingController productNameController =
      TextEditingController(text: product['productName']);
  final TextEditingController productDescriptionController =
      TextEditingController(text: product['productDescription']);
  final TextEditingController priceController =
      TextEditingController(text: product['price'].toString());
  final TextEditingController shippingController =
      TextEditingController(text: product['shipping']?.toString() ?? '0.00');
  final TextEditingController carryController =
      TextEditingController(text: product['carry']?.toString() ?? '0.00');
  String? selectedCategory = product['category'];
  String? updatedImageBase64;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('แก้ไขสินค้า'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: productNameController,
                decoration: InputDecoration(labelText: 'ชื่อสินค้า'),
              ),
              TextField(
                controller: productDescriptionController,
                decoration: InputDecoration(labelText: 'รายละเอียดสินค้า'),
                maxLines: 3,
              ),
              TextField(
                controller: priceController,
                decoration: InputDecoration(labelText: 'ราคา'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: shippingController,
                decoration: InputDecoration(labelText: 'ค่าขนส่ง'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: carryController,
                decoration: InputDecoration(labelText: 'ค่าบริการเพิ่มเติม'),
                keyboardType: TextInputType.number,
              ),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                items: ['เสื้อผ้า', 'รองเท้า', 'ความงาม', 'กระเป๋า']
                    .map((value) => DropdownMenuItem(
                          value: value,
                          child: Text(value),
                        ))
                    .toList(),
                onChanged: (value) {
                  selectedCategory = value;
                },
              ),
              SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  final pickedFile =
                      await ImagePicker().pickImage(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    final bytes = await File(pickedFile.path).readAsBytes();
                    setState(() {
                      updatedImageBase64 = base64Encode(bytes);
                    });
                  }
                },
                child: Container(
                  height: 120,
                  child: updatedImageBase64 != null
                      ? Image.memory(
                          base64Decode(updatedImageBase64!),
                          fit: BoxFit.cover,
                        )
                      : (product['imageUrl'] != null
                          ? Image.network(
                              product['imageUrl'],
                              fit: BoxFit.cover,
                            )
                          : Icon(Icons.add_photo_alternate_outlined, size: 40)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await PostService().editPost(
                  product['id'],
                  productName: productNameController.text,
                  productDescription: productDescriptionController.text,
                  price: double.tryParse(priceController.text) ?? product['price'],
                  shipping: double.tryParse(shippingController.text) ?? 0.0,
                  carry: double.tryParse(carryController.text) ?? 0.0,
                  category: selectedCategory!,
                  imagePath: updatedImageBase64 ?? product['imageUrl'],
                );

                await _fetchProductDetails();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('แก้ไขสำเร็จ!')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('ไม่สามารถแก้ไขได้: $e')),
                );
              }
            },
            child: Text('บันทึก'),
          ),
        ],
      );
    },
  );
}


void _confirmDelete(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('ยืนยันการลบ'),
        content: Text('คุณแน่ใจหรือไม่ว่าต้องการลบสินค้า "${product['productName']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                Navigator.of(context).pop();
                await PostService().deletePost(product['id']);
                Navigator.pop(context, true);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('ลบสินค้าสำเร็จ!')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('ไม่สามารถลบสินค้าได้: $e')),
                );
              }
            },
            child: Text('ลบ'),
            ),
          ],
        );
      },
    );
  }
}
