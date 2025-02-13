import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:loginsystem/screen/Transfer.dart';

class RecipientDetailPage extends StatelessWidget {
  final String firebaseUid;
  final String endpoint;

  const RecipientDetailPage({
    Key? key,
    required this.firebaseUid,
    required this.endpoint,
  }) : super(key: key);

  Future<Map<String, dynamic>> fetchIncomeData() async {
    try {
      final response = await http
          .get(Uri.parse(
              'http://10.0.2.2:3000/recipients/$firebaseUid/$endpoint'))
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map<String, dynamic>) {
          return data;
        }
      }
      return {}; // ส่งค่า empty map หาก response ไม่ใช่ 200 หรือ data ไม่ถูกต้อง
    } catch (e) {
      //print('Error fetching income data: $e');
      return {}; // ส่งค่า empty map ในกรณีมีข้อผิดพลาด
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: fetchIncomeData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('Error: ${snapshot.error}',
                  style: TextStyle(color: Colors.red)),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Scaffold(
            body: Center(
              child: Text('ไม่มีข้อมูลธนาคาร',
                  style: TextStyle(color: Colors.grey)),
            ),
          );
        } else {
          final incomeData = snapshot.data!;
          return DefaultTabController(
            length: 3,
            child: Scaffold(
              appBar: AppBar(
                automaticallyImplyLeading: false,
                centerTitle: true,
                title: Text('รายละเอียดข้อมูลการชำระเงิน'),
                bottom: TabBar(
                  labelColor: Colors.pink,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.pink,
                  tabs: [
                    Tab(text: 'ทั้งหมด'),
                    Tab(text: 'รอดำเนินการ'),
                    Tab(text: 'ทำการจ่ายเรียบร้อยแล้ว'),
                  ],
                ),
              ),
              body: Column(
                children: [
                  // กรอบข้อมูลธนาคาร
                  Container(
                    padding: const EdgeInsets.all(20.20), // ระยะห่างด้านในกรอบ
                    margin: const EdgeInsets.symmetric(
                        horizontal: 20.30,
                        vertical: 32.300), // เพิ่ม margin แนวนอน (ซ้าย-ขวา)
                    decoration: BoxDecoration(
                      color: Colors.white, // สีพื้นหลังของกรอบ
                      border: Border.all(
                          color: Colors.pink, width: 1), // เส้นกรอบสีชมพูบางลง
                      borderRadius:
                          BorderRadius.circular(12), // ความโค้งของกรอบ
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ธนาคาร: ${incomeData['bankName'] ?? 'Not provided'}',
                          style: TextStyle(fontSize: 18),
                        ),
                        SizedBox(height: 16), // เพิ่มระยะห่างระหว่างข้อความ
                        Text(
                          'ชื่อบัญชี : ${incomeData['accountName'] ?? 'Not provided'}',
                          style: TextStyle(fontSize: 18),
                        ),
                        SizedBox(height: 16), // เพิ่มระยะห่างระหว่างข้อความ
                        Text(
                          'เลขบัญชี : ${incomeData['accountNumber'] ?? 'Not provided'}',
                          style: TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                  ),

                  // TabBarView
                  Expanded(
                    child: TabBarView(
                      children: [
                        IncomeTab(
                            firebaseUid: firebaseUid, endpoint: 'ALLincome'),
                        IncomeTab(
                            firebaseUid: firebaseUid,
                            endpoint: 'Successincome'),
                        IncomeTab(
                            firebaseUid: firebaseUid, endpoint: 'Complete'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildFormField(String label, dynamic value) {
    final displayValue = (value != null && value.toString().isNotEmpty)
        ? value.toString()
        : 'Not provided';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        SizedBox(height: 5),
        Container(
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            displayValue,
            style: TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
}

class IncomeTab extends StatelessWidget {
  final String firebaseUid;
  final String endpoint;

  const IncomeTab({Key? key, required this.firebaseUid, required this.endpoint})
      : super(key: key);

  Future<Map<String, dynamic>> fetchIncomeData() async {
    try {
      final response = await http
          .get(Uri.parse(
              'http://10.0.2.2:3000/recipients/$firebaseUid/$endpoint'))
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map<String, dynamic>) {
          return data;
        }
      }
      return {}; // ส่งค่า empty map หาก response ไม่ใช่ 200 หรือ data ไม่ถูกต้อง
    } catch (e) {
      //('Error fetching income data: $e');
      return {}; // ส่งค่า empty map ในกรณีมีข้อผิดพลาด
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = new NumberFormat("#,##0.00", "th");
    return FutureBuilder<Map<String, dynamic>>(
      future: fetchIncomeData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}',
                style: TextStyle(color: Colors.red)),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text('ไม่มีใบแจ้งยอดชำระเงิน',
                style: TextStyle(color: Colors.grey)),
          );
        } else {
          final incomeData = snapshot.data!;
          final firstDate = DateTime.parse(incomeData['firstShopDate']);
          final lastDate = DateTime.parse(incomeData['lastShopDate']);

          final firstDateFormatted =
              '${firstDate.day} ${_getMonthName(firstDate.month)} ${firstDate.year}';
          final lastDateFormatted =
              '${lastDate.day} ${_getMonthName(lastDate.month)} ${lastDate.year}';

          // ระบุสถานะสำหรับแต่ละ Tab
          String statusLabel;
          if (endpoint == 'ALLincome') {
            statusLabel = 'ทั้งหมด';
          } else if (endpoint == 'Successincome') {
            statusLabel = 'รอดำเนินการ';
          } else if (endpoint == 'Complete') {
            statusLabel = 'ทำการจ่ายเรียบร้อยแล้ว';
          } else {
            statusLabel = 'ไม่ทราบสถานะ';
          }

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              ListTile(
                title: Text(
                  '$firstDateFormatted - $lastDateFormatted',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                subtitle: Text('สถานะ: $statusLabel'),
                trailing: Text(
                  '${formatter.format(double.tryParse(incomeData['totalIncome']?.toString() ?? '0') ?? 0.00)}',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green),
                ),
              ),

              // ✅ เพิ่มปุ่ม "โอนเงิน" เฉพาะใน Tab "รอดำเนินการ"
              if (endpoint == 'Successincome')
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: Icon(Icons.payment, color: Colors.white),
                    label: Text(
                      'โอนเงิน',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TransferPage(
                            firebaseUid: firebaseUid, // ส่ง UID ไป TransferPage
                            totalIncome: incomeData['totalIncome'].toString(),
                            amount: null, // ส่งยอดเงินไป TransferPage
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        }
      },
    );
  }

  String _getMonthName(int month) {
    const monthNames = [
      'มกราคม',
      'กุมภาพันธ์',
      'มีนาคม',
      'เมษายน',
      'พฤษภาคม',
      'มิถุนายน',
      'กรกฎาคม',
      'สิงหาคม',
      'กันยายน',
      'ตุลาคม',
      'พฤศจิกายน',
      'ธันวาคม'
    ];
    return monthNames[month - 1];
  }

  Widget _buildFormField(String label, dynamic value) {
    final displayValue = (value != null && value.toString().isNotEmpty)
        ? value.toString()
        : 'Not provided';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        SizedBox(height: 5),
        Container(
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            displayValue,
            style: TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
}
