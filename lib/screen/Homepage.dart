import 'package:flutter/material.dart';

class HomepageScreen extends StatefulWidget {
  @override
  _HomepageState createState() => _HomepageState();
}

class _HomepageState extends State<HomepageScreen> {
  int _selectedIndex = 0;

  // Sample list of images for the carousel (corrected)
  final List<String> carouselImages = [
    'assets/images/carousel1.png', // Use assets for local images
    'assets/images/carousel2.png',
    'https://example.com/carousel3.png', // URL for web image
  ];

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
            // Carousel section
            SizedBox(
              height: 150,
              child: PageView.builder(
                itemCount: carouselImages.length,
                itemBuilder: (context, index) {
                  // Use Image.asset for local images
                  if (carouselImages[index].startsWith('assets')) {
                    return Image.asset(
                      carouselImages[index],
                      fit: BoxFit.cover,
                    );
                  } else {
                    return Image.network(
                      carouselImages[index],
                      fit: BoxFit.cover,
                    );
                  }
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
                        color: index == _selectedIndex ? Colors.pink : Colors.grey,
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
            _buildProductRecommendation(
              'https://example.com/product1.png',
              'Starbucks แก้วใหม่',
              2600,
            ),
            _buildProductRecommendation(
              'https://example.com/product2.png',
              'New Balance 530',
              3999,
            ),
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

  // Category icon widget
  Widget _buildCategoryIcon(IconData icon, String label) {
    return Column(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.pinkAccent,
          child: Icon(icon, color: Colors.white),
        ),
        SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 14)),
      ],
    );
  }

  // Product recommendation widget
  Widget _buildProductRecommendation(String imageUrl, String name, int price) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Image.network(imageUrl, height: 80, width: 80),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('ราคา: ฿price', style: TextStyle(fontSize: 14, color: Colors.pink)),
            ],
          )
        ],
      ),
    );
  }
}
