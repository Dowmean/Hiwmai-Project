import 'package:http/http.dart' as http;
import 'dart:convert';

class ProductService {
  final String apiUrl = 'http://10.0.2.2:3000/getproduct'; // API to get products

  // Function to fetch product data
  Future<List<dynamic>> fetchProducts() async {
    try {
      var response = await http.get(Uri.parse(apiUrl), headers: {"Content-Type": "application/json"});
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception("Failed to load products");
      }
    } catch (e) {
      throw Exception("Error fetching products: $e");
    }
  }
}
