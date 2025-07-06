// models/user_model.dart
class UserModel {
  final String? uid;
  final String email;
  final String password;
  final String? name;

  UserModel({
    this.uid,
    required this.email,
    required this.password,
    this.name,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String?,
      email: json['email'] as String,
      password: json['password'] as String,
      name: json['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'password': password,
      'name': name,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? password,
    String? name,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      password: password ?? this.password,
      name: name ?? this.name,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.uid == uid &&
        other.email == email &&
        other.password == password &&
        other.name == name;
  }

  @override
  int get hashCode {
    return uid.hashCode ^ email.hashCode ^ password.hashCode ^ name.hashCode;
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, password: $password, name: $name)';
  }
} 