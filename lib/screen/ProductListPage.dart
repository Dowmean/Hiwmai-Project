import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'ProductService.dart';
import 'ProductDetailPage.dart';

class ProductListPage extends StatefulWidget {
  @override
  _ProductListPageState createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  late Future<List<dynamic>> _favoriteProducts =
      Future.value([]); // Default value
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
      //print('User email: $email');
    } else {
      //print('No user is currently logged in.');
    }
  }

Future<void> _fetchFavorites() async {
  if (email.isNotEmpty) {
    setState(() {
      _favoriteProducts =
          ProductService().getFavorites(email).then((favoriteIds) {
        final uniqueIds = favoriteIds.toSet().toList();
        //print('Favorite IDs: $uniqueIds');

        if (uniqueIds.isEmpty) return Future.value([]);

        return ProductService()
            .fetchProductsByIds(uniqueIds)
            .then((products) {
          //print('Fetched products: $products');

          // ตรวจสอบค่า imageUrl ใน products
          products.forEach((product) {
            //print('Product image URL: ${product['imageUrl']}');
          });

          return products;
        }).catchError((e) {
          //print('Error fetching products: $e');
          return [];
        });
      }).catchError((e) {
        //print('Error fetching favorites: $e');
        return [];
      });
    });
  } else {
    //print('No email found, skipping fetch.');
    setState(() {
      _favoriteProducts = Future.value([]);
    });
  }
}

Widget _buildProductImage(dynamic imageUrl) {
  if (imageUrl == null || imageUrl.isEmpty) {
    return Container(
      color: Colors.grey[200],
      height: 120,
      child: Icon(Icons.broken_image, size: 50),
    );
  }

  try {
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: 120,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        //print('Error loading image: $error');
        return Container(
          color: Colors.grey[200],
          height: 120,
          child: Icon(Icons.broken_image, size: 50),
        );
      },
    );
  } catch (e) {
    //print('Unexpected error loading image: $e');
    return Container(
      color: Colors.grey[200],
      height: 120,
      child: Icon(Icons.broken_image, size: 50),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    final formatter = new NumberFormat("#,##0.00", "th");
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text('รายการโปรดของคุณ'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _fetchFavorites();
        },
        child: FutureBuilder<List<dynamic>>(
          future: _favoriteProducts,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('ไม่มีรายการโปรด'));
            } else {
              return GridView.builder(
                padding: EdgeInsets.all(8.0),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10.0,
                  mainAxisSpacing: 10.0,
                  childAspectRatio: 0.75,
                ),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final product = snapshot.data![index];
                  final productName =
                      product['productName']?.toString() ?? 'ไม่มีชื่อสินค้า';
                  final price = product['price']?.toString() ?? 'ไม่มีราคา';
                  final imageUrl = product['imageUrl'];

                  return GestureDetector(
                    onTap: () {
                      // นำไปยังหน้ารายละเอียดสินค้าเมื่อคลิกที่รายการ
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ProductDetailPage(
      product: product,
      onFavoriteUpdate: (_) {
        _fetchFavorites(); // Refresh favorite list
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
                          Expanded(
                            child: _buildProductImage(imageUrl),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              productName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
child: Text(
  "${formatter.format(double.tryParse(product['price'].toString()) ?? 0.00)}", 
  style: TextStyle(color: Colors.pink[600]),
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
      ),
    );
  }
}
