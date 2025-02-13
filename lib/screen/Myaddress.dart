import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:loginsystem/screen/AddAddress.dart';
import 'package:loginsystem/screen/Editmyaddress.dart';

class MyAddressScreen extends StatefulWidget {
  const MyAddressScreen({super.key});

  @override
  _MyAddressScreenState createState() => _MyAddressScreenState();
}

class _MyAddressScreenState extends State<MyAddressScreen> {
  List addresses = [];
  String firebaseUid = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    fetchAddresses();
  }

  // ✅ ดึงรายการที่อยู่จาก API
  Future<void> fetchAddresses() async {
    final response = await http.get(Uri.parse('http://10.0.2.2:3000/addresses/$firebaseUid'));
    if (response.statusCode == 200) {
      setState(() {
        addresses = json.decode(response.body);
      });
    }
  }

  // ✅ ฟังก์ชันลบที่อยู่ (มี dialog ยืนยัน)
  Future<void> deleteAddress(int id) async {
    bool confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("ยืนยันการลบ"),
        content: const Text("คุณต้องการลบที่อยู่นี้หรือไม่?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("ยกเลิก")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context, true);
              await http.delete(Uri.parse('http://10.0.2.2:3000/addresses/$id'));
              fetchAddresses();
            },
            child: const Text("ลบ", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmDelete) {
      await http.delete(Uri.parse('http://10.0.2.2:3000/addresses/$id'));
      fetchAddresses();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ที่อยู่ของฉัน")),
      body: addresses.isEmpty
          ? const Center(child: Text("ไม่มีที่อยู่ที่บันทึกไว้", style: TextStyle(fontSize: 18)))
          : ListView.builder(
              itemCount: addresses.length,
              itemBuilder: (context, index) {
                final address = addresses[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🔹 แสดงชื่อผู้รับ
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              address['name'],
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            if (address['is_default'] == 1)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  "ค่าเริ่มต้น",
                                  style: TextStyle(color: Colors.white, fontSize: 14),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 5),

                        // 🔹 แสดงรายละเอียดที่อยู่
                        Text(
                          "${address['address_detail']}, ${address['subdistrict'] ?? '-'}, ${address['district'] ?? '-'}, ${address['province'] ?? '-'}, ${address['postal_code'] ?? '-'}",
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),

                        const SizedBox(height: 10),

// 🔹 ปุ่มแก้ไข & ลบที่อยู่
Row(
  mainAxisAlignment: MainAxisAlignment.end,
  children: [
    // 🔹 ปุ่มแก้ไข
    IconButton(
      icon: const Icon(Icons.edit, color: Colors.blue),
      onPressed: () async {
        bool? isEdited = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditMyAddressScreen(addressId: address['id']), // ✅ ส่ง `addressId` ไป
          ),
        );

        if (isEdited == true) fetchAddresses(); // รีโหลดรายการที่อยู่
      },
    ),


                            // 🔹 ปุ่มลบ
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => deleteAddress(address['id']),
                            ),
                          ],
                        ),
                      ],
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
