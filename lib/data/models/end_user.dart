class EndUser {
  int? id;

  EndUser({required this.id});

  Map<String, dynamic> toMap() {
    return {if (id != null) 'id': id};
  }

  factory EndUser.fromMap(Map<String, dynamic> map) {
    return EndUser(id: map['id']);
  }
}
