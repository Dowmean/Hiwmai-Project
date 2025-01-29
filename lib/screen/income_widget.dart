import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class IncomeWidget extends StatefulWidget {
  final String firebaseUid;

  const IncomeWidget({
    Key? key,
    required this.firebaseUid,
  }) : super(key: key);

  @override
  State<IncomeWidget> createState() => _IncomeWidgetState();
}

class _IncomeWidgetState extends State<IncomeWidget> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> fetchIncomeData(String endpoint) async {
    try {
      final response = await http
          .get(Uri.parse('http://10.0.2.2:3000/recipients/${widget.firebaseUid}/$endpoint'))
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {};
    } catch (e) {
      print('Error fetching income data: $e');
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: InkWell(
              onTap: () {
                // โค้ดสำหรับเปลี่ยนช่วงวันที่
              },
              child: Row(
                children: [
                  Text(
                    '1 ก.ค. 2024 - 31 ก.ค. 2024',
                    style: TextStyle(fontSize: 14),
                  ),
                  Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
          FutureBuilder<Map<String, dynamic>>(
            future: fetchIncomeData('ALLincome'),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              
              final totalIncome = snapshot.data?['totalIncome'] ?? '0';
              
              return Column(
                children: [
                  Text(
                    totalIncome.toString(),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.pink,
                    ),
                  ),
                  
                  TabBar(
                    controller: _tabController,
                    labelColor: Colors.pink,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.pink,
                    tabs: [
                      Tab(text: 'ทั้งหมด'),
                      Tab(text: 'รอดำเนินการ'),
                      Tab(text: 'ทำการจ่ายเรียบร้อยแล้ว'),
                    ],
                  ),
                  
                  Container(
                    height: 80,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildIncomeTab('ALLincome'),
                        _buildIncomeTab('Successincome'),
                        _buildIncomeTab('Complete'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeTab(String endpoint) {
    return FutureBuilder<Map<String, dynamic>>(
      future: fetchIncomeData(endpoint),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('ไม่มีข้อมูล'));
        }

        final incomeData = snapshot.data!;
        
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bill for commission completed',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${incomeData['totalIncome']}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'ทำการจ่ายเรียบร้อยแล้ว',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}