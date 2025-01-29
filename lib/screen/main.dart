import 'package:flutter/material.dart';
import 'package:loginsystem/screen/Homepage.dart';
import 'package:loginsystem/screen/ProductListPage.dart';
import 'package:loginsystem/screen/Profilepage.dart';
import 'package:loginsystem/screen/PostCreate.dart';
import 'package:loginsystem/screen/feed.dart'; 
class MainScreen extends StatefulWidget {
  final String email; // เพิ่มตัวแปร email

  MainScreen({this.email=''}); // Constructor สำหรับรับ email

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    // Debug: ตรวจสอบค่า email ที่ส่งเข้ามา
    //print('Email in MainScreen: ${widget.email}');

    // กำหนดหน้าต่าง ๆ พร้อมส่ง email ไปยัง ProductListPage และ ProfileScreen
    _pages = [
      HomepageScreen(),
      ProductListPage(), // ส่ง email ไปที่ ProductListPage
      ProductFeedScreen(),
      ProfileScreen(), // ส่ง email ไปที่ ProfileScreen
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex], // แสดงหน้าที่เลือก
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.pink,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped, // อัปเดต index เมื่อมีการเลือกเมนู
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favorite'),
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Feed'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}