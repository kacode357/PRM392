// lib/screens/ai_create_image_screen.dart
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:merchant/screens/ai_result_image_screen.dart';

const String apiKey = "yNVUdjuAPVFR5mlU5T5UQg=="; // API Key của mày

class AiCreateImageScreen extends StatefulWidget {
  const AiCreateImageScreen({super.key});

  @override
  State<AiCreateImageScreen> createState() => _AiCreateImageScreenState();
}

class _AiCreateImageScreenState extends State<AiCreateImageScreen> {
  final _commandController = TextEditingController();
  final List<String> _selectedStyles = [];
  final List<String> _selectedShapes = [];
  final List<String> _selectedColors = []; // Dùng mã hex string
  bool _isLoading = false;

  // Dữ liệu tùy chọn
  final List<String> _stylesOptions = ["Tối giản", "Hiện đại", "Cổ điển", "Công nghệ", "Màu nước", "Chữ tượng hình", "Dễ thương", "Trừu tượng"];
  final List<String> _shapesOptions = ["Tròn", "Vuông", "Tam giác", "Ngôi sao", "Trái tim", "Lục giác", "Kim cương", "Dòng chảy"];
  final List<String> _colorGrid = ["#FF0000", "#FF4500", "#FFA500", "#FFFF00", "#ADFF2F", "#00FF00", "#00FA9A", "#00FFFF", "#1E90FF", "#0000FF", "#800080", "#FF69B4", "#FFC0CB", "#FFFFFF", "#D3D3D3", "#808080", "#000000", "#A52A2A", "#F4A460", "#FFD700"];

  @override
  void dispose() {
    _commandController.dispose();
    super.dispose();
  }

  void _toggleSelection(List<String> list, String item, int maxSelection) {
    setState(() {
      if (list.contains(item)) {
        list.remove(item);
      } else {
        if (list.length < maxSelection) {
          list.add(item);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Chỉ được chọn tối đa $maxSelection mục.')));
        }
      }
    });
  }

  String _getColorName(String hex) {
    const colorMap = {'#ff0000': 'đỏ', '#ffa500': 'cam', '#ffff00': 'vàng', '#00ff00': 'xanh lá', '#0000ff': 'xanh dương', '#800080': 'tím', '#ffffff': 'trắng', '#000000': 'đen'};
    return colorMap[hex.toLowerCase()] ?? hex;
  }

  Future<void> _handleCreateLogo() async {
    if (_commandController.text.trim().isEmpty) {
      _showErrorDialog("Vui lòng nhập câu lệnh để tạo logo.");
      return;
    }
    setState(() { _isLoading = true; });

    String fullPrompt = _commandController.text.trim();
    if (_selectedStyles.isNotEmpty) fullPrompt += ', phong cách: ${_selectedStyles.join(", ")}';
    if (_selectedShapes.isNotEmpty) fullPrompt += ', hình dạng: ${_selectedShapes.join(", ")}';
    if (_selectedColors.isNotEmpty) fullPrompt += ', màu sắc: ${_selectedColors.map(_getColorName).join(", ")}';

    try {
      final response = await http.post(
        Uri.parse("https://api.thehive.ai/api/v3/stabilityai/sdxl"),
        headers: {'authorization': 'Bearer $apiKey', 'Content-Type': 'application/json'},
        body: json.encode({'input': {'prompt': fullPrompt, 'negative_prompt': "blurry, distorted, ugly, low quality, bad resolution, watermarks", 'image_size': {'width': 1024, 'height': 1024}, 'num_inference_steps': 15, 'guidance_scale': 7.5, 'num_images': 1, 'seed': Random().nextInt(100000), 'output_format': 'jpeg', 'output_quality': 90}}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['output'] != null && (data['output'] as List).isNotEmpty) {
        final List<String> imageUrls = (data['output'] as List).map((img) => img['url'] as String).toList();
        if (mounted) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => AiResultImageScreen(imageUrls: imageUrls, prompt: fullPrompt)));
        }
      } else {
        throw Exception(data['error']?['message'] ?? 'Không thể tạo logo. Vui lòng thử lại.');
      }
    } catch (e) {
      if (mounted) _showErrorDialog('Lỗi: $e');
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('Lỗi'), content: Text(message), actions: [TextButton(child: const Text('OK'), onPressed: () => Navigator.of(ctx).pop())]));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tạo Logo Bằng AI')),
      // THAY ĐỔI: Bọc toàn bộ body bằng SafeArea
      body: SafeArea(
        child: IgnorePointer(
          ignoring: _isLoading,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Nhập câu lệnh'),
                TextFormField(controller: _commandController, decoration: const InputDecoration(hintText: 'Ví dụ: logo quán ăn vặt...', border: OutlineInputBorder()), maxLines: 4),
                const SizedBox(height: 24),

                _buildSectionTitle('Phong cách (tối đa 2)'),
                _buildOptionsWrap(_stylesOptions, _selectedStyles, 2),
                const SizedBox(height: 24),

                _buildSectionTitle('Hình dạng (tối đa 2)'),
                _buildOptionsWrap(_shapesOptions, _selectedShapes, 2),
                const SizedBox(height: 24),

                _buildSectionTitle('Màu sắc (tối đa 3)'),
                _buildColorGrid(),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white),
                    onPressed: _isLoading ? null : _handleCreateLogo,
                    child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Ok, chốt!', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Padding(padding: const EdgeInsets.only(bottom: 8.0), child: Text(title, style: Theme.of(context).textTheme.titleLarge));

  Widget _buildOptionsWrap(List<String> options, List<String> selectedList, int max) => Wrap(
    spacing: 8.0,
    runSpacing: 4.0,
    children: options.map((option) => FilterChip(
      label: Text(option),
      selected: selectedList.contains(option),
      onSelected: (selected) => _toggleSelection(selectedList, option, max),
    )).toList(),
  );

  Widget _buildColorGrid() => Wrap(
    spacing: 10.0,
    runSpacing: 10.0,
    children: _colorGrid.map((hexColor) {
      final color = Color(int.parse(hexColor.substring(1), radix: 16) + 0xFF000000);
      final isSelected = _selectedColors.contains(hexColor);
      return GestureDetector(
        onTap: () => _toggleSelection(_selectedColors, hexColor, 3),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20), // Tròn
            border: isSelected ? Border.all(color: Theme.of(context).primaryColorDark, width: 3) : Border.all(color: Colors.grey.shade400),
          ),
          child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
        ),
      );
    }).toList(),
  );
}