import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ใช้ Firebase Authentication
import 'ProductService.dart';

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
  String email = ''; // จะดึงข้อมูลจาก Firebase Authentication

  @override
  void initState() {
    super.initState();
    product = widget.product;
    isFavorite = product['isFavorite'] ?? false;
    _fetchEmail(); // ดึงอีเมลจาก Firebase Authentication
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

  Future<void> toggleFavorite() async {
    try {
      if (email.isEmpty) {
        throw Exception('Email is missing');
      }

      final dynamic productId = product['id'];

      // แปลง productId ให้เป็น int ถ้าจำเป็น
      int parsedProductId;
      if (productId is String) {
        parsedProductId = int.parse(productId);
      } else if (productId is int) {
        parsedProductId = productId;
      } else {
        throw Exception('Invalid product ID type');
      }

      print('Toggling favorite...');
      print('Email: $email');
      print('Product ID: $parsedProductId');
      print('Current Favorite Status: $isFavorite');

      // เพิ่มหรือลบรายการโปรด
      if (isFavorite) {
        await ProductService().removeFavorite(email, parsedProductId);
      } else {
        await ProductService().addFavorite(email, parsedProductId);
      }

      // อัปเดตสถานะใน UI
      setState(() {
        isFavorite = !isFavorite;
        product['isFavorite'] = isFavorite;
      });

      widget.onFavoriteUpdate(product);

      print('Updated Favorite Status: $isFavorite');
    } catch (e) {
      print('Error toggling favorite: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(product['productName'] ?? 'Product Details'),
        actions: [
          PopupMenuButton<String>(
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
                product['profilePicture'] != null
                    ? CircleAvatar(
                        backgroundImage: MemoryImage(
                          base64Decode(product['profilePicture']),
                        ),
                        radius: 24,
                      )
                    : CircleAvatar(
                        radius: 24,
                        child: Icon(Icons.person, size: 24),
                      ),
                SizedBox(width: 8),
                Text(
                  product['firstName'] ?? 'Unknown',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                  onPressed: toggleFavorite,
                ),
              ],
            ),
            Text(
              "ราคา: ฿${product['price']}",
              style: TextStyle(fontSize: 18, color: Colors.pink),
            ),
            SizedBox(height: 10),
            Text(
              "หมวดหมู่: ${product['category']}",
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            SizedBox(height: 20),
            Text(
              product['productDescription'] ?? '',
              style: TextStyle(fontSize: 16),
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

  void showEditDialog(BuildContext context) {
    // Implementation
  }

  void _confirmDelete(BuildContext context) {
    // Implementation
  }

  void _deleteProduct(BuildContext context) {
    // Implementation
  }
}
