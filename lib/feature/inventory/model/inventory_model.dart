import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryModel{
  final String productName;
  final String userId;
  final Timestamp expiryDate;
  final String batchNo;
  final int quantity;
  int daysLeft;

  InventoryModel({required this.productName,required this.userId, required this.expiryDate,required this.batchNo,required this.quantity,required this.daysLeft});

  factory InventoryModel.fromMap(Map<String, dynamic> json) => InventoryModel(
    productName: json["product_name"],
    userId: json["user_id"],
    expiryDate: json["expiry_date"] is Timestamp ? json["expiry_date"] : Timestamp.now(),
    batchNo: json["batch_no"],
    quantity: json["quantity"],
    daysLeft: json["days_left"]?? 0,
  );

  Map<String, dynamic> toMap() => {

    "product_name": productName,
    "user_id": userId,
    "expiry_date": expiryDate,
    "batch_no": batchNo,
    "quantity": quantity,
    "days_left": daysLeft,
  };

}