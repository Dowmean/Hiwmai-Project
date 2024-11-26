import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ProductService.dart';
import 'ProductDetailPage.dart';

class ProductListPage extends StatefulWidget {
  @override
  _ProductListPageState createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  late Future<List<dynamic>> _favoriteProducts = Future.value([]); // Default value
  String email = '';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _fetchUserEmail();
    _fetchFavorites(); // Fetch user favorites
  }

  Future<void> _fetchUserEmail() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        email = user.email ?? '';
      });
      print('User email: $email');
    } else {
      print('No user is currently logged in.');
    }
  }

  void _fetchFavorites() {
    if (email.isNotEmpty) {
      _favoriteProducts = ProductService().getFavorites(email).then((favoriteIds) {
        final uniqueIds = favoriteIds.toSet().toList(); // Remove duplicates
        print('Unique Favorite IDs: $uniqueIds'); // Debugging

        if (uniqueIds.isEmpty) {
          print('No product IDs to fetch.'); // Debugging
          return Future.value([]); // Return an empty Future<List>
        } else {
          return ProductService().fetchProductsByIds(uniqueIds).then((products) {
            print('Fetched products: $products'); // Debugging
            return products; // Return the fetched products
          }).catchError((e) {
            print('Error fetching products: $e'); // Error logging
            return []; // Return empty list on error
          });
        }
      }).catchError((e) {
        print('Error fetching favorites: $e'); // Error logging
        return []; // Return empty list on error
      });
    } else {
      print('No email found, skipping fetch.');
      _favoriteProducts = Future.value([]); // Return empty list if no email
    }
  }

  Widget _buildProductImage(dynamic imageUrl) {
    try {
      if (imageUrl is Map && imageUrl['data'] != null) {
        Uint8List imageData = Uint8List.fromList(List<int>.from(imageUrl['data']));
        return Image.memory(
          imageData,
          fit: BoxFit.cover,
          width: double.infinity,
          height: 120,
        );
      } else if (imageUrl is String) {
        if (imageUrl.startsWith('data:image')) {
          return Image.memory(
            base64Decode(imageUrl.split(',').last),
            fit: BoxFit.cover,
            width: double.infinity,
            height: 120,
          );
        } else {
          return Image.network(
            imageUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: 120,
          );
        }
      }
    } catch (e) {
      print('Error decoding image: $e'); // Error logging
    }
    return Container(
      color: Colors.grey[200],
      height: 120,
      child: Icon(Icons.broken_image, size: 50),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('รายการโปรดของคุณ'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _favoriteProducts,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('ไม่มีรายการโปรด'));
          } else {
            // เปลี่ยนจาก ListView เป็น GridView
            return GridView.builder(
              padding: EdgeInsets.all(8.0),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // จำนวนคอลัมน์ใน Grid
                crossAxisSpacing: 10.0,
                mainAxisSpacing: 10.0,
                childAspectRatio: 0.75, // ปรับอัตราส่วนความกว้าง/สูง
              ),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final product = snapshot.data![index];
                return GestureDetector(
                  onTap: () {
                    // ไปยังหน้ารายละเอียดสินค้า
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetailPage(
                          product: product,
                          onFavoriteUpdate: (_) {
                            setState(() {
                              _fetchFavorites(); // Update favorites after edit
                            });
                          },
                        ),
                      ),
                    );
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Image section
                        Expanded(
                          child: _buildProductImage(product['imageUrl']),
                        ),
                        // Text section
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            product['productName'] ?? 'ไม่มีชื่อสินค้า',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            "฿${product['price'] ?? 'ไม่มีราคา'}",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
