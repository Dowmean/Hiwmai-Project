//user
import 'dart:convert';
import 'package:http/http.dart' as http;

class OrderSuccessService {
  static Future<List<dynamic>> fetchSuccessOrders(String email) async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/SuccessOrdersByEmailUser?email=$email'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['orders'] ?? [];
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to fetch success orders.');
      }
    } catch (e) {
      throw Exception('An error occurred while fetching success orders: $e');
    }
  }
}
