class User {
  final int? userId;
  final String email;
  final String passwordHash;
  String user_name;

  User({
    this.userId,
    required this.email,
    required this.passwordHash,
    required this.user_name,
  });

  Map<String, dynamic> toMap() {
    return {
      if (userId != null) 'user_id': userId,
      'email': email,
      'password_hash': passwordHash,
      'name': user_name,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      userId: map['user_id'] as int?,
      email: map['email'] as String? ?? '',
      passwordHash: map['password_hash'] as String? ?? '',
      user_name: map['name'] as String? ?? '',
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: (json['id'] ?? json['userId']) as int?,
      user_name: (json['name'] ?? json['user_name']) as String? ?? '',
      email: json['email'] as String? ?? '',
      passwordHash: (json['passwordHash'] ?? json['password_hash']) as String? ?? '',
    );
  }

  // Chuyển Object → JSON (gửi lên server)
  Map<String, dynamic> toJson() {
    return {
      'id': userId,
      'name': user_name,
      'email': email,
      'passwordHash': passwordHash,
    };
  }

  // User copyWith({
  //   int? userId,
  //   String? email,
  //   String? passwordHash,
  //   String? name,
  //   String? dateOfBirth,
  //   String? gender,
  //   double? height,
  //   double? weight,
  //   String? bloodType,
  // }) {
  //   return User(
  //     userId: userId ?? this.userId,
  //     email: email ?? this.email,
  //     passwordHash: passwordHash ?? this.passwordHash,
  //     name: name ?? this.name,
  //     dateOfBirth: dateOfBirth ?? this.dateOfBirth,
  //     gender: gender ?? this.gender,
  //     height: height ?? this.height,
  //     weight: weight ?? this.weight,
  //     bloodType: bloodType ?? this.bloodType,
  //   );
  // }
}
