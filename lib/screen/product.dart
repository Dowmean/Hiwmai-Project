import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProductPage extends StatelessWidget {
  const ProductPage({super.key});

  // ฟังก์ชันดึงข้อมูลจาก Firestore
  Stream<QuerySnapshot> getPosts() {
    return FirebaseFirestore.instance.collection('posts').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Product List"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: getPosts(),  // เรียกใช้ฟังก์ชันเพื่อดึงข้อมูลจาก Firebase
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          // ถ้า snapshot มีข้อมูล
          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            // สร้างรายการจากข้อมูลใน Firebase
            return ListView(
              children: snapshot.data!.docs.map((DocumentSnapshot document) {
                Map<String, dynamic> data = document.data() as Map<String, dynamic>;

                return Card(
                  child: ListTile(
                    leading: data['imageUrl'] != null
                        ? Image.network(data['imageUrl'], height: 50, width: 50)
                        : Icon(Icons.image),
                    title: Text(data['productName'] ?? 'No Product Name'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Category: ${data['category']}'),
                        Text('Price: ${data['price']} ฿'),
                        Text(data['productDescription'] ?? 'No Description'),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          } else {
            return Center(child: Text("No products found"));
          }
        },
      ),
    );
  }
}
