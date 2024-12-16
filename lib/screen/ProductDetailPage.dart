import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:loginsystem/screen/ProfileView.dart';
import 'PostService.dart';

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
  late Map<String, dynamic> product;
  bool isFavorite = false;
  String email = ''; // Will fetch from Firebase Authentication
  final String baseUrl = 'http://10.0.2.2:3000'; // API Base URL

  @override
  void initState() {
    super.initState();
    product = widget.product;
    isFavorite = product['isFavorite'] ?? false;
    _fetchEmail();
    _checkFavoriteStatus();
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
                // Profile Picture - ทำให้กดแล้ว navigate ไปหน้า ProfileView
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
                        ? MemoryImage(base64Decode(product['profilePicture']))
                        : AssetImage('assets/avatar.png') as ImageProvider,
                    radius: 24,
                  ),
                ),
                SizedBox(width: 8),
                // User Name - ทำให้กดแล้ว navigate ไปหน้า ProfileView
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ProfileView(email: product['email']),
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
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
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
                      // Revert UI state if the operation fails
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
            // Icon(
            //   Icons.shopping_bag_outlined, // ใช้ไอคอนกระเป๋าช้อปปิ้ง
            //   size: 30, // ขนาดของไอคอน
            //   color: Colors.grey, // สีของไอคอน
            // ),
            Text(
              product['category'] ?? '',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            SizedBox(height: 20),
            Text(
              "รายละเอียด " ?? '',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              product['productDescription'] ?? '',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
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
      final imageData = base64Decode(imageUrl);
      return Image.memory(
        imageData,
        fit: BoxFit.cover,
        height: 300,
        width: double.infinity,
      );
    } catch (e) {
      print('Error decoding image: $e');
      return Container(
        color: Colors.grey[200],
        height: 300,
        width: double.infinity,
        child: Icon(Icons.broken_image, size: 100),
      );
    }
  }

  // Helper function to pick an image and return it as Base64
  Future<String?> _pickImage() async {
    try {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        return "data:image/png;base64,${base64Encode(bytes)}";
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
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  items: [
                    DropdownMenuItem(
                        value: 'เสื้อผ้า', child: Text('เสื้อผ้า')),
                    DropdownMenuItem(value: 'รองเท้า', child: Text('รองเท้า')),
                    DropdownMenuItem(value: 'ความงาม', child: Text('ความงาม')),
                    DropdownMenuItem(value: 'กระเป๋า', child: Text('กระเป๋า')),
                  ],
                  onChanged: (String? value) {
                    selectedCategory = value;
                  },
                ),
                SizedBox(height: 16),
                Text('รูปภาพสินค้า'),
                GestureDetector(
                  onTap: () async {
                    final pickedImage = await _pickImage();
                    if (pickedImage != null) {
                      setState(() {
                        updatedImageBase64 = pickedImage;
                      });
                    }
                  },
                  child: Container(
                    height: 120,
                    child: updatedImageBase64 != null
                        ? Image.memory(
                            base64Decode(updatedImageBase64!.split(',').last),
                            fit: BoxFit.cover,
                          )
                        : (product['imageUrl'] != null
                            ? Image.memory(
                                base64Decode(
                                    product['imageUrl'].split(',').last),
                                fit: BoxFit.cover,
                              )
                            : Icon(Icons.add_photo_alternate_outlined,
                                size: 40)),
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
                    price: double.tryParse(priceController.text) ??
                        product['price'],
                    category: selectedCategory!,
                    imageUrl: updatedImageBase64 ?? product['imageUrl'],
                  );
                  setState(() {
                    product['productName'] = productNameController.text;
                    product['productDescription'] =
                        productDescriptionController.text;
                    product['price'] = double.tryParse(priceController.text) ??
                        product['price'];
                    product['category'] = selectedCategory;
                  });
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
          content: Text('คุณแน่ใจหรือไม่ว่าต้องการลบสินค้านี้?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await PostService().deletePost(product['id']);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('ลบสินค้าสำเร็จ!')),
                  );
                  Navigator.pop(context);
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
