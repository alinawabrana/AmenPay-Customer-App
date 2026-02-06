class UserModel {
  final int id;
  final String fullname;
  final String email;
  final String phone;
  final String role;
  final String? image;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.fullname,
    required this.email,
    required this.phone,
    required this.role,
    required this.image,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      fullname: json['fullname'],
      email: json['email'],
      phone: json['phone'],
      role: json['role'],
      image: json['image'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
