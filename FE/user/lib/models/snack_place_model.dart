import 'package:user/models/premium_package_model.dart';

class SnackPlace {
  final String snackPlaceId;
  final String placeName;
  final String address;
  final String mainDish;
  final num averagePrice;
  final String openingHour;
  final String businessModelName;
  final String image;
  final String? description;
  final String? phoneNumber;
  final PremiumPackage? premiumPackage;

  SnackPlace({
    required this.snackPlaceId,
    required this.placeName,
    required this.address,
    required this.mainDish,
    required this.averagePrice,
    required this.openingHour,
    required this.businessModelName,
    required this.image,
    this.description,
    this.phoneNumber,
    this.premiumPackage,
  });

  factory SnackPlace.fromJson(Map<String, dynamic> json) {
    return SnackPlace(
      snackPlaceId: json['snackPlaceId'] ?? '',
      placeName: json['placeName'] ?? 'N/A',
      address: json['address'] ?? 'N/A',
      mainDish: json['mainDish'] ?? 'N/A',
      averagePrice: json['averagePrice'] ?? 0,
      openingHour: json['openingHour'] ?? '',
      businessModelName: json['businessModelName'] ?? 'N/A',
      image: json['image'] ?? '',
      description: json['description'],
      phoneNumber: json['phoneNumber'],
      premiumPackage: json['premiumPackage'] != null
          ? PremiumPackage.fromJson(json['premiumPackage'])
          : null,
    );
  }
}