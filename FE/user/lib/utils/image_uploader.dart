import 'dart:io';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

// Tiện ích tải ảnh lên Cloudinary
class ImageUploader {
  static const String _cloudinaryUrl = 'https://api.cloudinary.com/v1_1/dgtbovcjg/image/upload';
  static const String _uploadPreset = 'mma-upload';

  // Hàm này sẽ trả về URL của ảnh sau khi tải lên thành công, hoặc null nếu thất bại
  static Future<String?> uploadImage() async {
    try {
      final picker = ImagePicker();
      // Mở thư viện ảnh để người dùng chọn
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image == null) {
        // Người dùng không chọn ảnh
        return null;
      }

      // Chuẩn bị dữ liệu để gửi đi
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(image.path, filename: 'upload.jpg'),
        'upload_preset': _uploadPreset,
      });

      // Dùng Dio để gửi request POST
      final dio = Dio();
      final response = await dio.post(_cloudinaryUrl, data: formData);

      // Lấy URL an toàn từ kết quả trả về của Cloudinary
      if (response.statusCode == 200 && response.data['secure_url'] != null) {
        return response.data['secure_url'];
      } else {
        throw Exception('Tải ảnh lên thất bại, không nhận được URL.');
      }
    } catch (e) {
      print('Lỗi khi tải ảnh lên: $e');
      return null;
    }
  }
}