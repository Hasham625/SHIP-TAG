class User {
  final String id;
  final String mobileNumber;
  final String email;
  final String name;
  final String? profileImage;

  User({
    required this.id,
    required this.mobileNumber,
    required this.email,
    required this.name,
    this.profileImage,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      mobileNumber: json['mobileNumber'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      profileImage: json['profileImage'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mobileNumber': mobileNumber,
      'email': email,
      'name': name,
      'profileImage': profileImage,
    };
  }

  User copyWith({
    String? id,
    String? mobileNumber,
    String? email,
    String? name,
    String? profileImage,
  }) {
    return User(
      id: id ?? this.id,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      email: email ?? this.email,
      name: name ?? this.name,
      profileImage: profileImage ?? this.profileImage,
    );
  }
}
