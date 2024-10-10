import 'package:flutter/material.dart'; 
import 'package:loginsystem/screen/login.dart';
import 'package:loginsystem/screen/register.dart';
import 'package:loginsystem/screen/createpost.dart';  // นำเข้า CreatePostPage
import 'package:loginsystem/screen/product.dart';  // นำเข้า ProductPage

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Register/Login/Create Post"),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(10, 50, 10, 0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Image.asset("assets/images/person.png"),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.add),
                  label: Text("สร้างบัญชีผู้ใช้", style: TextStyle(fontSize: 20)),
                  onPressed: () {
                    Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (context) {
                        return RegisterScreen();
                      })
                    );
                  },
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.login),
                  label: Text("เข้าสู่ระบบ", style: TextStyle(fontSize: 20)),
                  onPressed: () {
                    Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (context) {
                        return LoginScreen();
                      })
                    );
                  },
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.post_add),
                  label: Text("สร้างโพสต์", style: TextStyle(fontSize: 20)),
                  onPressed: () {
                    Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (context) {
                        return CreatePostPage();  // นำทางไปยังหน้า Create Post
                      })
                    );
                  },
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.shopping_cart),
                  label: Text("ดูรายการสินค้า", style: TextStyle(fontSize: 20)),  // ปุ่มดูรายการสินค้า
                  onPressed: () {
                    Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (context) {
                        return ProductPage();  // นำทางไปยังหน้า ProductPage
                      })
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
