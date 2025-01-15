import 'package:mysql1/mysql1.dart'; // Import mysql1 for MySQL

class PostModel {
  int? id; // Use int for MySQL ID
  String userName;
  String userId;
  String category;
  String productName;
  String productDescription;
  double price;
  List<int>? imageUrl; // Change to binary (List<int>) to handle BLOBs
  DateTime postedDate;

  PostModel({
    this.id,
    required this.userName,
    required this.userId,
    required this.category,
    required this.productName,
    required this.productDescription,
    required this.price,
    this.imageUrl, // Nullable for optional image
    required this.postedDate,
  });

  // Create from Map (used to retrieve from MySQL)
  factory PostModel.fromMap(ResultRow row) {
    return PostModel(
      id: row['id'],
      userName: row['userName'],
      userId: row['userId'],
      category: row['category'],
      productName: row['productName'],
      productDescription: row['productDescription'],
      price: row['price'],
      imageUrl: row['imageUrl'] != null ? (row['imageUrl'] as Blob).toBytes() : null, // Handle BLOB conversion
      postedDate: DateTime.parse(row['postedDate']),
    );
  }

  // Convert to Map (for writing to MySQL)
  Map<String, dynamic> toMap() {
    return {
      'userName': userName,
      'userId': userId,
      'category': category,
      'productName': productName,
      'productDescription': productDescription,
      'price': price,
      'imageUrl': imageUrl, // Send binary data (BLOB)
      'postedDate': postedDate.toIso8601String(),
    };
  }

  // Insert data into MySQL
  Future<void> insertToMySQL(MySqlConnection connection) async {
    var result = await connection.query(
      'INSERT INTO product (userName, userId, category, productName, productDescription, price, imageUrl, postedDate) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      [userName, userId, category, productName, productDescription, price, imageUrl, postedDate.toIso8601String()],
    );
    id = result.insertId; // Store the newly created ID
  }
}
