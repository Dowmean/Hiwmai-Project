import 'dart:convert';
import 'package:http/http.dart' as http;

class ShippingService {
  static Future<List<dynamic>> fetchShippingOrders(String email) async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/ShippingOrdersByEmailUser?email=$email'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['orders'] ?? [];
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to fetch shipping orders.');
      }
    } catch (e) {
      throw Exception('An error occurred while fetching shipping orders: $e');
    }
  }
}
