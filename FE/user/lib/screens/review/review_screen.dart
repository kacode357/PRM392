// lib/screens/review/review_screen.dart

import 'package:flutter/material.dart';
import 'package:user/config/dio_customize.dart';
import 'package:user/services/review_services.dart';
import 'package:user/utils/image_uploader.dart'; // File mày đã cung cấp
import 'package:user/widgets/alert_dialog.dart'; // Giả sử mày có widget này
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Dùng package này cho ảnh
import 'package:flutter_rating_bar/flutter_rating_bar.dart'; // Package cho rating bar tiện lợi

class ReviewScreen extends StatefulWidget {
  final String snackPlaceId;

  const ReviewScreen({Key? key, required this.snackPlaceId}) : super(key: key);

  @override
  _ReviewScreenState createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  double _tasteRating = 0;
  double _priceRating = 0;
  double _sanitaryRating = 0;
  double _textureRating = 0;
  double _convenienceRating = 0;
  String? _imageUrl;
  final _commentController = TextEditingController();

  bool _isUploading = false;
  bool _isSubmitting = false;

  Future<void> _handleImagePick() async {
    setState(() => _isUploading = true);
    final url = await ImageUploader.uploadImage();
    if (url != null) {
      setState(() {
        _imageUrl = url;
      });
    }
    setState(() => _isUploading = false);
  }

  void _handleSubmit() async {
    if (_isSubmitting) return;

    if (_tasteRating == 0 ||
        _priceRating == 0 ||
        _sanitaryRating == 0 ||
        _textureRating == 0 ||
        _convenienceRating == 0 ||
        _commentController.text.trim().isEmpty) {
      AppAlertDialog.show(
        context,
        title: 'Lỗi',
        content: 'Vui lòng chọn số sao cho tất cả hạng mục và nhập nhận xét.',
        isSuccess: false,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id'); // Giả sử mày lưu user_id

      if (userId == null) {
        throw Exception('Không tìm thấy thông tin người dùng. Vui lòng đăng nhập lại.');
      }
      
      final ApiResponse response = await ReviewServices.createReviewApi(
        snackPlaceId: widget.snackPlaceId,
        userId: userId,
        tasteRating: _tasteRating.toInt(),
        priceRating: _priceRating.toInt(),
        sanitaryRating: _sanitaryRating.toInt(),
        textureRating: _textureRating.toInt(),
        convenienceRating: _convenienceRating.toInt(),
        image: _imageUrl ?? '', // Gửi chuỗi rỗng nếu không có ảnh
        comment: _commentController.text.trim(),
      );

      if(response.status == 200) {
         await AppAlertDialog.show(
          context,
          title: 'Thành công',
          content: 'Đánh giá của bạn đã được gửi thành công!',
          isSuccess: true,
        );
        Navigator.of(context).pop(true); // Trả về true để báo hiệu cần refresh
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      AppAlertDialog.show(
        context,
        title: 'Lỗi',
        content: e.toString(),
        isSuccess: false,
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }
  
  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Đánh giá quán')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRatingBar('Hương vị', _tasteRating, (rating) => setState(() => _tasteRating = rating)),
            _buildRatingBar('Giá cả', _priceRating, (rating) => setState(() => _priceRating = rating)),
            _buildRatingBar('Vệ sinh', _sanitaryRating, (rating) => setState(() => _sanitaryRating = rating)),
            _buildRatingBar('Kết cấu', _textureRating, (rating) => setState(() => _textureRating = rating)),
            _buildRatingBar('Tiện lợi', _convenienceRating, (rating) => setState(() => _convenienceRating = rating)),
            
            SizedBox(height: 20),
            Text('Nhận xét:', style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 8),
            TextFormField(
              controller: _commentController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Nhập nhận xét của bạn...',
              ),
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
            ),

            SizedBox(height: 20),
            Text('Hình ảnh (tùy chọn):', style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 8),
            GestureDetector(
              onTap: _isUploading ? null : _handleImagePick,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _isUploading
                    ? Center(child: CircularProgressIndicator())
                    : _imageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: _imageUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                              errorWidget: (context, url, error) => Icon(Icons.error),
                            ),
                          )
                        : Center(child: Icon(Icons.add_a_photo, size: 40, color: Colors.grey)),
              ),
            ),
            SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSubmit,
                child: _isSubmitting
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Gửi đánh giá'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingBar(String label, double currentRating, Function(double) onRatingUpdate) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16)),
          RatingBar.builder(
            initialRating: currentRating,
            minRating: 1,
            direction: Axis.horizontal,
            itemCount: 5,
            itemPadding: EdgeInsets.symmetric(horizontal: 2.0),
            itemBuilder: (context, _) => Icon(Icons.star, color: Colors.amber),
            onRatingUpdate: onRatingUpdate,
            itemSize: 28,
          ),
        ],
      ),
    );
  }
}