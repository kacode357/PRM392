// lib/models/user.dart

class UserPackage {
  final String packageName;
  UserPackage({required this.packageName});

  factory UserPackage.fromJson(Map<String, dynamic> json) {
    return UserPackage(packageName: json['packageName'] ?? '');
  }
}

class User {
  final List<UserPackage> userPackages;

  User({required this.userPackages});

  factory User.fromJson(Map<String, dynamic> json) {
    var packagesList = json['userPackages'] as List? ?? [];
    List<UserPackage> packages = packagesList.map((i) => UserPackage.fromJson(i)).toList();
    return User(userPackages: packages);
  }
}