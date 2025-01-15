import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ProductDetailPage.dart';

class RecommendedProductsSection extends StatelessWidget {
  final String apiUrl = 'http://10.0.2.2:3000/getproduct';

  Future<List<Map<String, dynamic>>> fetchRandomProducts() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        List<dynamic> products = json.decode(response.body);
        products.shuffle(); // Shuffle the list to get random products
        return products.take(5).cast<Map<String, dynamic>>().toList();
      } else {
        throw Exception("Failed to load products");
      }
    } catch (e) {
      throw Exception("Error fetching products: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchRandomProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Text("Error loading products: ${snapshot.error}"),
          );
        } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          final products = snapshot.data!;
          return SizedBox(
            height: 240,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetailPage(
                          product: product,
                          onFavoriteUpdate: (updatedProduct) {},
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 180,
                    margin: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: product['imageUrl'] != null
                                ? Image.memory(
                                    base64Decode(product['imageUrl']),
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    color: Colors.grey[200],
                                    child: Icon(Icons.image),
                                  ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              product['productName'] ?? '',
                              style: TextStyle(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              "Price: ฿${product['price']}",
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        } else {
          return Center(
            child: Text(
              "ไม่มีสินค้าแนะนำ",
              style: TextStyle(fontSize: 16),
            ),
          );
        }
      },
    );
  }
}
