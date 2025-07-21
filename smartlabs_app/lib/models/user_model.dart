class UserModel {
  final int id;
  final String name;
  final String registration;
  final String email;
  final String cardsNumber;
  final int deviceId;

  UserModel({
    required this.id,
    required this.name,
    required this.registration,
    required this.email,
    required this.cardsNumber,
    required this.deviceId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      registration: json['registration'],
      email: json['email'],
      cardsNumber: json['cards_number'],
      deviceId: json['device_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'registration': registration,
      'email': email,
      'cards_number': cardsNumber,
      'device_id': deviceId,
    };
  }
}