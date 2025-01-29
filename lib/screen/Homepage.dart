import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ProductCategory.dart'; // Import for the category page
import 'ProductDetailPage.dart'; // Import for the product detail page
import 'ChatList.dart';
import 'package:loginsystem/screen/Search.dart';

class HomepageScreen extends StatefulWidget {
  @override
  _HomepageScreenState createState() => _HomepageScreenState();
}

class _HomepageScreenState extends State<HomepageScreen> {
  List<dynamic> recommendedProducts = [];
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _carouselTimer;

  bool isLoading = true; // Flag for loading products

  // API URL for fetching products
  final String apiUrl = 'http://10.0.2.2:3000/getproduct';

  // List of carousel images
  final List<String> carouselImages = [
    'assets/images/carousel1.png',
    'assets/images/carousel2.png',
  ];

  @override
  void initState() {
    super.initState();
    _startAutoSlide();
    fetchProducts(); // Fetch recommended products
  }

  @override
  void dispose() {
    _pageController.dispose();
    _carouselTimer?.cancel();
    super.dispose();
  }

  // Function to auto-slide the carousel
  void _startAutoSlide() {
    _carouselTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      if (_currentPage < carouselImages.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      _pageController.animateToPage(
        _currentPage,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  // Function to fetch products
  Future<void> fetchProducts() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));
      //print("API Status Code: ${response.statusCode}");
      //print("API Response Body: ${response.body}");

      if (response.statusCode == 200) {
        List<dynamic> products = json.decode(response.body);
        setState(() {
          recommendedProducts = products; // Store products
          isLoading = false; // Stop loading
        });
      } else {
        //print("Error: Failed to load products");
        setState(() {
          isLoading = false; // Stop loading on error
        });
      }
    } catch (e) {
      //print("Error fetching products: $e");
      setState(() {
        isLoading = false; // Stop loading on error
      });
    }
  }

  // Navigate to category page
  void _navigateToCategoryPage(String category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryProductPage(category: category),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
title: GestureDetector(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SearchProductsPage()),
    );
  },
  child: Container(
    height: 40,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        SizedBox(width: 10),
        Icon(Icons.search, color: Colors.grey),
        SizedBox(width: 10),
        Text("ค้นหาสินค้า...", style: TextStyle(color: Colors.grey)),
      ],
    ),
  ),
),

        backgroundColor: Colors.pink,
        actions: [
          IconButton(
            icon: Icon(Icons.chat_bubble),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatListPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Carousel Section
            SizedBox(
              height: 150,
              child: PageView.builder(
                controller: _pageController,
                itemCount: carouselImages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final imagePath = carouselImages[index];
                  return imagePath.startsWith('assets')
                      ? Image.asset(
                          imagePath,
                          fit: BoxFit.cover,
                        )
                      : Image.network(
                          imagePath,
                          fit: BoxFit.cover,
                        );
                },
              ),
            ),
            // Dots Indicator
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(carouselImages.length, (index) {
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == _currentPage ? Colors.pink : Colors.grey,
                    ),
                  );
                }),
              ),
            ),
            // Category Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'หมวดหมู่',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildCategoryIcon(Icons.shopping_bag, 'เสื้อผ้า'),
                  _buildCategoryIcon(Icons.local_mall, 'กระเป๋า'),
                  _buildCategoryIcon(Icons.face, 'ความงาม'),
                  _buildCategoryIcon(Icons.run_circle, 'รองเท้า'),
                ],
              ),
            ),
            // Product Recommendation Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'สินค้าแนะนำ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            isLoading
                ? Center(
                    child: CircularProgressIndicator(), // Loading indicator
                  )
                : recommendedProducts.isNotEmpty
                    ? SizedBox(
                        height: 240,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: recommendedProducts.length,
                          itemBuilder: (context, index) {
                            var product = recommendedProducts[index];
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      // Profile Section
                                      Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Row(
                                            children: [
CircleAvatar(
  backgroundImage: product['profilePicture'] != null
      ? NetworkImage(product['profilePicture'])
      : null,
  onBackgroundImageError: (exception, stackTrace) {
    //print("Error loading profile picture: $exception");
  },
  child: product['profilePicture'] == null
      ? Icon(Icons.person)
      : null,
  radius: 16,
),

                                              SizedBox(width: 8),
                                              Text(
                                                product['firstName'] ??
                                                    "Unknown",
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          )),
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.vertical(
                                              top: Radius.circular(10)),
                                          child: product['imageUrl'] != null
                                              ? (product['imageUrl'] is Map &&
                                                      product['imageUrl']
                                                              ['data'] !=
                                                          null
                                                  ? Image.memory(
                                                      Uint8List.fromList(List<
                                                              int>.from(
                                                          product['imageUrl']
                                                              ['data'])),
                                                      fit: BoxFit.cover,
                                                      width: double.infinity,
                                                      errorBuilder: (context,
                                                          error, stackTrace) {
                                                        return Container(
                                                          color:
                                                              Colors.grey[200],
                                                          child: Icon(
                                                              Icons
                                                                  .broken_image,
                                                              size: 50),
                                                        );
                                                      },
                                                    )
                                                  : Image.network(
  product['imageUrl'],
  fit: BoxFit.cover,
  width: double.infinity,
  errorBuilder: (context, error, stackTrace) {
    return Container(
      color: Colors.grey[200],
      child: Icon(Icons.broken_image, size: 50),
                                                        );
                                                      },
                                                    ))
                                              : Container(
                                                  color: Colors.grey[200],
                                                  child: Icon(Icons.image,
                                                      size: 50),
                                                ),
                                        ),
                                      ),

                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          product['productName'] ?? '',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8.0),
                                        child: Text(
                                          "Price: ฿${product['price']}",
                                          style: TextStyle(
                                              color: Colors.grey[600]),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    : Center(
                        child: Text(
                          "ไม่มีสินค้าแนะนำ",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
          ],
        ),
      ),
    );
  }

  // Build category icon
  Widget _buildCategoryIcon(IconData icon, String label) {
    return GestureDetector(
      onTap: () {
        _navigateToCategoryPage(label);
      },
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.pinkAccent,
            child: Icon(icon, color: Colors.white),
          ),
          SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
