import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

class AddAddressScreen extends StatefulWidget {
  const AddAddressScreen({super.key});

  @override
  _AddAddressScreenState createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressDetailController = TextEditingController();

  String? selectedProvince;
  String? selectedDistrict;
  String? selectedSubdistrict;
  String? postalCode = "-"; // ✅ ค่าเริ่มต้น
  bool isDefault = false;
  String addressType = "บ้าน"; // ✅ ค่าเริ่มต้น

  List<dynamic> provinces = [];
  List<dynamic> districts = [];
  List<dynamic> subdistricts = [];

  @override
  void initState() {
    super.initState();
    fetchProvinces();
  }

  // ✅ ดึงข้อมูลจังหวัด
  Future<void> fetchProvinces() async {
    final response = await http.get(Uri.parse('http://10.0.2.2:3000/provinces'));
    if (response.statusCode == 200) {
      setState(() {
        provinces = json.decode(response.body);
      });
    }
  }

  // ✅ ดึงข้อมูลอำเภอ
  Future<void> fetchDistricts(String provinceId) async {
    final response = await http.get(Uri.parse('http://10.0.2.2:3000/amphures/$provinceId'));
    if (response.statusCode == 200) {
      setState(() {
        districts = json.decode(response.body);
        selectedDistrict = null;
        selectedSubdistrict = null;
        subdistricts = [];
        postalCode = "-";
      });
    }
  }

  // ✅ ดึงข้อมูลตำบล
  Future<void> fetchSubdistricts(String districtId) async {
    final response = await http.get(Uri.parse('http://10.0.2.2:3000/districts/$districtId'));
    if (response.statusCode == 200) {
      setState(() {
        subdistricts = json.decode(response.body);
        selectedSubdistrict = null;
        postalCode = "-";
      });
    }
  }

  // ✅ อัปเดตรหัสไปรษณีย์เมื่อเลือกตำบล
  void updatePostalCode(String subdistrictName) {
    final subdistrict = subdistricts.firstWhere(
      (s) => s["name_th"] == subdistrictName,
      orElse: () => {"zip_code": "-"},
    );

    setState(() {
      postalCode = subdistrict["zip_code"].toString();
    });
  }

  // ✅ เพิ่มที่อยู่ลงฐานข้อมูล
  Future<void> addAddress() async {
    if (!_formKey.currentState!.validate()) return;

    String firebaseUid = FirebaseAuth.instance.currentUser!.uid;
    String email = FirebaseAuth.instance.currentUser!.email ?? "";

    final response = await http.post(
      Uri.parse('http://10.0.2.2:3000/addresses'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "firebase_uid": firebaseUid,
        "email": email,
        "name": nameController.text,
        "phone": phoneController.text,
        "address_detail": addressDetailController.text,
        "province": selectedProvince,
        "district": selectedDistrict,
        "subdistrict": selectedSubdistrict,
        "postal_code": postalCode,
        "is_default": isDefault,
        "address_type": addressType
      }),
    );

    if (response.statusCode == 201) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("เกิดข้อผิดพลาด: ${response.body}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("เพิ่มที่อยู่ใหม่")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "ชื่อผู้รับ"),
                validator: (value) => value!.isEmpty ? "กรุณากรอกชื่อ" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: "เบอร์โทรศัพท์"),
                validator: (value) => value!.isEmpty ? "กรุณากรอกเบอร์โทรศัพท์" : null,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedProvince,
                items: provinces.map<DropdownMenuItem<String>>((province) {
                  return DropdownMenuItem<String>(
                    value: province["id"].toString(),
                    child: Text(province["name_th"]),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    selectedProvince = newValue;
                    fetchDistricts(newValue!);
                  });
                },
                decoration: const InputDecoration(labelText: "เลือกจังหวัด"),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedDistrict,
                items: districts.map<DropdownMenuItem<String>>((district) {
                  return DropdownMenuItem<String>(
                    value: district["id"].toString(),
                    child: Text(district["name_th"]),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    selectedDistrict = newValue;
                    fetchSubdistricts(newValue!);
                  });
                },
                decoration: const InputDecoration(labelText: "เลือกอำเภอ/เขต"),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedSubdistrict,
                items: subdistricts.map<DropdownMenuItem<String>>((subdistrict) {
                  return DropdownMenuItem<String>(
                    value: subdistrict["name_th"],
                    child: Text(subdistrict["name_th"]),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    selectedSubdistrict = newValue;
                    updatePostalCode(newValue!);
                  });
                },
                decoration: const InputDecoration(labelText: "เลือกตำบล/แขวง"),
              ),
              const SizedBox(height: 10),
              Text("รหัสไปรษณีย์: ${postalCode ?? '-'}"),
              const SizedBox(height: 10),
              TextFormField(
                controller: addressDetailController,
                decoration: const InputDecoration(labelText: "รายละเอียดที่อยู่"),
                validator: (value) => value!.isEmpty ? "กรุณากรอกรายละเอียดที่อยู่" : null,
              ),
               // 🔹 ตั้งค่า "ที่อยู่ตั้งต้น"
              SwitchListTile(
                title: const Text("เลือกเป็นที่อยู่ตั้งต้น"),
                value: isDefault,
                onChanged: (value) {
                  setState(() {
                    isDefault = value;
                  });
                },
              ),

              // 🔹 ประเภทที่อยู่
              const Text("ติดป้ายเป็น:"),
              Wrap(
                spacing: 10,
                children: ["ที่ทำงาน", "บ้าน", "อื่นๆ"].map((type) {
                  return ChoiceChip(
                    label: Text(type),
                    selected: addressType == type,
                    onSelected: (selected) {
                      setState(() {
                        addressType = type;
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: addAddress,
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
