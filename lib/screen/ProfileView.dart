import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:loginsystem/screen/Chat.dart';
import 'package:loginsystem/screen/ProductDetailPage.dart';
import 'package:loginsystem/screen/Totalreview.dart';

class ProfileView extends StatefulWidget {
  final String email; // รับอีเมลเป็นตัวระบุผู้ใช้
  const ProfileView({Key? key, required this.email}) : super(key: key);

  @override
  _ProfileViewState createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  String username = '';
  String profilePictureUrl = '';
  double avgRating = 0.0;
  int totalReviews = 0;
  int hiuCount = 0; // ✅ ตัวแปรเก็บจำนวนครั้งที่รับหิ้ว
  int totalLikes = 0; // ✅ เก็บจำนวนไลก์
  List<dynamic> userPosts = [];
  bool isLoading = true;
  

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    _fetchUserReviews();
    _fetchUserPosts();
    _fetchHiuCount(); // ✅ ดึงจำนวนครั้งที่รับหิ้ว
    _fetchTotalLikes(); // ✅ ดึงข้อมูลการกดหัวใจ

    
  }

  Future<void> _fetchUserProfile() async {
    final String apiUrl = 'http://10.0.2.2:3000/getProfile?email=${widget.email}';
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          username = data['username'] ?? 'ไม่ทราบชื่อ';
          profilePictureUrl = data['profile_picture'] ?? '';
        });
      }
    } catch (e) {
      print('Error fetching user profile: $e');
    }
  }

  Future<void> _fetchUserReviews() async {
    final String apiUrl = 'http://10.0.2.2:3000/rateReviews?email=${widget.email}';
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          avgRating = double.parse(data['avg_rating'].toString());
          totalReviews = data['total_reviews'] ?? 0;
        });
      }
    } catch (e) {
      print('Error fetching user reviews: $e');
    }
  }

  Future<void> _fetchHiuCount() async {
    final String apiUrl = 'http://10.0.2.2:3000/getHiuCount?email=${widget.email}';
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          hiuCount = data['totalHiuCount'] ?? 0;
        });
      }
    } catch (e) {
      print('Error fetching hiu count: $e');
    }
  }

Future<void> _fetchTotalLikes() async {
  final String apiUrl = 'http://10.0.2.2:3000/getTotalLikes?email=${widget.email}';
  try {
    final response = await http.get(Uri.parse(apiUrl));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        totalLikes = data['totalLikes'] ?? 0;
      });
    }
  } catch (e) {
    print('Error fetching total likes: $e');
  }
}

  Future<void> _fetchUserPosts() async {
    final String apiUrl = 'http://10.0.2.2:3000/postsByUser?email=${widget.email}';
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          userPosts = data;
        });
      }
    } catch (e) {
      print('Error fetching user posts: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _displayProfileImage() {
    return CircleAvatar(
      radius: 50,
      backgroundImage: profilePictureUrl.isNotEmpty
          ? NetworkImage(profilePictureUrl)
          : AssetImage('assets/avatar.png') as ImageProvider,
    );
  }

  Widget _buildReviewSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star, color: Colors.amber, size: 30),
            SizedBox(width: 5),
            Text(
              avgRating.toStringAsFixed(1),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(width: 5),
            Text(
              "(${totalReviews} รีวิว)",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
        SizedBox(height: 10),
      ],
    );
  }

  Widget _buildHiuCountSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag, color: Colors.pink, size: 30),
            SizedBox(width: 5),
            Text(
              "$hiuCount",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.pink),
            ),
          ],
        ),
        SizedBox(height: 5),
        Text(
          "รับหิ้วไปแล้ว",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ],
    );
  }
  
Widget _buildFavoriteSection() {
  return Column(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite, color: Colors.pink, size: 30),
          SizedBox(width: 5),
          Text(
            "$totalLikes",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.pink),
          ),
        ],
      ),
      SizedBox(height: 5),
      Text(
        "การกดหัวใจ",
        style: TextStyle(fontSize: 16, color: Colors.grey),
      ),
    ],
  );
}

  Widget _buildPostCard(dynamic post) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailPage(
              product: post,
              onFavoriteUpdate: (updatedProduct) {
                setState(() {
                  final index =
                      userPosts.indexWhere((p) => p['id'] == updatedProduct['id']);
                  if (index != -1) {
                    userPosts[index] = updatedProduct;
                  }
                });
              },
            ),
          ),
        );
      },
      child: Card(
        elevation: 5,
        margin: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            post['imageUrl'] != null && post['imageUrl'].isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                    child: Image.network(
                      post['imageUrl'],
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  )
                : Container(
                    height: 150,
                    color: Colors.grey[200],
                    child: Icon(Icons.broken_image, size: 100),
                  ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                post['productName'] ?? 'ไม่มีชื่อสินค้า',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
Widget _buildStatCard(IconData icon, String value, String label, {Color? color, VoidCallback? onTap}) {
  return Expanded(
    child: GestureDetector( // ✅ ใช้ GestureDetector เพื่อให้สามารถคลิกได้
      onTap: onTap, // ✅ เมื่อกดที่ Card ให้ทำงานฟังก์ชันที่ส่งมา
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color ?? Colors.pink, size: 24),
              SizedBox(width: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color ?? Colors.pink,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

@override 
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      automaticallyImplyLeading: false,
      centerTitle: true,
      title: Text('โปรไฟล์ผู้ใช้'),
      backgroundColor: Colors.pink,
    ),
    body: isLoading
        ? Center(child: CircularProgressIndicator())
        : SingleChildScrollView(  // ✅ ทำให้หน้าสามารถเลื่อนได้ทั้งหมด
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _displayProfileImage(),
                      SizedBox(height: 16),
                      Text(
                        username,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 24),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatCard(
                              Icons.star,
                              avgRating.toStringAsFixed(1),
                              'ความพึงพอใจ',
                              color: Colors.amber,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TotalReview(email: widget.email),
                                  ),
                                );
                              },
                            ),
                            _buildStatCard(
                              Icons.favorite,
                              totalLikes.toString(),
                              'การกดหัวใจ',
                            ),
                            _buildStatCard(
                              Icons.shopping_bag,
                              hiuCount.toString(),
                              'รับหิ้วไปแล้ว',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(),
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 40.0),
  child: ElevatedButton(
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatPage(
      receiverEmail: widget.email,
      firstName: username, // ใช้ firstName แทน receiverName
          ),
        ),
      );
    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 99),
                      backgroundColor: Colors.pink,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text('คุยกับผู้รับหิ้ว', style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                ),
                SizedBox(height: 20), // ✅ เพิ่มระยะห่างให้ปุ่มดูเป็นระเบียบ
                _buildPostList(), // ✅ ทำให้เลื่อนลงได้
              ],
            ),
          ),
  );
}

// ✅ ฟังก์ชันใหม่ `_buildPostList()` 
Widget _buildPostList() {
  return ListView.builder(
    shrinkWrap: true, // ✅ ป้องกันปัญหาเลื่อนผิดปกติ
    physics: NeverScrollableScrollPhysics(), // ✅ ทำให้ ListView อยู่ใน SingleChildScrollView
    itemCount: userPosts.length,
    itemBuilder: (context, index) {
      return _buildPostCard(userPosts[index]);
    },
  );
}

}
