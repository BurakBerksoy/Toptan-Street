// User model sınıfı - Backend'deki User entity ile uyumlu
class User {
  final int? id;
  final String firstName;
  final String lastName;
  final String email;
  final String role; // WHOLESALER veya RETAILER
  final bool? paymentStatus;
  final String? createdAt;
  final String? updatedAt;

  User({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    this.paymentStatus,
    this.createdAt,
    this.updatedAt,
  });

  // JSON'dan User nesnesine dönüştürme
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      email: json['email'],
      role: json['role'],
      paymentStatus: json['paymentStatus'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  // User nesnesini JSON'a dönüştürme
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'role': role,
      'paymentStatus': paymentStatus,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

// Kullanıcı rolleri enum'u
enum UserRole {
  WHOLESALER, // Toptancı
  RETAILER, // Perakendeci
}

// Enum değerlerini string'e dönüştürme yardımcısı extension
extension UserRoleExtension on UserRole {
  String get name {
    switch (this) {
      case UserRole.WHOLESALER:
        return 'WHOLESALER';
      case UserRole.RETAILER:
        return 'RETAILER';
      default:
        return 'RETAILER';
    }
  }
  
  String get displayName {
    switch (this) {
      case UserRole.WHOLESALER:
        return 'Toptancı';
      case UserRole.RETAILER:
        return 'Perakendeci';
      default:
        return 'Perakendeci';
    }
  }
}
