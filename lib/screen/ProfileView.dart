import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:loginsystem/screen/Chat.dart';
import 'package:loginsystem/screen/ProductDetailPage.dart';

class ProfileView extends StatefulWidget {
  final String email; // รับอีเมลเป็นตัวระบุผู้ใช้
  const ProfileView({Key? key, required this.email}) : super(key: key);

  @override
  _ProfileViewState createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  String username = '';
  String profilePictureUrl = '';
  List<dynamic> userPosts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    _fetchUserPosts();
  }

  Future<void> _fetchUserProfile() async {
    final String apiUrl =
        'http://10.0.2.2:3000/getProfile?email=${widget.email}';

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('API Response (Profile): ${response.body}'); // Debug

        setState(() {
          username = data['username'] ?? 'ไม่ทราบชื่อ';
          profilePictureUrl = data['profile_picture'] ?? '';
        });
      } else {
        print('Failed to fetch user profile: ${response.body}');
      }
    } catch (e) {
      print('Error fetching user profile: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchUserPosts() async {
    final String apiUrl =
        'http://10.0.2.2:3000/postsByUser?email=${widget.email}';

    try {
      print('Fetching posts for email: ${widget.email}'); // Debug email
      final response = await http.get(Uri.parse(apiUrl));
      print('API Response Code: ${response.statusCode}'); // Debug status code
      print('API Response Body: ${response.body}'); // Debug raw response

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Parsed Data: $data'); // Debug parsed data

        setState(() {
          userPosts = data;
        });
      } else {
        print('Failed to fetch user posts: ${response.body}');
      }
    } catch (e) {
      print('Error fetching user posts: $e');
    }
  }

  Widget _displayProfileImage() {
    if (profilePictureUrl.isNotEmpty) {
      try {
        return CircleAvatar(
          radius: 50,
          backgroundImage: MemoryImage(base64Decode(profilePictureUrl)),
        );
      } catch (e) {
        print('Error decoding profile picture: $e');
        return _defaultProfileImage();
      }
    } else {
      return _defaultProfileImage();
    }
  }

  Widget _defaultProfileImage() {
    return CircleAvatar(
      radius: 50,
      backgroundImage: AssetImage('assets/avatar.png'),
    );
  }

Widget _buildPostCard(dynamic post) {
  print('Building Post Card: $post'); // Debug post data
  return GestureDetector(
    onTap: () {
      // นำไปยังหน้า ProductDetailPage
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductDetailPage(
            product: post,
            onFavoriteUpdate: (updatedProduct) {
              // อัปเดตข้อมูลโพสต์ในหน้า ProfileView หากมีการเปลี่ยนแปลง
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
                    post['imageUrl'], // ใช้ URL แทน Base64
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 150,
                        color: Colors.grey[200],
                        child: Icon(Icons.broken_image, size: 100),
                      );
                    },
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
          Padding(
            padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
            child: Text(
              '฿${post['price']}',
              style: TextStyle(fontSize: 16, color: Colors.pink),
              ),
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
        title: Text('โปรไฟล์ผู้ใช้'),
        backgroundColor: Colors.pink,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // โปรไฟล์ส่วนบน
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
                    ],
                  ),
                ),
                Divider(),
                // โพสต์ของผู้ใช้
                Expanded(
                  child: userPosts.isEmpty
                      ? Center(child: Text('ไม่มีโพสต์จากผู้ใช้งาน'))
                      : ListView.builder(
                          itemCount: userPosts.length,
                          itemBuilder: (context, index) {
                            return _buildPostCard(userPosts[index]);
                          },
                        ),
                ),
                // ปุ่มพูดคุย
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
      padding: EdgeInsets.symmetric(vertical: 12),
      backgroundColor: Colors.pink,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25),
      ),
    ),
    child: Text('คุยกับผู้รับหิ้ว', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ],
            ),
    );
  }
}
