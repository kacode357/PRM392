// lib/models/review_model.dart

class Reply {
  final String replyId;
  final String? reviewId; // <<< SỬA Ở ĐÂY: Thêm dấu ? để cho phép null
  final String? parentReplyId; // parentReplyId cũng có thể null
  final String userId;
  final String userName;
  final String? image;
  final String comment;
  final DateTime createdAt;
  final List<Reply> replies;

  Reply({
    required this.replyId,
    this.reviewId, // <<< SỬA Ở ĐÂY: Bỏ required
    this.parentReplyId,
    required this.userId,
    required this.userName,
    this.image,
    required this.comment,
    required this.createdAt,
    required this.replies,
  });

  factory Reply.fromJson(Map<String, dynamic> json) {
    var repliesFromJson = json['replies'] as List? ?? [];
    List<Reply> replyList = repliesFromJson.map((i) => Reply.fromJson(i)).toList();

    return Reply(
      replyId: json['replyId'],
      reviewId: json['reviewId'], // <<< SỬA Ở ĐÂY: Giờ nó có thể null
      parentReplyId: json['parentReplyId'],
      userId: json['userId'],
      userName: json['userName'],
      image: json['image'],
      comment: json['comment'],
      createdAt: DateTime.parse(json['createdAt']),
      replies: replyList,
    );
  }
}

// Class ReviewWithReplies giữ nguyên không cần sửa
class ReviewWithReplies {
  // ... code của mày
  final String reviewId;
  final String snackPlaceId;
  final String userId;
  final String userName;
  final int taste;
  final int price;
  final int sanitary;
  final int texture;
  final int convenience;
  final String image;
  final String comment;
  final DateTime date;
  final int recommendCount;
  final bool isRecommend;
  final bool status;
  final List<Reply> replies;

  ReviewWithReplies({
    required this.reviewId,
    required this.snackPlaceId,
    required this.userId,
    required this.userName,
    required this.taste,
    required this.price,
    required this.sanitary,
    required this.texture,
    required this.convenience,
    required this.image,
    required this.comment,
    required this.date,
    required this.recommendCount,
    required this.isRecommend,
    required this.status,
    required this.replies,
  });

   factory ReviewWithReplies.fromJson(Map<String, dynamic> json) {
    var repliesFromJson = json['replies'] as List? ?? [];
    List<Reply> replyList = repliesFromJson.map((i) => Reply.fromJson(i)).toList();

    return ReviewWithReplies(
      reviewId: json['reviewId'],
      snackPlaceId: json['snackPlaceId'],
      userId: json['userId'],
      userName: json['userName'],
      taste: json['taste'],
      price: json['price'],
      sanitary: json['sanitary'],
      texture: json['texture'],
      convenience: json['convenience'],
      image: json['image'],
      comment: json['comment'],
      date: DateTime.parse(json['date']),
      recommendCount: json['recommendCount'],
      isRecommend: json['isRecommend'],
      status: json['status'],
      replies: replyList,
    );
  }

  ReviewWithReplies copyWith({
    int? recommendCount,
    bool? isRecommend,
  }) {
    return ReviewWithReplies(
      reviewId: this.reviewId,
      snackPlaceId: this.snackPlaceId,
      userId: this.userId,
      userName: this.userName,
      taste: this.taste,
      price: this.price,
      sanitary: this.sanitary,
      texture: this.texture,
      convenience: this.convenience,
      image: this.image,
      comment: this.comment,
      date: this.date,
      recommendCount: recommendCount ?? this.recommendCount,
      isRecommend: isRecommend ?? this.isRecommend,
      status: this.status,
      replies: this.replies,
    );
  }
}