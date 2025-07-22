// lib/models/rating_summary_model.dart

class RatingSummary {
  final double averageRating;
  final int totalRatingsCount;
  final double recommendPercent;
  final Map<String, double> ratingDistributionPercent;

  RatingSummary({
    required this.averageRating,
    required this.totalRatingsCount,
    required this.recommendPercent,
    required this.ratingDistributionPercent,
  });

  factory RatingSummary.fromJson(Map<String, dynamic> json) {
    // Chuyển đổi Map<String, dynamic> thành Map<String, double>
    final Map<String, double> distribution = (json['ratingDistributionPercent'] as Map<String, dynamic>).map(
      (key, value) => MapEntry(key, (value as num).toDouble()),
    );

    return RatingSummary(
      averageRating: (json['averageRating'] as num).toDouble(),
      totalRatingsCount: json['totalRatingsCount'] as int,
      recommendPercent: (json['recommendPercent'] as num).toDouble(),
      ratingDistributionPercent: distribution,
    );
  }
}