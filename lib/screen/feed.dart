import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:loginsystem/screen/Notifications.dart';
import 'package:loginsystem/screen/PostCreate.dart';
import 'package:loginsystem/screen/ProductDetailPage.dart';
import 'package:loginsystem/screen/Search.dart';


class ProductFeedScreen extends StatefulWidget {
  @override
  _ProductFeedScreenState createState() => _ProductFeedScreenState();
}

class _ProductFeedScreenState extends State<ProductFeedScreen> {
  List<Post> posts = [];
  String profilePictureUrl = '';
  String username = '';
  String? currentUserRole;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchUserRole();
    fetchPosts().then((fetchedPosts) {
      setState(() {
        posts = fetchedPosts;
      });
    });
  }

  Future<void> _fetchUserData() async {
    final User? user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? '';

    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/getUserProfile?email=$email'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          username = data['username'] ?? '';
          profilePictureUrl = data['profile_picture'] ?? '';
        });
      } else {
        //print("Failed to load profile data: ${response.statusCode}");
      }
    } catch (e) {
      //print("Error fetching profile data: $e");
    }
  }

  Future<void> _fetchUserRole() async {
    final User? user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? '';

    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/getUserRole?email=$email'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          currentUserRole = data['role'];
        });
      } else {
        //print("Failed to fetch user role: ${response.body}");
      }
    } catch (e) {
      //print("Error fetching user role: $e");
    }
  }

  Future<List<Post>> fetchPosts() async {
    const String apiUrl = 'http://10.0.2.2:3000/posts';
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((item) => Post.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load posts: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching posts: $e');
    }
  }

Widget _displayProfileImage() {
  if (profilePictureUrl.isNotEmpty) {
    return CircleAvatar(
      radius: 30,
      backgroundImage: NetworkImage(profilePictureUrl),
    );
  } else {
    return CircleAvatar(
      radius: 30,
      backgroundImage: AssetImage('assets/images/avatar.png'),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final String? currentUserEmail = user?.email; // ✅ ดึงอีเมลของผู้ใช้

    return Scaffold(
      body: Column(
        children: [
          SizedBox(height: 50), // ✅ ระยะห่างด้านบน
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                // ✅ ปรับช่องค้นหาให้มีขนาดเล็กลง โดยใช้ Expanded
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SearchProductsPage()),
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: Colors.pink),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search, color: Colors.pink),
                          SizedBox(width: 8),
                          Text(
                            'ค้นหา',
                            style: TextStyle(color: Colors.pink, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10), // ✅ เว้นระยะระหว่างช่องค้นหาและไอคอนแจ้งเตือน
                // ✅ ปุ่มแจ้งเตือน
                IconButton(
                  icon: Icon(Icons.notifications, color: Colors.pink, size: 28),
                  onPressed: currentUserEmail == null
                      ? null // ปิดการกดปุ่มถ้าไม่มีอีเมล
                      : () {
                          debugPrint("🔔 Navigating to NotificationsPage with email: $currentUserEmail");
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => NotificationsPage(email: currentUserEmail!)),
                          );
                        },
                ),
              ],
            ),
          ),
          Divider(),

          if (currentUserRole != 'User')
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  _displayProfileImage(),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => PostCreatePage()),
                          );
                        },
                        child: Text(
                          'เริ่มต้นการเป็นนักหิ้ว ...',
                          style: TextStyle(
                            color: Colors.pink,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          Expanded(
            child: posts.isEmpty
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      return ProductCard(post: posts[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class Post {
  final int id;
  final String productName;
  final String productDescription;
  final double price;
  final String? imageUrl;
  final String firstName;
  final String? profilePicture;

  Post({
    required this.id,
    required this.productName,
    required this.productDescription,
    required this.price,
    this.imageUrl,
    required this.firstName,
    this.profilePicture,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      productName: json['productName'],
      productDescription: json['productDescription'],
      price: double.parse(json['price'].toString()),
      imageUrl: json['imageUrl'],
      firstName: json['firstName'],
      profilePicture: json['profilePicture'],
    );
  }
}

class ProductCard extends StatelessWidget {
  final Post post;

  const ProductCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final formatter = new NumberFormat("#,##0.00", "th");
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 5,
            spreadRadius: 2,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundImage: post.profilePicture != null
                    ? NetworkImage(post.profilePicture!)
                    : AssetImage('assets/images/default_profile.png')
                        as ImageProvider,
                radius: 20,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  post.firstName,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                post.imageUrl!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                  );
                },
              ),
            ),
          SizedBox(height: 10),
          Text(
            post.productName,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
Text(
  "${formatter.format(double.tryParse(post.price.toString()) ?? 0.00)}", 
  style: TextStyle(fontSize: 16, color: Colors.pink),
),

          SizedBox(height: 5),
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductDetailPage(
                      product: {
                        'id': post.id,
                        'productName': post.productName,
                        'productDescription': post.productDescription,
                        'price': post.price,
                        'imageUrl': post.imageUrl,
                        'firstName': post.firstName,
                        'profilePicture': post.profilePicture,
                      },
                      onFavoriteUpdate: (updatedProduct) {},
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text('เพิ่มเติม', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
