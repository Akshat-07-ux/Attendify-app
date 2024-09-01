// user_model.dart
class UserModel {
  String uid;
  String name;
  String email;
  String phone;
  String address;
  int presents;
  int absents;
  int cl;  // Casual Leave
  int el;  // Earned Leave
  int sl;  // Sick Leave
  bool hasNotification;

  UserModel(
    this.uid,
    this.name,
    this.email,
    this.phone,
    this.address,
    this.presents,
    this.absents,
    this.cl,
    this.el,
    this.sl,
    {this.hasNotification = false}
  );

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'name': name,
    'email': email,
    'phone': phone,
    'address': address,
    'presents': presents,
    'absents': absents,
    'cl': cl,
    'el': el,
    'sl': sl,
    'hasNotification': hasNotification,
  };

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      json['uid'] ?? '',
      json['name'] ?? '',
      json['email'] ?? '',
      json['phone'] ?? '',
      json['address'] ?? '',
      json['presents'] ?? 0,
      json['absents'] ?? 0,
      json['cl'] ?? 0,
      json['el'] ?? 0,
      json['sl'] ?? 0,
      hasNotification: json['hasNotification'] ?? false,
    );
  }
}