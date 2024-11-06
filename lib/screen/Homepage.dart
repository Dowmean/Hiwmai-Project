import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class HomepageScreen extends StatefulWidget {
  @override
  _HomepageState createState() => _HomepageState();
}

class _HomepageState extends State<HomepageScreen> {
  int _selectedIndex = 0;
  List<dynamic> recommendedProducts = [];
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _carouselTimer;

  // API URL
  final String apiUrl = 'http://10.0.2.2:3000/getproduct';

  // List of images for the carousel
  final List<String> carouselImages = [
    'assets/images/carousel1.png',
    'assets/images/carousel2.png',
    'https://example.com/carousel3.png',
  ];

  @override
  void initState() {
    super.initState();
    _startAutoSlide();
    fetchProducts();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _carouselTimer?.cancel();
    super.dispose();
  }

  // Function to start auto-slide for the carousel
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

  // Function to fetch products and select random ones for recommendations
  Future<void> fetchProducts() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        List<dynamic> products = json.decode(response.body);

        // Randomly select 2 products for recommendations
        final random = Random();
        setState(() {
          recommendedProducts = (products..shuffle(random)).take(2).toList();
        });
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      print("Error fetching products: $e");
    }
  }

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
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'ค้นหา',
              prefixIcon: Icon(Icons.search),
              border: InputBorder.none,
            ),
          ),
        ),
        backgroundColor: Colors.pink,
        actions: [
          IconButton(
            icon: Icon(Icons.chat_bubble),
            onPressed: () {
              // Chat button pressed
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 5),
            // Carousel section
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
            // Dots indicator
            Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
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
            ),
            // Category section
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
                  _buildCategoryIcon(Icons.shopping_bag, 'เสื้อผ้า', () => _navigateToCategoryPage('เสื้อผ้า')),
                  _buildCategoryIcon(Icons.local_mall, 'กระเป๋า', () => _navigateToCategoryPage('กระเป๋า')),
                  _buildCategoryIcon(Icons.face, 'ความงาม', () => _navigateToCategoryPage('ความงาม')),
                  _buildCategoryIcon(Icons.run_circle, 'รองเท้า', () => _navigateToCategoryPage('รองเท้า')),
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
            recommendedProducts.isNotEmpty
                ? Column(
                    children: recommendedProducts.map((product) {
                      return _buildProductRecommendation(
                        product['imageUrl'] ?? '',
                        product['productName'] ?? 'ชื่อสินค้า',
                        int.tryParse(product['price'] ?? '0') ?? 0,
                      );
                    }).toList(),
                  )
                : Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.pink,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Categories',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // Category icon widget with callback
  Widget _buildCategoryIcon(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
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

  // Product recommendation widget
  Widget _buildProductRecommendation(String imageUrl, String name, int price) {
    bool isBase64 = imageUrl.contains(','); // ตรวจสอบว่าเป็นข้อมูล base64 หรือไม่
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          imageUrl.isNotEmpty
            ? (isBase64
              ? Image.memory(base64Decode(imageUrl.split(',')[1]), height: 80, width: 80)
              : Image.network(imageUrl, height: 80, width: 80))
            : Icon(Icons.image, size: 80),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('ราคา: ฿$price', style: TextStyle(fontSize: 14, color: Colors.pink)),
            ],
          ),
        ],
      ),
    );
  }
}

class CategoryProductPage extends StatefulWidget {
  final String category;

  CategoryProductPage({required this.category});

  @override
  _CategoryProductPageState createState() => _CategoryProductPageState();
}

class _CategoryProductPageState extends State<CategoryProductPage> {
  List<dynamic> products = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCategoryProducts();
  }

  Future<void> fetchCategoryProducts() async {
    final String apiUrl = 'http://10.0.2.2:3000/getproduct';
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        List<dynamic> allProducts = json.decode(response.body);
        
        setState(() {
          products = allProducts.where((product) => product['category'] == widget.category).toList();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      print("Error fetching category products: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("หมวดหมู่: ${widget.category}"),
        backgroundColor: Colors.pink,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : products.isEmpty
              ? Center(child: Text("ไม่มีสินค้าในหมวดหมู่ ${widget.category}"))
              : ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    var product = products[index];
                    return ListTile(
                      leading: product['imageUrl'] != null && product['imageUrl'].isNotEmpty
                          ? Image.network(product['imageUrl'], height: 50, width: 50)
                          : Icon(Icons.image, size: 50),
                      title: Text(product['productName']),
                      subtitle: Text("ราคา: ฿${product['price']}"),
                    );
                  },
                ),
    );
  }
}
