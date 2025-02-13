import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:loginsystem/screen/ProductDetailPage.dart';

class SearchProductsPage extends StatefulWidget {
  @override
  _SearchProductsPageState createState() => _SearchProductsPageState();
}

class _SearchProductsPageState extends State<SearchProductsPage> {
  TextEditingController searchController = TextEditingController();
  List<dynamic> products = [];
  bool isLoading = false;
  String errorMessage = '';
  Timer? _debounce;

  // ✅ ฟังก์ชันค้นหาสินค้า (มี debounce 500ms)
  void onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(Duration(milliseconds: 500), () {
      searchProducts(query);
    });
  }

  Future<void> searchProducts(String query) async {
    if (query.isEmpty) {
      setState(() {
        products = [];
        errorMessage = '';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/searchProducts?productName=$query'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          products = data['products'];
          isLoading = false;
        });
      } else {
        setState(() {
          products = [];
          errorMessage = 'No products found';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        products = [];
        errorMessage = 'Error fetching products';
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formatter = new NumberFormat("#,##0.00", "th");
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text('ค้นหาสินค้า', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.pink,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // ✅ ช่องค้นหาสินค้า
            TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: 'ค้นหาสินค้า...',
                prefixIcon: Icon(Icons.search, color: Colors.pink),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          searchController.clear();
                          searchProducts('');
                        },
                      )
                    : null,
              ),
            ),
            SizedBox(height: 20),

            // ✅ แสดงสถานะโหลดข้อมูล
            if (isLoading)
              Center(child: CircularProgressIndicator()),

            // ✅ แสดงข้อความ error
            if (errorMessage.isNotEmpty)
              Center(child: Text(errorMessage, style: TextStyle(color: Colors.red))),

            // ✅ แสดงรายการสินค้า
            Expanded(
              child: ListView.builder(
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: ListTile(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailPage(
          product: product,
          onFavoriteUpdate: (updatedProduct) {
            // อัปเดตสถานะ favorite หลังจากกลับมา
            setState(() {
              product['isFavorite'] = updatedProduct['isFavorite'];
            });
          },
        ),
      ),
    );
  },
  leading: product['imageUrl'] != null
      ? Image.network(
          product['imageUrl'],
          width: 60,
          height: 60,
          fit: BoxFit.cover,
        )
      : Icon(Icons.image_not_supported, size: 60, color: Colors.grey),
  title: Text(
    product['productName'],
    style: TextStyle(fontWeight: FontWeight.bold),
  ),
  subtitle: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(product['productDescription']),
Text(
  "${formatter.format(double.tryParse(product['price'].toString()) ?? 0.00)}", // ✅ ใช้ formatter.format
  style: TextStyle(color: Colors.pink[600]),
),
    ],
  ),
),

                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
