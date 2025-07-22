// lib/screens/comment_reply_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// === CÁC IMPORT CỦA DỰ ÁN MÀY ===
import '../services/review_services.dart';
import '../config/dio_customize.dart';
import '../constants/app_colors.dart';
import '../constants/app_fonts.dart';

// === DATA MODELS (Tương ứng với interface TypeScript) ===

class Reply {
  final String replyId;
  final String? reviewId;
  final String? parentReplyId;
  final String userId;
  final String userName;
  final String? image;
  final String comment;
  final String createdAt;
  final List<Reply> replies;

  Reply({
    required this.replyId,
    this.reviewId,
    this.parentReplyId,
    required this.userId,
    required this.userName,
    this.image,
    required this.comment,
    required this.createdAt,
    required this.replies,
  });

  factory Reply.fromJson(Map<String, dynamic> json) {
    var repliesList = (json['replies'] as List<dynamic>?)
        ?.map((r) => Reply.fromJson(r as Map<String, dynamic>))
        .toList() ??
        [];
    return Reply(
      replyId: json['replyId'],
      reviewId: json['reviewId'],
      parentReplyId: json['parentReplyId'],
      userId: json['userId'],
      userName: json['userName'],
      image: json['image'],
      comment: json['comment'],
      createdAt: json['createdAt'],
      replies: repliesList,
    );
  }
}

class ReviewWithReplies {
  final String reviewId;
  final String userId;
  final String userName;
  final int taste;
  final int price;
  final int sanitary;
  final int texture;
  final int convenience;
  final String? image;
  final String comment;
  final String date;
  final int recommendCount;
  final List<Reply> replies;

  ReviewWithReplies({
    required this.reviewId,
    required this.userId,
    required this.userName,
    required this.taste,
    required this.price,
    required this.sanitary,
    required this.texture,
    required this.convenience,
    this.image,
    required this.comment,
    required this.date,
    required this.recommendCount,
    required this.replies,
  });

  factory ReviewWithReplies.fromJson(Map<String, dynamic> json) {
    var repliesList = (json['replies'] as List<dynamic>?)
        ?.map((r) => Reply.fromJson(r as Map<String, dynamic>))
        .toList() ??
        [];
    return ReviewWithReplies(
      reviewId: json['reviewId'],
      userId: json['userId'],
      userName: json['userName'],
      taste: json['taste'] as int,
      price: json['price'] as int,
      sanitary: json['sanitary'] as int,
      texture: json['texture'] as int,
      convenience: json['convenience'] as int,
      image: json['image'],
      comment: json['comment'] ?? 'Không có bình luận',
      date: json['date'],
      recommendCount: json['recommendCount'] as int,
      replies: repliesList,
    );
  }
}

// === WIDGET TRẠNG THÁI CHÍNH ===

class CommentReplyScreen extends StatefulWidget {
  const CommentReplyScreen({super.key});

  @override
  State<CommentReplyScreen> createState() => _CommentReplyScreenState();
}

class _CommentReplyScreenState extends State<CommentReplyScreen> {
  bool _loading = true;
  String? _error;
  List<ReviewWithReplies> _reviews = [];
  String? _currentUserId;

  final TextEditingController _replyController = TextEditingController();
  // Biến này để lưu thông tin về bình luận đang được trả lời
  ({String reviewId, String? parentReplyId})? _replyingTo;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  // === CÁC HÀM XỬ LÝ LOGIC ===

  Future<void> _loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserId = prefs.getString('user_id');
    });
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await ReviewServices.getAllReviewsAndRepliesApi();
      if (response.status == 200 && response.data is List) {
        final dataList = response.data as List;
        setState(() {
          _reviews =
              dataList.map((item) => ReviewWithReplies.fromJson(item)).toList();
        });
      } else {
        throw Exception('Không thể tải danh sách bình luận.');
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _openReplyDialog({required String reviewId, String? parentReplyId}) {
    _replyingTo = (reviewId: reviewId, parentReplyId: parentReplyId);
    showDialog(
      context: context,
      builder: (context) {
        bool isSubmitting = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Viết phản hồi', style: AppFonts.baloo2Bold),
              content: TextField(
                controller: _replyController,
                autofocus: true,
                maxLines: null,
                decoration:
                const InputDecoration(hintText: 'Nhập phản hồi của bạn...'),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                    setDialogState(() => isSubmitting = true);
                    await _handleSendReply();
                    setDialogState(() => isSubmitting = false);
                  },
                  child: isSubmitting
                      ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Gửi'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      // Dọn dẹp sau khi dialog đóng
      _replyController.clear();
      _replyingTo = null;
    });
  }

  // === HÀM ĐÃ SỬA HOÀN CHỈNH ĐỂ GỬI PAYLOAD ĐÚNG ===
  Future<void> _handleSendReply() async {
    final content = _replyController.text.trim();
    if (content.isEmpty || _replyingTo == null || _currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nội dung không được để trống!')),
      );
      return;
    }

    try {
      final String reviewId = _replyingTo!.reviewId;
      final String? parentReplyId = _replyingTo!.parentReplyId;

      // Gửi đi request đã sửa logic
      final response = await ReviewServices.createReplyApi(
        // Nếu có parentReplyId (trả lời reply), thì reviewId gửi đi là null.
        // Nếu không (trả lời review), thì mới gửi reviewId.
        reviewId: parentReplyId != null ? null : reviewId,
        parentReplyId: parentReplyId,
        content: content,
        userId: _currentUserId!,
      );

      if (response.status == 200) {
        Navigator.of(context).pop(); // Đóng dialog
        await _fetchData(); // Tải lại dữ liệu
      } else {
        // Cố gắng lấy message lỗi từ server để hiển thị
        String serverMessage = response.message ?? 'Gửi phản hồi thất bại.';
        if (response.data is Map && response.data['message'] != null) {
          serverMessage = response.data['message'];
        }
        throw Exception(serverMessage);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  // === CÁC WIDGET CON ĐỂ BUILD GIAO DIỆN ===

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quản lý bình luận',
            style: AppFonts.baloo2Bold
                .copyWith(color: AppColors.lightPrimaryText, fontSize: 24)),
        centerTitle: true,
        backgroundColor: AppColors.lightBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: AppColors.lightBackground,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.lightPrimaryText));
    }
    if (_error != null) {
      return Center(
          child: Text(_error!,
              style: AppFonts.comfortaaRegular
                  .copyWith(color: AppColors.lightError)));
    }
    if (_reviews.isEmpty) {
      return Center(
          child: Text("Chưa có bình luận nào.", style: AppFonts.comfortaaRegular));
    }

    return RefreshIndicator(
      onRefresh: _fetchData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _reviews.length,
        itemBuilder: (context, index) => _buildReviewItem(_reviews[index]),
      ),
    );
  }

  Widget _buildReviewItem(ReviewWithReplies item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserInfo(item.userName, item.comment, item.date),
            const SizedBox(height: 10),
            if (item.image != null &&
                item.image!.isNotEmpty &&
                item.image != 'string')
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(item.image!,
                    fit: BoxFit.cover, width: double.infinity, height: 150),
              ),
            const SizedBox(height: 10),
            _buildRatings(item),
            const Divider(height: 20),
            // Truyền reviewId gốc xuống các hàm con
            ...item.replies
                .map((reply) => _buildReplyItem(reply, reviewId: item.reviewId))
                .toList(),
            const SizedBox(height: 10),
            // Ẩn nút trả lời nếu là bình luận của chính mình
            if (item.userId != _currentUserId)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.reply, size: 18),
                  label: const Text('Trả lời'),
                  onPressed: () => _openReplyDialog(reviewId: item.reviewId),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Sửa hàm để nhận và truyền reviewId, sửa lỗi null check
  Widget _buildReplyItem(Reply reply, {required String reviewId, int level = 0}) {
    return Padding(
      padding: EdgeInsets.only(left: 20.0 * level, top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUserInfo(reply.userName, reply.comment, reply.createdAt,
              isReply: true),
          // Ẩn nút trả lời nếu là phản hồi của chính mình
          if (reply.userId != _currentUserId)
            Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: () => _openReplyDialog(
                  // Dùng reviewId được truyền xuống, không dùng reply.reviewId
                    reviewId: reviewId,
                    parentReplyId: reply.replyId),
                child: Text(
                  'Trả lời',
                  style: AppFonts.comfortaaMedium.copyWith(
                      color: AppColors.lightPrimaryText, fontSize: 13),
                ),
              ),
            ),
          // Truyền tiếp reviewId cho các cấp trả lời sâu hơn
          ...reply.replies
              .map((childReply) =>
              _buildReplyItem(childReply, reviewId: reviewId, level: level + 1))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildUserInfo(String name, String comment, String date,
      {bool isReply = false}) {
    final formattedDate =
    DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(date));
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.account_circle, size: 40, color: AppColors.lightIcon),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: AppFonts.comfortaaBold.copyWith(fontSize: 16)),
              Text(comment, style: AppFonts.comfortaaRegular),
              const SizedBox(height: 4),
              Text(formattedDate,
                  style: AppFonts.comfortaaRegular
                      .copyWith(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRatings(ReviewWithReplies item) {
    return Column(
      children: [
        _buildRatingRow('Hương vị', item.taste),
        _buildRatingRow('Giá cả', item.price),
        _buildRatingRow('Vệ sinh', item.sanitary),
        _buildRatingRow('Kết cấu', item.texture),
        _buildRatingRow('Tiện lợi', item.convenience),
      ],
    );
  }

  Widget _buildRatingRow(String label, int rating) {
    return Row(
      children: [
        SizedBox(width: 80, child: Text(label, style: AppFonts.comfortaaRegular)),
        Row(
          children: List.generate(
              5,
                  (index) => Icon(
                index < rating ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 20,
              )),
        ),
      ],
    );
  }
}