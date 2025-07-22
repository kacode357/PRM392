import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user/config/dio_customize.dart';
import 'package:user/models/review_model.dart';
import 'package:user/services/review_services.dart';
import 'package:user/widgets/alert_dialog.dart';

// Màn hình hiển thị bình luận không cần ownerId
class CommentsScreen extends StatefulWidget {
  final String snackPlaceId;
  const CommentsScreen({Key? key, required this.snackPlaceId}) : super(key: key);

  @override
  _CommentsScreenState createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  late Future<List<ReviewWithReplies>> _reviewsFuture;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _reviewsFuture = _fetchDataForBuilder();
  }

  Future<List<ReviewWithReplies>> _fetchDataForBuilder() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _currentUserId = prefs.getString('user_id');
      });
    }

    final ApiResponse response = await ReviewServices.getAllReviewsAndRepliesBySnackPlaceIdApi(
      snackPlaceId: widget.snackPlaceId,
    );

    if (response.data != null) {
      final List<dynamic> responseData = response.data;
      return responseData.map((item) => ReviewWithReplies.fromJson(item)).toList();
    } else {
      throw Exception('Không thể tải bình luận: ${response.message}');
    }
  }

  void _refreshData() {
    setState(() {
      _reviewsFuture = _fetchDataForBuilder();
    });
  }

   Future<void> _handleRecommend(String reviewId) async {
    // <<< LOGIC KIỂM TRA ĐĂNG NHẬP NẰM NGAY ĐÂY
    if (_currentUserId == null) {
      AppAlertDialog.show(context, title: "Lỗi", content: "Bạn cần đăng nhập để thực hiện.", isSuccess: false);
      return; // Dừng hàm ngay lập tức
    }
    // Nếu đã đăng nhập, code sẽ chạy tiếp xuống dưới
    try {
      await ReviewServices.recommendReviewApi(reviewId: reviewId, userId: _currentUserId!);
      _refreshData();
    } catch (e) {
      AppAlertDialog.show(context, title: "Lỗi", content: "Thao tác thất bại: $e", isSuccess: false);
    }
  }

  Future<void> _handleDelete(String reviewId) async {
    final confirm = await AppAlertDialog.show(
      context,
      title: 'Xác nhận',
      content: 'Bạn có chắc chắn muốn xóa đánh giá này?',
      showCancelButton: true,
    );

    if (confirm == true) {
      try {
        await ReviewServices.deleteReviewApi(reviewId: reviewId);
        _refreshData();
      } catch (e) {
        AppAlertDialog.show(context, title: "Lỗi", content: "Xóa thất bại: $e", isSuccess: false);
      }
    }
  }

  void _openReplyDialog({required String reviewId, String? parentReplyId}) {
    if (_currentUserId == null) {
      AppAlertDialog.show(context, title: "Lỗi", content: "Bạn cần đăng nhập để trả lời.", isSuccess: false);
      return;
    }
    
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Viết phản hồi'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: 'Nhập phản hồi của bạn...'),
          autofocus: true,
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Hủy')),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              
              final payloadReviewId = parentReplyId != null ? null : reviewId;
              
              try {
                await ReviewServices.createReplyApi(
                    reviewId: payloadReviewId,
                    parentReplyId: parentReplyId,
                    content: controller.text.trim(),
                    userId: _currentUserId!,
                );
                Navigator.of(context).pop();
                _refreshData();
              } catch (e) {
                AppAlertDialog.show(context, title: "Lỗi", content: "Gửi trả lời thất bại: $e", isSuccess: false);
              }
            },
            child: Text('Gửi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Bình luận')),
      body: RefreshIndicator(
        onRefresh: () async => _refreshData(),
        child: FutureBuilder<List<ReviewWithReplies>>(
          future: _reviewsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Lỗi: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('Chưa có bình luận nào.'));
            }

            final reviews = snapshot.data!;
            return ListView.builder(
              itemCount: reviews.length,
              itemBuilder: (context, index) {
                final review = reviews[index];
                return _ReviewItem(
                  review: review,
                  currentUserId: _currentUserId,
                  onRecommend: () => _handleRecommend(review.reviewId),
                  onDelete: () => _handleDelete(review.reviewId),
                  onReply: _openReplyDialog,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// --- WIDGET CON CHO TỪNG REVIEW ---
class _ReviewItem extends StatelessWidget {
  final ReviewWithReplies review;
  final String? currentUserId;
  final VoidCallback onRecommend;
  final VoidCallback onDelete;
  final Function({required String reviewId, String? parentReplyId}) onReply;

  const _ReviewItem({
    required this.review,
    this.currentUserId,
    required this.onRecommend,
    required this.onDelete,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(review.date);

    return Card(
      margin: EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(child: Icon(Icons.person)),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(review.userName, style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(formattedDate, style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                if (review.userId == currentUserId)
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: onDelete,
                  )
              ],
            ),
            SizedBox(height: 10),
            // Comment
            Text(review.comment),
            // Image
            if (review.image.isNotEmpty && review.image != 'string')
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: review.image,
                    placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) => SizedBox.shrink(),
                  ),
                ),
              ),
            // Actions
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: onRecommend,
                  icon: Icon(
                    review.isRecommend ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                    color: review.isRecommend ? Colors.blue : Colors.grey,
                    size: 20,
                  ),
                  label: Text('${review.recommendCount}'),
                ),
                // LOGIC CŨ: Ai cũng thấy nút trả lời
                TextButton(
                  onPressed: () => onReply(reviewId: review.reviewId),
                  child: Text('Trả lời'),
                )
              ],
            ),
            // Replies Section
            if (review.replies.isNotEmpty)
              _RepliesSection(
                replies: review.replies,
                onReply: onReply,
              )
          ],
        ),
      ),
    );
  }
}

// --- WIDGET CON CHO PHẦN REPLIES LỒNG NHAU ---
class _RepliesSection extends StatelessWidget {
  final List<Reply> replies;
  final Function({required String reviewId, String? parentReplyId}) onReply;
  final int level;

  const _RepliesSection({
    required this.replies,
    required this.onReply,
    this.level = 0
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(left: level > 0 ? 16 : 0, top: 8),
      padding: EdgeInsets.only(left: 10),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: Colors.grey.shade300, width: 2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: replies.map((reply) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Reply Item
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // LOGIC CŨ: Dùng chung icon person cho tất cả
                      CircleAvatar(radius: 12, child: Icon(Icons.person, size: 14)),
                      SizedBox(width: 8),
                      Text(reply.userName, style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 32.0),
                    child: Text(reply.comment),
                  ),
                  SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 32.0),
                    child: Row(
                      children: [
                        Text(DateFormat('dd/MM/yy HH:mm').format(reply.createdAt), style: TextStyle(color: Colors.grey, fontSize: 12)),
                        SizedBox(width: 8),
                        // LOGIC CŨ: Ai cũng có thể trả lời
                        InkWell(
                          onTap: () => onReply(reviewId: reply.reviewId!, parentReplyId: reply.replyId),
                          child: Text('Trả lời', style: TextStyle(color: Colors.blue, fontSize: 12)),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
            // Recursively build replies for this reply
            if (reply.replies.isNotEmpty)
              _RepliesSection(replies: reply.replies, onReply: onReply, level: level + 1),
          ],
        )).toList(),
      ),
    );
  }
}