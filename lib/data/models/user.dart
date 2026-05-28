class User {
  final int? userId;
  final String email;
  final String passwordHash;
  final String name;
  final String? dateOfBirth;
  final String? gender;
  final double? height;
  final double? weight;
  final String? bloodType;

  User({
    this.userId,
    required this.email,
    required this.passwordHash,
    required this.name,
    this.dateOfBirth,
    this.gender,
    this.height,
    this.weight,
    this.bloodType,
  });

  Map<String, dynamic> toMap() {
    return {
      if (userId != null) 'user_id': userId,
      'email': email,
      'password_hash': passwordHash,
      'name': name,
      'date_of_birth': dateOfBirth,
      'gender': gender,
      'height': height,
      'weight': weight,
      'blood_type': bloodType,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      userId: map['user_id'],
      email: map['email'],
      passwordHash: map['password_hash'],
      name: map['name'],
      dateOfBirth: map['date_of_birth'],
      gender: map['gender'],
      height: map['height'] != null ? (map['height'] as num).toDouble() : null,
      weight: map['weight'] != null ? (map['weight'] as num).toDouble() : null,
      bloodType: map['blood_type'],
    );
  }

  User copyWith({
    int? userId,
    String? email,
    String? passwordHash,
    String? name,
    String? dateOfBirth,
    String? gender,
    double? height,
    double? weight,
    String? bloodType,
  }) {
    return User(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      name: name ?? this.name,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      bloodType: bloodType ?? this.bloodType,
    );
  }
}
