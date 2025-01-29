import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OrderReview extends StatefulWidget {
  final String ref; // Reference ของคำสั่งซื้อ
  final String productName;
  final String productImage;
  final String email;

  OrderReview({
    required this.ref,
    required this.productName,
    required this.productImage,
    required this.email,
  });

  @override
  _OrderReviewState createState() => _OrderReviewState();
}

class _OrderReviewState extends State<OrderReview> {
  int _rating = 0;
  TextEditingController _reviewController = TextEditingController();
  bool isSubmitting = false;

  Future<void> submitReview() async {
    if (_rating == 0 || _reviewController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please provide a rating and a review.')),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:3000/addReview'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'ref': widget.ref,
          'email': widget.email,
          'rate': _rating,
          'description': _reviewController.text,
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Review submitted successfully!')),
        );
        Navigator.pop(context); // กลับไปหน้าก่อนหน้า
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit review.')),
        );
      }
    } catch (e) {
      //print('Error submitting review: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred while submitting the review.')),
      );
    } finally {
      setState(() {
        isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ให้คะแนนสินค้า', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: isSubmitting ? null : submitReview,
            child: Text(
              'ยืนยัน',
              style: TextStyle(color: Colors.pink, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.network(
                  widget.productImage,
                  height: 60,
                  width: 60,
                  fit: BoxFit.cover,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.productName,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Text('คุณภาพสินค้า', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Row(
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    Icons.star,
                    color: _rating > index ? Colors.orange : Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _rating = index + 1;
                    });
                  },
                );
              }),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _reviewController,
              decoration: InputDecoration(
                hintText: 'เขียนรีวิวสินค้าเพิ่มเติม',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 5,
            ),
            if (isSubmitting)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
