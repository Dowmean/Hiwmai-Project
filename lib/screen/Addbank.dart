import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class AddBankScreen extends StatefulWidget {
  const AddBankScreen({super.key});

  @override
  _AddBankScreenState createState() => _AddBankScreenState();
}

class _AddBankScreenState extends State<AddBankScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController fullnameController = TextEditingController();
  final TextEditingController bankNumberController = TextEditingController();
  
  String selectedBank = "กรุงไทย (KTB)"; // ค่าเริ่มต้น
  bool isDefault = false;

  // 🔹 รายชื่อธนาคารในไทย (เพิ่มมากขึ้น)
  final List<String> bankList = [
    "กรุงไทย (KTB)",
    "กรุงเทพ (BBL)",
    "กสิกรไทย (KBank)",
    "ไทยพาณิชย์ (SCB)",
    "ธนชาต (TTB)",
    "ออมสิน (GSB)",
    "ยูโอบี (UOB)",
    "ซีไอเอ็มบี ไทย (CIMB)",
    "แลนด์ แอนด์ เฮ้าส์ (LH Bank)",
    "ทหารไทยธนชาต (TTB)",
    "เกียรตินาคินภัทร (KKP)",
    "ซิตี้แบงก์ (Citi)",
    "สแตนดาร์ดชาร์เตอร์ด (Standard Chartered)",
    "ไอซีบีซี (ICBC)",
    "ไทยเครดิต (Thai Credit)",
    "เวสเทิร์น ยูเนี่ยน (Western Union)",
  ];

  Future<void> addBankAccount() async {
    if (!_formKey.currentState!.validate()) return;

    String firebaseUid = FirebaseAuth.instance.currentUser!.uid;
    String email = FirebaseAuth.instance.currentUser!.email ?? "";

    await http.post(
      Uri.parse('http://10.0.2.2:3000/bank-accounts'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "firebase_uid": firebaseUid,
        "email": email,
        "fullname": fullnameController.text,
        "banknumber": bankNumberController.text,
        "bankname": selectedBank,
        "is_default": isDefault
      }),
    );

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("เพิ่มบัญชีธนาคาร")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: fullnameController,
                decoration: const InputDecoration(labelText: "ชื่อ-นามสกุล"),
                validator: (value) => value!.isEmpty ? "กรุณากรอกชื่อ-นามสกุล" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: bankNumberController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "เลขบัญชีธนาคาร"),
                validator: (value) => value!.isEmpty ? "กรุณากรอกเลขบัญชี" : null,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedBank,
                items: bankList.map((String bank) {
                  return DropdownMenuItem(
                    value: bank,
                    child: Text(bank),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    selectedBank = newValue!;
                  });
                },
                decoration: const InputDecoration(labelText: "เลือกธนาคาร"),
              ),
              const SizedBox(height: 10),
              CheckboxListTile(
                title: const Text("ตั้งเป็นบัญชีธนาคารเริ่มต้น"),
                value: isDefault,
                onChanged: (value) {
                  setState(() {
                    isDefault = value!;
                  });
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: addBankAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text("บันทึก", style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
