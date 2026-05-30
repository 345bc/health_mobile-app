import 'end_user.dart';

class User {
  final int? userId;
  final String email;
  final String passwordHash;
  EndUser? endUser;

  User({
    this.userId,
    required this.email,
    required this.passwordHash,
    required String user_name,
    this.endUser,
  }) {
    endUser ??= EndUser(id: userId, name: user_name);
    if (user_name.isNotEmpty) {
      endUser!.name = user_name;
    }
  }

  String get user_name => endUser?.name ?? '';
  set user_name(String name) {
    endUser ??= EndUser(id: userId);
    endUser!.name = name;
  }

  String? get dateOfBirth => endUser?.dateOfBirth;
  String? get gender => endUser?.gender;
  double? get height => endUser?.height;
  double? get weight => endUser?.weight;
  String? get bloodType => endUser?.bloodType;

  Map<String, dynamic> toMap() {
    return {
      if (userId != null) 'user_id': userId,
      'email': email,
      'password_hash': passwordHash,
      'name': endUser?.name,
      'date_of_birth': endUser?.dateOfBirth,
      'gender': endUser?.gender,
      'height': endUser?.height,
      'weight': endUser?.weight,
      'blood_type': endUser?.bloodType,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      userId: map['user_id'] as int?,
      email: map['email'] as String? ?? '',
      passwordHash: map['password_hash'] as String? ?? '',
      user_name: map['name'] as String? ?? '',
      endUser: EndUser(
        id: map['user_id'] as int?,
        name: map['name'] as String?,
        dateOfBirth: map['date_of_birth'] as String?,
        gender: map['gender'] as String?,
        height: (map['height'] is num)
            ? (map['height'] as num).toDouble()
            : null,
        weight: (map['weight'] is num)
            ? (map['weight'] as num).toDouble()
            : null,
        bloodType: map['blood_type'] as String?,
      ),
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    final nameVal = (json['name'] ?? json['user_name']) as String? ?? '';
    return User(
      userId: (json['id'] ?? json['userId']) as int?,
      email: json['email'] as String? ?? '',
      passwordHash:
          (json['passwordHash'] ?? json['password_hash']) as String? ?? '',
      user_name: nameVal,
      endUser: EndUser(
        id: (json['id'] ?? json['userId']) as int?,
        name: nameVal,
        dateOfBirth: (json['dateOfBirth'] ?? json['date_of_birth']) as String?,
        gender: json['gender'] as String?,
        height: (json['height'] is num)
            ? (json['height'] as num).toDouble()
            : null,
        weight: (json['weight'] is num)
            ? (json['weight'] as num).toDouble()
            : null,
        bloodType: (json['bloodType'] ?? json['blood_type']) as String?,
      ),
    );
  }

  // Chuyển Object → JSON (gửi lên server)
  Map<String, dynamic> toJson() {
    return {
      'id': userId,
      'name': endUser?.name,
      'email': email,
      'passwordHash': passwordHash,
      'dateOfBirth': endUser?.dateOfBirth,
      'gender': endUser?.gender,
      'height': endUser?.height,
      'weight': endUser?.weight,
      'bloodType': endUser?.bloodType,
    };
  }

  User copyWith({
    int? userId,
    String? email,
    String? passwordHash,
    String? user_name,
    String? dateOfBirth,
    String? gender,
    double? height,
    double? weight,
    String? bloodType,
    EndUser? endUser,
  }) {
    return User(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      user_name: user_name ?? this.user_name,
      endUser:
          endUser ??
          (this.endUser != null
              ? this.endUser!.copyWith(
                  id: userId ?? this.userId,
                  name: user_name ?? this.endUser?.name,
                  dateOfBirth: dateOfBirth ?? this.endUser?.dateOfBirth,
                  gender: gender ?? this.endUser?.gender,
                  height: height ?? this.endUser?.height,
                  weight: weight ?? this.endUser?.weight,
                  bloodType: bloodType ?? this.endUser?.bloodType,
                )
              : EndUser(
                  id: userId ?? this.userId,
                  name: user_name,
                  dateOfBirth: dateOfBirth,
                  gender: gender,
                  height: height,
                  weight: weight,
                  bloodType: bloodType,
                )),
    );
  }
}
