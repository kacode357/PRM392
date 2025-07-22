import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:saver_gallery/saver_gallery.dart';

class AiResultImageScreen extends StatefulWidget {
  final List<String> imageUrls;
  final String prompt;

  const AiResultImageScreen({
    super.key,
    required this.imageUrls,
    required this.prompt,
  });

  @override
  State<AiResultImageScreen> createState() => _AiResultImageScreenState();
}

class _AiResultImageScreenState extends State<AiResultImageScreen> {
  // Map để theo dõi trạng thái tải của từng ảnh, giúp các nút hoạt động độc lập
  final Map<String, bool> _downloadingStatus = {};

  /// Tải ảnh về từ URL và lưu vào thư viện của máy
  Future<void> _downloadImage(String url) async {
    // Cập nhật UI để hiển thị trạng thái đang tải cho ĐÚNG cái nút được bấm
    setState(() {
      _downloadingStatus[url] = true;
    });

    // 1. Xin quyền truy cập bộ nhớ
    // Đối với Android 13+ và iOS, cần xin quyền truy cập thư viện ảnh
    final status = await Permission.photos.request();
    if (!status.isGranted) {
      _showResultDialog('Lỗi', 'Cần cấp quyền truy cập thư viện ảnh để lưu ảnh.');
      setState(() { _downloadingStatus[url] = false; });
      return;
    }

    try {
      // 2. Tải ảnh về bằng Dio vào một thư mục tạm
      final dio = Dio();
      final tempDir = await getTemporaryDirectory();
      final fileName = 'ai_logo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savePath = '${tempDir.path}/$fileName';
      await dio.download(url, savePath);

      // 3. Dùng saver_gallery để lưu file từ đường dẫn tạm vào thư viện
      // Đây là code đã sửa lại với đúng tên tham số
      final result = await SaverGallery.saveFile(
        filePath: savePath,
        fileName: fileName,
        androidRelativePath: "Pictures/MerchantApp", // Tạo album riêng cho đẹp
        skipIfExists: false,
      );

      if (result.isSuccess) {
        _showResultDialog('Thành công', 'Ảnh đã được lưu vào thư viện của bạn!', isSuccess: true);
      } else {
        throw Exception(result.errorMessage ?? 'Không thể lưu ảnh vào thư viện.');
      }
    } catch (e) {
      _showResultDialog('Lỗi', 'Tải ảnh thất bại: $e');
    } finally {
      // Dù thành công hay thất bại, cũng phải tắt trạng thái loading cho nút đó
      if (mounted) {
        setState(() {
          _downloadingStatus[url] = false;
        });
      }
    }
  }

  /// Hiển thị dialog thông báo kết quả (thành công hoặc thất bại)
  void _showResultDialog(String title, String message, {bool isSuccess = false}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(isSuccess ? Icons.check_circle : Icons.error, color: isSuccess ? Colors.green : Colors.red),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [TextButton(child: const Text('OK'), onPressed: () => Navigator.of(ctx).pop())],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kết Quả Logo AI')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hiển thị lại câu lệnh đã dùng
            if (widget.prompt.isNotEmpty)
              Card(
                margin: const EdgeInsets.only(bottom: 20),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Câu lệnh đã dùng:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(widget.prompt),
                    ],
                  ),
                ),
              ),
            
            // Hiển thị danh sách các ảnh kết quả
            ...widget.imageUrls.map((url) => _buildImageCard(url)).toList(),

            const SizedBox(height: 20),
            ElevatedButton(
              child: const Text('Tạo Logo Khác'),
              onPressed: () => Navigator.of(context).pop(),
            )
          ],
        ),
      ),
    );
  }

  /// Widget để build một thẻ ảnh + nút tải về
  Widget _buildImageCard(String url) {
    final isDownloading = _downloadingStatus[url] ?? false;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 20),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Widget hiển thị ảnh từ URL, có loading và error placeholder
          Image.network(
            url,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) => 
              progress == null 
                ? child 
                : const Padding(
                    padding: EdgeInsets.all(32.0), 
                    child: CircularProgressIndicator(),
                  ),
            errorBuilder: (context, error, stack) => 
              const Padding(
                padding: EdgeInsets.all(32.0), 
                child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
              ),
          ),
          // Nút Tải về
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isDownloading ? null : () => _downloadImage(url),
                icon: isDownloading 
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) 
                  : const Icon(Icons.download),
                label: Text(isDownloading ? 'Đang tải...' : 'Tải về'),
              ),
            ),
          )
        ],
      ),
    );
  }
}