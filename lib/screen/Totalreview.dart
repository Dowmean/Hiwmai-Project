import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TotalReview extends StatefulWidget {
  final String email;
  const TotalReview({Key? key, required this.email}) : super(key: key);

  @override
  _TotalReviewState createState() => _TotalReviewState();
}

class _TotalReviewState extends State<TotalReview> {
  List<dynamic> reviews = [];
  double avgRating = 0.0;
  int totalReviews = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserReviews();
  }

  Future<void> _fetchUserReviews() async {
    final String apiUrl = 'http://10.0.2.2:3000/getUserReviews?email=${widget.email}';
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          reviews = data['reviews'];
          avgRating = reviews.isNotEmpty
              ? reviews.map((r) => r['rate']).reduce((a, b) => a + b) / reviews.length
              : 0.0;
          totalReviews = reviews.length;
        });
      }
    } catch (e) {
      print('Error fetching user reviews: $e');
    }
  }

  Widget _buildReviewHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "รีวิวผู้รับหิ้ว",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              Text(
                avgRating.toStringAsFixed(1),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.pink),
              ),
              Text(
                " - 5.0 ",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.pink),
              ),
              Text(
                "(${totalReviews} รีวิว)",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(dynamic review) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: review['reviewer_profile'] != null
                ? NetworkImage(review['reviewer_profile'])
                : AssetImage('assets/avatar.png') as ImageProvider,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${review['reviewer_name'].substring(0, 2)} ****', // ✅ ซ่อนบางส่วนของชื่อ
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < review['rate'] ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 20,
                    );
                  }),
                ),
                if (review['description'] != null && review['description'].isNotEmpty) // ✅ แสดงเฉพาะเมื่อมี description
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      review['description'],
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text("รีวิวผู้รับหิ้ว"),
        
      ),
      body: reviews.isEmpty
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildReviewHeader(),
                Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: reviews.length,
                    itemBuilder: (context, index) {
                      return _buildReviewCard(reviews[index]);
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
