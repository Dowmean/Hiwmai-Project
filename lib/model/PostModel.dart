import 'package:cloud_firestore/cloud_firestore.dart'; // นำเข้า cloud_firestore สำหรับ Timestamp

class PostModel {
  String? id; // ID ของเอกสาร (อาจสร้างในภายหลัง)
  String userName;
  String userId;
  String category;
  String productName;
  String productDescription;
  double price;
  String? imageUrl;
  DateTime postedDate;

  PostModel({
    this.id,
    required this.userName,
    required this.userId,
    required this.category,
    required this.productName,
    required this.productDescription,
    required this.price,
    this.imageUrl,
    required this.postedDate,
  });

  // สร้างฟังก์ชันจาก Map (ดึงข้อมูลจาก Firestore)
  factory PostModel.fromMap(Map<String, dynamic> data, String documentId) {
    return PostModel(
      id: documentId,
      userName: data['userName'],
      userId: data['userId'],
      category: data['category'],
      productName: data['productName'],
      productDescription: data['productDescription'],
      price: data['price'].toDouble(),
      imageUrl: data['imageUrl'],
      postedDate: (data['postedDate'] as Timestamp).toDate(), // แปลง Timestamp เป็น DateTime
    );
  }

  // แปลงข้อมูลเป็น Map (เขียนข้อมูลลง Firestore)
  Map<String, dynamic> toMap() {
    return {
      'userName': userName,
      'userId': userId,
      'category': category,
      'productName': productName,
      'productDescription': productDescription,
      'price': price,
      'imageUrl': imageUrl,
      'postedDate': postedDate,
    };
  }
}
