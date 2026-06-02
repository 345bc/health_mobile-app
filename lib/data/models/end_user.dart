class EndUser {
  int? id;
  String? name;
  String? dateOfBirth;
  String? gender;
  double? height;
  double? weight;
  String? bloodType;
  String? avatar;

  EndUser({
    this.id,
    this.name,
    this.dateOfBirth,
    this.gender,
    this.height,
    this.weight,
    this.bloodType,
    this.avatar,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'date_of_birth': dateOfBirth,
      'gender': gender,
      'height': height,
      'weight': weight,
      'blood_type': bloodType,
      'avatar': avatar,
    };
  }

  factory EndUser.fromMap(Map<String, dynamic> map) {
    return EndUser(
      id: map['id'] ?? map['user_id'],
      name: map['fullName'] ?? map['name'],
      dateOfBirth: map['birthDate'] ?? map['date_of_birth'] ?? map['dateOfBirth'],
      gender: map['gender'],
      height: (map['height'] is num) ? (map['height'] as num).toDouble() : null,
      weight: (map['weight'] is num) ? (map['weight'] as num).toDouble() : null,
      bloodType: map['bloodType'] ?? map['blood_type'],
      avatar: map['avatar'],
    );
  }

  EndUser copyWith({
    int? id,
    String? name,
    String? dateOfBirth,
    String? gender,
    double? height,
    double? weight,
    String? bloodType,
    String? avatar,
  }) {
    return EndUser(
      id: id ?? this.id,
      name: name ?? this.name,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      bloodType: bloodType ?? this.bloodType,
      avatar: avatar ?? this.avatar,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'fullName': name,
      'birthDate': dateOfBirth,
      'gender': gender,
      'height': height,
      'weight': weight,
      'bloodType': bloodType,
      'avatar': avatar,
    };
  }
}
