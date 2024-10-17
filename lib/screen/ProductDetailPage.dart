import 'package:flutter/material.dart';
import 'dart:convert';

class ProductDetailPage extends StatelessWidget {
  final Map<String, dynamic> product; // รับข้อมูลของสินค้าที่ถูกเลือกมาแสดง

  ProductDetailPage({required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(product['productName']),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image section
              product['imageUrl'] != null && product['imageUrl'] is String && product['imageUrl'].isNotEmpty
                  ? _buildProductImage(product['imageUrl'])
                  : Container(
                      color: Colors.grey[200],
                      height: 300,
                      width: double.infinity,
                      child: Icon(Icons.image, size: 100),
                    ),
              SizedBox(height: 20),

              // Product name
              Text(
                product['productName'],
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),

              // Product price
              Text(
                "Price: \$${product['price']}",
                style: TextStyle(fontSize: 20, color: Colors.grey[600]),
              ),
              SizedBox(height: 10),

              // Product category
              Text(
                "Category: ${product['category']}",
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
              SizedBox(height: 20),

              // Product description
              Text(
                product['productDescription'],
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Function to decode Base64 image and handle errors
  Widget _buildProductImage(String imageUrl) {
    try {
      final imageData = base64Decode(imageUrl);
      return Image.memory(
        imageData,
        fit: BoxFit.cover,
        height: 300,
        width: double.infinity,
      );
    } catch (e) {
      // Handle invalid Base64 or image data
      return Container(
        color: Colors.grey[200],
        height: 300,
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image, size: 100, color: Colors.grey),
            SizedBox(height: 10),
            Text('Invalid image data', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
  }
}
