/*
import 'dart:developer';
import 'package:easyexpire/feature/inventory/model/inventory_model.dart';
import 'package:easyexpire/feature/login/model/user_model.dart';
import 'package:flutter/foundation.dart';


class LocalDatabase extends ChangeNotifier{

  static Database? database;
  static const int version = 1;

  static const String _tableUser = "user";
  static const String _tableProductInventory = "inventory";


  //USER
  static const _columnId = "id";
  static const _columnFirstName = "first_name";
  static const _columnLastName = "last_name";
  static const _columnEmail = "email";
  static const _columnPhoneCode = "phone_code";
  static const _columnPhone = "phone ";

  //PRODUCT INVENTORY
  static const _columnProductId = "id";
  static const _columnProductName = "product_name";
  static const _columnBarcodeNumber = "barcode_number";
  static const _columnQuantity = "quantity";
  static const _columnBatchNo = "batch_no";
  static const _columnExpiryDate = "expiry_date ";
  static const _columnDayLeft= "days_left ";




  Future<void> initDB() async {
    if (database != null) {
      return;
    }
    try {
      String path = '${await getDatabasesPath()}expiryTrack.db';
      database =
      await openDatabase(path, version: version, onCreate: onCreate);
    } catch (ex) {
      log(ex.toString());
    }
    notifyListeners();
  }

  static void onCreate(Database db, int version) async {
    //creating user table when user registration is completed
    await db.execute(
      "CREATE TABLE $_tableUser("
          "$_columnId INTEGER PRIMARY KEY AUTOINCREMENT,"
          "$_columnFirstName STRING,"
          "$_columnLastName STRING,"
          "$_columnEmail STRING,"
          "$_columnPhoneCode STRING,"
          "$_columnPhone STRING"
          ")",
    );


    //creating product inventory table when can add products
    await db.execute(
      "CREATE TABLE $_tableProductInventory("
          "$_columnProductId INTEGER PRIMARY KEY AUTOINCREMENT,"
          "$_columnProductName STRING,"
          "$_columnBarcodeNumber INTEGER,"
          "$_columnQuantity INTEGER,"
          "$_columnBatchNo STRING,"
          "$_columnExpiryDate STRING,"
          "$_columnDayLeft STRING"
          ")",
    );
  }



  static Future<int> insertUser(UserModel userModel) async {
    return await database?.insert(_tableUser, userModel.toMap()) ?? 1;
  }

  static Future<UserModel> getProfileDetailById(String id) async {
    final maps =
    await database!.query(_tableUser, where: 'id=?', whereArgs: [id]);
    return UserModel.fromMap(maps[0]);
  }


  static Future<int> insertProduct(InventoryModel inventoryModel) async {
    return await database?.insert(_tableProductInventory, inventoryModel.toMap()) ?? 1;
  }


  static Future<List<Map<String, dynamic>>?> queryAllProducts() async {
    return await database?.query(_tableProductInventory);
  }
}
*/
