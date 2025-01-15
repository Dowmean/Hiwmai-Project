import 'dart:convert';
import 'package:flutter/material.dart';
import 'UserService.dart'; // Import your UserService

class UserListPage extends StatefulWidget {
  @override
  _UserListPageState createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  final UserService _userService = UserService();

  Future<List<dynamic>>? _usersFuture;

  @override
  void initState() {
    super.initState();
    _usersFuture = _userService.fetchAllUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('จัดการบัญชีผู้ใช้งาน'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No users found'));
          } else {
            final users = snapshot.data!;
            return ListView.builder(
  itemCount: users.length,
  itemBuilder: (context, index) {
    final user = users[index];
    final profilePictureUrl = user['profile_picture'];
    print('Profile Picture URL: $profilePictureUrl'); // Debug URL

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        children: [
CircleAvatar(
  radius: 30, // Adjust the size of the avatar
  backgroundImage: profilePictureUrl != null && profilePictureUrl.isNotEmpty
      ? NetworkImage(profilePictureUrl)
      : null,
  onBackgroundImageError: profilePictureUrl != null && profilePictureUrl.isNotEmpty
      ? (exception, stackTrace) {
          print('Error loading profile picture: $exception');
        }
      : null, // Don't use onBackgroundImageError if backgroundImage is null
  child: profilePictureUrl == null || profilePictureUrl.isEmpty
      ? Icon(Icons.person, size: 30)
      : null,
),

          SizedBox(width: 16), // Spacing between avatar and text
          Expanded(
            child: Text(
              user['first_name'],
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete, color: Colors.red, size: 28),
            onPressed: () async {
              final confirmed = await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Confirm Deletion'),
                  content: Text('Are you sure you want to delete this user?'),
                  actions: [
                    TextButton(
                      child: Text('Cancel'),
                      onPressed: () => Navigator.pop(context, false),
                    ),
                    TextButton(
                      child: Text('Delete'),
                      onPressed: () => Navigator.pop(context, true),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                try {
                  await _userService.deleteUser(user['email']);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${user['first_name']} deleted successfully'),
                    ),
                  );

                  setState(() {
                    _usersFuture = _userService.fetchAllUsers();
                  });
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
