import 'dart:convert';

UserModel userDataFromMap(String str) => UserModel.fromMap(json.decode(str));

String userDataToMap(UserModel data) => json.encode(data.toMap());

class UserModel {
  UserModel(
      {required this.id,
        required this.storeName,
        required this.storeAddress,
        required this.email,
        required this.phoneCode,
        required this.phone});

  String id;
  String storeName;
  String storeAddress;
  String email;
  String phoneCode;
  String phone;

  factory UserModel.fromMap(Map<String, dynamic> json) => UserModel(
    id: json["id"],
    storeName: json["store_name"],
    storeAddress: json["store_address"],
    email: json["email"],
    phoneCode: json["phone_code"],
    phone: json["phone"],
  );

  Map<String, dynamic> toMap() => {
    "id": id,
    "store_name": storeName,
    "store_address": storeAddress,
    "email": email,
    "phone_code": phoneCode,
    "phone": phone,
  };

  factory UserModel.empty() {
    return UserModel(
      id: '',
      storeName: '',
      storeAddress: '',
      email: '',
      phoneCode: '',
      phone: '',
    );
  }
}
