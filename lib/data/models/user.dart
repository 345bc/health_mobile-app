class User {
  final int? userId;
  final String email;
  final String passwordHash;
  final String name;
  final String? dateOfBirth;
  final String? gender;

  User({
    this.userId,
    required this.email,
    required this.passwordHash,
    required this.name,
    required this.dateOfBirth,
    required this.gender,
  });

  // Chuyển từ Map (database) thành Object Note
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'email': email,
      'password_hash': passwordHash,
      'name': name,
      'date_of_birth': dateOfBirth,
      'gender': gender,
    };
  }

  // Chuyển từ Object Note thành Map (để lưu vào database)
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      userId: map['user_id'],
      email: map['email'],
      passwordHash: map['password_hash'],
      name: map['name'],
      dateOfBirth: map['date_of_birth'],
      gender: map['gender'],
    );
  }
}
