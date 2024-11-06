import 'package:flutter/material.dart';
import 'dart:convert';
import 'PostService.dart';

class ProductDetailPage extends StatefulWidget {
  final Map<String, dynamic> product;

  ProductDetailPage({required this.product});

  @override
  _ProductDetailPageState createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late Map<String, dynamic> product;

  @override
  void initState() {
    super.initState();
    product = widget.product;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(product['productName']),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                showEditDialog(context);
              } else if (value == 'delete') {
                _confirmDelete(context);
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem<String>(
                  value: 'edit',
                  child: Text('แก้ไข'),
                ),
                PopupMenuItem<String>(
                  value: 'delete',
                  child: Text('ลบ'),
                ),
              ];
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              product['imageUrl'] != null &&
                      product['imageUrl'] is String &&
                      product['imageUrl'].isNotEmpty
                  ? _buildProductImage(product['imageUrl'])
                  : Container(
                      color: Colors.grey[200],
                      height: 300,
                      width: double.infinity,
                      child: Icon(Icons.image, size: 100),
                    ),
              SizedBox(height: 20),
              Text(
                product['productName'],
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                "ราคา: ฿${product['price']}",
                style: TextStyle(fontSize: 20, color: Colors.grey[600]),
              ),
              SizedBox(height: 10),
              Text(
                "หมวดหมู่: ${product['category']}",
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
              SizedBox(height: 20),
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
      return Container(
        color: Colors.grey[200],
        height: 300,
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image, size: 100, color: Colors.grey),
            SizedBox(height: 10),
            Text('ข้อมูลรูปภาพไม่ถูกต้อง', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
  }

  void showEditDialog(BuildContext context) {
    final TextEditingController productNameController =
        TextEditingController(text: product['productName']);
    final TextEditingController productDescriptionController =
        TextEditingController(text: product['productDescription']);
    final TextEditingController priceController =
        TextEditingController(text: product['price'].toString());
    String? selectedCategory = product['category'];

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
                    DropdownMenuItem(value: 'เสื้อผ้า', child: Text('เสื้อผ้า')),
                    DropdownMenuItem(value: 'รองเท้า', child: Text('รองเท้า')),
                    DropdownMenuItem(value: 'ความงาม', child: Text('ความงาม')),
                    DropdownMenuItem(value: 'กระเป๋า', child: Text('กระเป๋า')),
                  ],
                  hint: Text("เลือกหมวดหมู่"),
                  onChanged: (String? value) {
                    selectedCategory = value;
                  },
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
                    category: selectedCategory!,
                    imageUrl: product['imageUrl'],
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('แก้ไขข้อมูลสำเร็จ')),
                  );

                  setState(() {
                    product['productName'] = productNameController.text;
                    product['productDescription'] =
                        productDescriptionController.text;
                    product['price'] = double.tryParse(priceController.text) ?? product['price'];
                    product['category'] = selectedCategory;
                  });

                  Navigator.of(context).pop();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('ไม่สามารถแก้ไขข้อมูลได้: $e')),
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
              onPressed: () {
                Navigator.of(context).pop();
                _deleteProduct(context);
              },
              child: Text('ลบ'),
            ),
          ],
        );
      },
    );
  }

  void _deleteProduct(BuildContext context) async {
    try {
      await PostService().deletePost(product['id']);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('ลบสินค้าเรียบร้อยแล้ว')));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('ไม่สามารถลบสินค้าได้: $e')));
    }
  }
}
