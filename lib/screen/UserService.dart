import 'dart:convert';
import 'package:http/http.dart' as http;

class UserService {
  final String baseUrl = 'http://10.0.2.2:3000';

  // Fetch all users
  Future<List<dynamic>> fetchAllUsers() async {
    final url = Uri.parse('$baseUrl/getAllUsers');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body); // Return the list of users
      } else {
        throw Exception('Failed to fetch users: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching users: $e');
    }
  }

  // Delete user by email
  Future<void> deleteUser(String email) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/deleteUser'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete user');
    }
  }
}
