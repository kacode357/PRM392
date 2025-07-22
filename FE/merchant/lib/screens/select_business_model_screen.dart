// lib/screens/select_business_model_screen.dart
import 'package:flutter/material.dart';
import 'package:merchant/models/business_model.dart';
// SỬA Ở ĐÂY: Import service thật
import 'package:merchant/services/business_model_services.dart'; 

class SelectBusinessModelScreen extends StatefulWidget {
  const SelectBusinessModelScreen({super.key});

  @override
  State<SelectBusinessModelScreen> createState() => _SelectBusinessModelScreenState();
}

class _SelectBusinessModelScreenState extends State<SelectBusinessModelScreen> {
  late Future<List<BusinessModel>> _futureBusinessModels;

  @override
  void initState() {
    super.initState();
    _futureBusinessModels = _fetchBusinessModels();
  }

  // SỬA Ở ĐÂY: Dùng hàm gọi API thật
  Future<List<BusinessModel>> _fetchBusinessModels() async {
    final response = await BusinessModelServices.searchBusinessModelsApi(
      pageNum: 1, 
      pageSize: 100, // Lấy nhiều để đủ dùng
      searchKeyword: '', 
      status: true
    );

    if (response.status == 200 && response.data != null) {
      // API của mày trả data trong trường 'pageData'
      final List<dynamic> rawData = response.data['pageData']; 
      return rawData.map((json) => BusinessModel.fromJson(json)).toList();
    } else {
      // Ném lỗi để FutureBuilder có thể bắt và hiển thị
      throw Exception('Không thể tải danh sách mô hình kinh doanh');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chọn Mô Hình Kinh Doanh')),
      body: FutureBuilder<List<BusinessModel>>(
        future: _futureBusinessModels,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Không có dữ liệu'));
          }

          final models = snapshot.data!;
          return ListView.builder(
            itemCount: models.length,
            itemBuilder: (context, index) {
              final model = models[index];
              return ListTile(
                title: Text(model.name),
                onTap: () {
                  Navigator.pop(context, model);
                },
              );
            },
          );
        },
      ),
    );
  }
}