import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:loginsystem/screen/AddAddress.dart';

class SelectAddressScreen extends StatefulWidget {
  @override
  _SelectAddressScreenState createState() => _SelectAddressScreenState();
}

class _SelectAddressScreenState extends State<SelectAddressScreen> {
  List addresses = [];
  String firebaseUid = FirebaseAuth.instance.currentUser!.uid;
  String baseUrl = 'http://10.0.2.2:3000';

  @override
  void initState() {
    super.initState();
    fetchAddresses();
  }

  Future<void> fetchAddresses() async {
    final response = await http.get(Uri.parse('$baseUrl/addresses/$firebaseUid'));
    if (response.statusCode == 200) {
      setState(() {
        addresses = json.decode(response.body);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("เลือกที่อยู่")),
      body: addresses.isEmpty
          ? const Center(child: Text("ไม่มีที่อยู่ที่บันทึกไว้", style: TextStyle(fontSize: 18)))
          : ListView.builder(
              itemCount: addresses.length,
              itemBuilder: (context, index) {
                final address = addresses[index];
                return InkWell(
                  onTap: () {
                    Navigator.pop(context, address); // ✅ ส่งที่อยู่กลับไป OrderPage
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 🔹 แสดงชื่อผู้รับ และป้ายค่าเริ่มต้น
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                address['name'],
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              if (address['is_default'] == 1)
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    "ค่าเริ่มต้น",
                                    style: TextStyle(color: Colors.white, fontSize: 14),
                                  ),
                                ),
                            ],
                          ),

                          SizedBox(height: 5),

                          // 🔹 แสดงรายละเอียดที่อยู่
                          Text(
                            "${address['address_detail']}, ${address['subdistrict'] ?? '-'}, ${address['district'] ?? '-'}, ${address['province'] ?? '-'}, ${address['postal_code'] ?? '-'}",
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          bool? isAdded = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddAddressScreen()),
          );
          if (isAdded == true) {
            fetchAddresses(); // ✅ รีโหลดที่อยู่ใหม่
          }
        },
        backgroundColor: Colors.pinkAccent,
        child: const Icon(Icons.add),
      ),
    );
  }
}
