import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'ProductDetailPage.dart'; // Import the ProductDetailPage for navigation

class CategoryProductPage extends StatefulWidget {
  final String category;

  CategoryProductPage({required this.category});

  @override
  _CategoryProductPageState createState() => _CategoryProductPageState();
}

class _CategoryProductPageState extends State<CategoryProductPage> {
  List<dynamic> products = [];
  bool isLoading = true;
  final String apiUrl = 'http://10.0.2.2:3000/category/';

  @override
  void initState() {
    super.initState();
    fetchCategoryProducts();
  }

  Future<void> fetchCategoryProducts() async {
    try {
      final response = await http.get(Uri.parse('$apiUrl${widget.category}'));
      print("API Response: ${response.body}"); // Debugging
      if (response.statusCode == 200) {
        setState(() {
          products = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      print("Error fetching products: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  void updateFavoriteStatus(Map<String, dynamic> updatedProduct) {
    setState(() {
      // อัปเดตสถานะในรายการสินค้า
      products = products.map((product) {
        if (product['id'] == updatedProduct['id']) {
          return updatedProduct;
        }
        return product;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('หมวดหมู่: ${widget.category}'),
        backgroundColor: Colors.pink,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : products.isEmpty
              ? Center(
                  child: Text("ไม่มีสินค้าในหมวดหมู่ ${widget.category}"),
                )
              : GridView.builder(
                  padding: EdgeInsets.all(8.0),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10.0,
                    mainAxisSpacing: 10.0,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return GestureDetector(
                      onTap: () {
                        // Navigate to ProductDetailPage when tapped
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductDetailPage(
                              product: product,
                              onFavoriteUpdate: updateFavoriteStatus,
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
                            // Profile section
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  product['profilePicture'] != null &&
                                          product['profilePicture'].isNotEmpty
                                      ? CircleAvatar(
                                          backgroundImage: MemoryImage(
                                            base64Decode(
                                                product['profilePicture']),
                                          ),
                                          radius: 16,
                                        )
                                      : CircleAvatar(
                                          child: Icon(Icons.person, size: 16),
                                          radius: 16,
                                        ),
                                  SizedBox(width: 8),
                                  Text(
                                    product['firstName'] ?? 'Unknown',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Product image
                            Expanded(
                              child: product['imageUrl'] != null &&
                                      product['imageUrl'].isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(10)),
                                      child: Image.memory(
                                        base64Decode(product['imageUrl']),
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                      ),
                                    )
                                  : Container(
                                      color: Colors.grey[200],
                                      height: 120,
                                      child: Icon(Icons.image, size: 50),
                                    ),
                            ),
                            // Product details
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                product['productName'],
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
                                "Price: ฿${product['price']}",
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
                ),
    );
  }
}
