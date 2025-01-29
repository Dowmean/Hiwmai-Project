import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MyReviewsPage extends StatelessWidget {
  final String userEmail;
  final String orderRef;

  MyReviewsPage({required this.userEmail, required this.orderRef});

  Future<Map<String, dynamic>> fetchReviewDetails() async {
    try {
      //print('Fetching details for email: $userEmail, orderRef: $orderRef');
      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/getReviewDetails?email=$userEmail&orderRef=$orderRef'),
      );

      if (response.statusCode == 200) {
        //print('Response data: ${response.body}');
        return json.decode(response.body);
      } else {
        //print('Failed with status: ${response.statusCode}');
        throw Exception('Failed to fetch review details');
      }
    } catch (e) {
      //print('Error fetching review details: $e');
      throw Exception('Error fetching review details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // ลบปุ่มย้อนกลับ
        centerTitle: true, 
        title: Text('รายละเอียดรีวิว', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchReviewDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: Text('ไม่มีข้อมูลรีวิว'));
          } else {
            final review = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: review['profile_picture'] != null &&
                                    review['profile_picture'].toString().isNotEmpty
                                ? NetworkImage(review['profile_picture'])
                                : AssetImage('assets/avatar_placeholder.png') as ImageProvider,
                            radius: 30,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              review['first_name']?.toString() ?? 'Unknown User', // แสดง u.first_name
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 20),
if (review['productName'] != null && review['productName'].toString().isNotEmpty)
  Text(
    review['productName'], // แสดงชื่อผลิตภัณฑ์
    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
  ),
SizedBox(height: 10),
                      if (review['product_image'] != null &&
                          review['product_image'].toString().isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            review['product_image'], // แสดง p.imageUrl
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 200,
                                color: Colors.grey[200],
                                child: Center(child: Icon(Icons.broken_image)),
                              );
                            },
                          ),
                        )
                      else
                        Container(
                          height: 200,
                          color: Colors.grey[200],
                          child: Center(child: Icon(Icons.broken_image)),
                        ),
                      SizedBox(height: 20),
                      Text(
                        'คะแนนรีวิว',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            index < (review['review_rate'] ?? 0)
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.orange,
                          );
                        }),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'คำอธิบาย:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      Text(
                        review['review_description']?.toString() ?? 'ไม่มีคำอธิบาย',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'หมายเลขคำสั่งซื้อ: ${review['order_ref']}',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
