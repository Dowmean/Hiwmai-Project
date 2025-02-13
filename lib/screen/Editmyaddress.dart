import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

class EditMyAddressScreen extends StatefulWidget {
  final int addressId; // ✅ รับค่า ID ของที่อยู่ที่ต้องแก้ไข

  const EditMyAddressScreen({super.key, required this.addressId});

  @override
  _EditMyAddressScreenState createState() => _EditMyAddressScreenState();
}

class _EditMyAddressScreenState extends State<EditMyAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressDetailController = TextEditingController();

  String? selectedProvince;
  String? selectedDistrict;
  String? selectedSubdistrict;
  String? postalCode = "-";
  bool isDefault = false;
  String addressType = "บ้าน";
  bool isLoading = true;

  List<dynamic> provinces = [];
  List<dynamic> districts = [];
  List<dynamic> subdistricts = [];
  List<String> addressTypes = ["บ้าน", "ที่ทำงาน", "อื่นๆ"];

  final String baseUrl = 'http://10.0.2.2:3000';
  final String firebaseUid = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _fetchAddress();
    fetchProvinces();
  }

  // ✅ ดึงข้อมูลที่อยู่ที่ต้องแก้ไข
  Future<void> _fetchAddress() async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/addresses/id/${widget.addressId}'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
setState(() {
  nameController.text = data["name"] ?? "";
  phoneController.text = data["phone"] ?? "";
  addressDetailController.text = data["address_detail"] ?? "";
  selectedProvince = data["province"] != null ? data["province"].toString() : "";
  selectedDistrict = data["district"] != null ? data["district"].toString() : "";
  selectedSubdistrict = data["subdistrict"] != null ? data["subdistrict"].toString() : "";
  postalCode = data["postal_code"] != null ? data["postal_code"].toString() : "-";
  isDefault = data["is_default"] == 1;
  addressType = data["address_type"] ?? "บ้าน";
  isLoading = false;
});


        if (selectedProvince != null) fetchDistricts(selectedProvince!);
        if (selectedDistrict != null) fetchSubdistricts(selectedDistrict!);
      } else {
        print("❌ ไม่พบที่อยู่ที่ต้องแก้ไข");
      }
    } catch (e) {
      print("❌ Error fetching address: $e");
    }
  }

  // ✅ ดึงข้อมูลจังหวัด
  Future<void> fetchProvinces() async {
    final response = await http.get(Uri.parse('$baseUrl/provinces'));
    if (response.statusCode == 200) {
      setState(() {
        provinces = json.decode(response.body);
      });
    }
  }

  // ✅ ดึงข้อมูลอำเภอ
  Future<void> fetchDistricts(String provinceId) async {
    final response = await http.get(Uri.parse('$baseUrl/amphures/$provinceId'));
    if (response.statusCode == 200) {
      setState(() {
        districts = json.decode(response.body);
      });

      if (selectedDistrict != null) {
        fetchSubdistricts(selectedDistrict!);
      }
    }
  }

  // ✅ ดึงข้อมูลตำบล
  Future<void> fetchSubdistricts(String districtId) async {
    final response = await http.get(Uri.parse('$baseUrl/districts/$districtId'));
    if (response.statusCode == 200) {
      setState(() {
        subdistricts = json.decode(response.body);
        if (selectedSubdistrict != null) {
          updatePostalCode(selectedSubdistrict!);
        }
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

  // ✅ ฟังก์ชันแก้ไขที่อยู่
Future<void> updateAddress() async {
  if (!_formKey.currentState!.validate()) return;

  final requestData = {
    "firebase_uid": firebaseUid,
    "name": nameController.text.isEmpty ? null : nameController.text,
    "phone": phoneController.text.isEmpty ? null : phoneController.text,
    "address_detail": addressDetailController.text.isEmpty ? null : addressDetailController.text,
    "province": selectedProvince == null || selectedProvince!.isEmpty ? null : selectedProvince,
    "district": selectedDistrict == null || selectedDistrict!.isEmpty ? null : selectedDistrict,
    "subdistrict": selectedSubdistrict == null || selectedSubdistrict!.isEmpty ? null : selectedSubdistrict,
    "postal_code": postalCode == null || postalCode!.isEmpty ? null : postalCode,
    "is_default": isDefault,
    "address_type": addressType.isEmpty ? "บ้าน" : addressType, // ✅ Ensure it's not empty
  };

  print("📌 Request Data: $requestData"); // ✅ Debugging line

  final response = await http.put(
    Uri.parse('$baseUrl/addresses/${widget.addressId}'),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode(requestData),
  );

  print("📌 API Response: ${response.body}"); // ✅ Debugging line

  if (response.statusCode == 200) {
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
      appBar: AppBar(title: const Text("แก้ไขที่อยู่")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
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
  value: selectedProvince ?? "", // ✅ ป้องกัน null
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
  children: addressTypes.map((type) {
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
                      onPressed: updateAddress,
                      child: const Text("บันทึกการเปลี่ยนแปลง"),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
