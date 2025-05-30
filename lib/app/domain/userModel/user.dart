class User {
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? address;
  final String? icNumber;
  final String? gender;
  final String? profileImageUrl;

  User({
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.address,
    this.icNumber,
    this.gender,
    this.profileImageUrl,
  });

  factory User.fromMap(Map<String, dynamic> data) {
    return User(
      name: data['name'],
      email: data['email'],
      role: data['role'],
      phone: data['phone'],
      address: data['address'],
      icNumber: data['icNumber'],
      gender: data['gender'],
      profileImageUrl: data['profileImageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'phone': phone,
      'address': address,
      'icNumber': icNumber,
      'gender': gender,
      'profileImageUrl': profileImageUrl,
    };
  }
}