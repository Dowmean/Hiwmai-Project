import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:loginsystem/screen/AddAddress.dart';

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

  Future<void> fetchAddresses() async {
    final response = await http.get(Uri.parse('http://10.0.2.2:3000/addresses/$firebaseUid'));
    if (response.statusCode == 200) {
      setState(() {
        addresses = json.decode(response.body);
      });
    }
  }

  Future<void> deleteAddress(int id) async {
    await http.delete(Uri.parse('http://10.0.2.2:3000/addresses/$id'));
    fetchAddresses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ที่อยู่ของฉัน")),
      body: ListView.builder(
        itemCount: addresses.length,
        itemBuilder: (context, index) {
          final address = addresses[index];
          return Card(
            child: ListTile(
              title: Text(address['name']),
              subtitle: Text("${address['address_detail']}, ${address['city']}, ${address['postal_code']}"),
              trailing: address['is_default'] == 1
                  ? ElevatedButton(
                      onPressed: () {}, 
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                      child: const Text("ค่าเริ่มต้น"),
                    )
                  : IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => deleteAddress(address['id']),
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
