import 'dart:convert';

class ClientModel {
  final String name;
  final String email;
  final String phone;

  ClientModel({
    required this.name,
    this.email = '',
    this.phone = '',
  });

  String get id => name.trim().toLowerCase();

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'phone': phone,
      };

  factory ClientModel.fromMap(Map<String, dynamic> map) => ClientModel(
        name: map['name'] ?? '',
        email: map['email'] ?? '',
        phone: map['phone'] ?? '',
      );

  String toJson() => json.encode(toMap());

  factory ClientModel.fromJson(String source) => ClientModel.fromMap(json.decode(source));
}
