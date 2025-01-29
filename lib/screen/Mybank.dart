import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:loginsystem/screen/Addbank.dart';

class MyBankScreen extends StatefulWidget {
  const MyBankScreen({super.key});

  @override
  _MyBankScreenState createState() => _MyBankScreenState();
}

class _MyBankScreenState extends State<MyBankScreen> {
  List bankAccounts = [];
  String firebaseUid = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    fetchBankAccounts();
  }

  Future<void> fetchBankAccounts() async {
    final response = await http.get(Uri.parse('http://10.0.2.2:3000/bank-accounts/$firebaseUid'));
    if (response.statusCode == 200) {
      setState(() {
        bankAccounts = json.decode(response.body);
      });
    }
  }

  Future<void> deleteBankAccount(int id) async {
    await http.delete(Uri.parse('http://10.0.2.2:3000/bank-accounts/$id'));
    fetchBankAccounts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("บัญชีธนาคารของฉัน")),
      body: ListView.builder(
        itemCount: bankAccounts.length,
        itemBuilder: (context, index) {
          final bank = bankAccounts[index];
          String bankLogoPath = 'assets/banks/${bank['bankname'].toLowerCase().replaceAll(" ", "")}.png';

          return Card(
            child: ListTile(
              leading: Image.asset(
                bankLogoPath,
                width: 40,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.account_balance, size: 40, color: Colors.grey);
                },
              ),
              title: Text("${bank['bankname']} (${bank['fullname']})"),
              subtitle: Text("•••• ${bank['banknumber'].substring(bank['banknumber'].length - 4)}"),
              trailing: bank['is_default'] == 1
                  ? ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                      child: const Text("ค่าเริ่มต้น"),
                    )
                  : IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => deleteBankAccount(bank['id']),
                    ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddBankScreen()),
          );
        },
        backgroundColor: Colors.pinkAccent,
        child: const Icon(Icons.add),
      ),
    );
  }
}
