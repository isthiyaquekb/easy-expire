import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easyexpire/core/services/local_notification_services.dart';
import 'package:easyexpire/feature/inventory/model/inventory_model.dart';
import 'package:easyexpire/feature/login/model/user_model.dart';
import 'package:easyexpire/utils/Formatter/app_date_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:intl/intl.dart';

import '../../../core/services/firebase_services.dart';

class HomeViewModel extends ChangeNotifier {
  final FirebaseServices _firebaseServices = FirebaseServices();
  var selectedCategoryIndex = 0;
  var selectedPopularIndex = 0;
  var dayLeft = 0;
  var productList = <InventoryModel>[];
  var productFilteredList = <InventoryModel>[];
  var focusDate = DateTime.now();
  var pickedDate="";
  var dateFromDB="";

  DateTime today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  int? selectedFilter; // Null means "Show All"
  List<InventoryModel> get getProductList => productList;
  var userId = "";

  void initialize() async{
    // checkingForUpdate();
    var userData=await fetchUserDetails();
    if (userData != null) {
      print("User ID: ${userData.id}");
      print("Store Name: ${userData.storeName}");
      print("Email: ${userData.email}");
      userId=userData.id;
      getAllProduct(userId);
      notifyListeners();
    } else {
      print("User not found.");
    }
    notifyListeners();
  }

  Future<UserModel?> fetchUserDetails() async {
    UserModel? userModel = await _firebaseServices.getCurrentUserDetails();
    return userModel;
  }
  void setCategory(int index) {
    selectedCategoryIndex = index;
    notifyListeners();
  }

  Future<void> checkForUpdate(BuildContext context) async {
    try {
      AppUpdateInfo appUpdateInfo = await InAppUpdate.checkForUpdate();
      if (appUpdateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        await InAppUpdate.startFlexibleUpdate();
        InAppUpdate.completeFlexibleUpdate();
      }
    } on PlatformException catch (e) {
      if (e.code == 'TASK_FAILURE') {
        // Handle the install not allowed error
        print('Update install not allowed: ${e.message}');
      } else {
        // Handle other PlatformExceptions
        print('Platform exception during update: ${e.message}');
      }
    } catch (e) {
      // Handle other exceptions
      print('Error during update check: $e');
    }
  }

  // void checkingForUpdate(){
  //   InAppUpdate.checkForUpdate().then((info) {
  //     if(info.updateAvailability == UpdateAvailability.updateAvailable){
  //       updateMyApp();
  //     }
  //   });
  // }

  // void updateMyApp() async {
  //   await InAppUpdate.startFlexibleUpdate();
  //   InAppUpdate.completeFlexibleUpdate().then((value) {
  //   }).catchError((e){
  //     e.toString();
  //     log("Exception Caught when updating app:${e.toString()}");
  //   });
  // }


  void setSelectedDate(DateTime selectedDate){
    focusDate = selectedDate;
    pickedDate=DateFormat('dd-MMM-yyyy').format(
        selectedDate);
    // productFilteredList = productList.where((o) => DateFormat('dd-MMM-yyyy').format(DateTime.parse()) == pickedDate).toList();
    notifyListeners();
  }

  void setSelectedFilter(int? days) {
    selectedFilter = days;
    if (days == null) {
      productFilteredList = List.from(productList);
    } else if(days==0){
      productFilteredList = productList.where((product) {
        var day=AppDateFormatter.dateTimeFromFirebase(product.expiryDate);
        // Parse 'dd-MM-yyyy' format correctly
        DateTime expiryDate = DateFormat("dd-MM-yyyy").parse(day);

        log("DAYS:$days");
        int daysLeft = expiryDate.difference(today).inDays;
        log("DAYS LEFT:$daysLeft");
        return daysLeft <= days;
      }).toList();
    }else {
      productFilteredList = productList.where((product) {
        var day=AppDateFormatter.dateTimeFromFirebase(product.expiryDate);
        // Parse 'dd-MM-yyyy' format correctly
        DateTime expiryDate = DateFormat("dd-MM-yyyy").parse(day);

        log("DAYS:$days");
        int daysLeft = expiryDate.difference(today).inDays;
        log("DAYS LEFT:$daysLeft");
        return daysLeft > 0 && daysLeft <= days;
      }).toList();
    }
    notifyListeners();
  }

  // Example of retrieving all products
  Stream<QuerySnapshot> getProductsStream() {
    return _firebaseServices.fireStore.collection(_firebaseServices.productCollection).snapshots();
  }

  //GET ALL PRODUCT

  Future<void> getAllProduct(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('user_id', isEqualTo: userId)
          .orderBy('days_left')
          .get();

      productList = snapshot.docs.map((doc) {
        final data = doc.data();
        return InventoryModel.fromMap(data);
      }).toList();

      // Calculate days left and filter based on selected filter
      setSelectedFilter(null);
      _calculateDaysLeftAndFilter();
      // setupNotification();
      notifyListeners();
    } catch (e) {
      print('Error fetching products: $e');
      // Handle error (e.g., show a snackbar)
    }
  }

  void _calculateDaysLeftAndFilter() {
    for (var product in productList) {
      final now = DateTime.now();
      var day=AppDateFormatter.dateTimeFromFirebase(product.expiryDate);
      // Parse 'dd-MM-yyyy' format correctly
      DateTime expiryDate = DateFormat("dd-MM-yyyy").parse(day);
      final difference = expiryDate.difference(now).inDays;
      product.daysLeft = difference;
    }

    setSelectedFilter(selectedFilter);
  }
  // void getAllProduct() async {
    // productList.clear();
    // if(dataList!.isNotEmpty){
    //   for (var element in dataList) {
    //     var data = InventoryModel.fromMap(element);
    //     calculateDaysRemaining(DateTime.parse(data.expiryDate), DateTime.now(),data);
    //   }
    //   if(DateTime.parse(InventoryModel.fromMap(dataList.first).expiryDate).isBefore(DateTime.now())){
    //
    //     setSelectedDate(DateTime.now());
    //   }else{
    //     setSelectedDate(DateTime.parse(InventoryModel.fromMap(dataList.first).expiryDate));
    //   }
    // }
    // notifyListeners();
  // }


  void calculateDaysRemaining(DateTime from, DateTime to, InventoryModel data,) {
    var fromDate = DateTime(from.year, from.month, from.day);
    var toDate = DateTime(to.year, to.month, to.day);
    dayLeft = (fromDate
        .difference(toDate)
        .inHours / 24).round();
    // var inventoryData=InventoryModel(barcode: data.barcode,
    //     productName: data.productName,
    //     expiryDate: data.expiryDate,
    //     batchNo: data.batchNo,
    //     quantity: data.quantity,
    //     daysLeft: dayLeft);
    // productList.add(inventoryData);
    // var myDateTime=DateFormat("HH:mm").format(DateTime.parse(data.expiryDate
    // ));
    // LocalNotificationServices.showScheduleNotification(int.parse(myDateTime.split(":")[0]), int.parse(myDateTime.split(":")[1]), data.productName, data.expiryDate, data.daysLeft.toString());
  }


  Future<void> signOut() async {
    await _firebaseServices.appLogout();
    log("LOGOUT OUT FIREBASE");
  }

  void setupNotification() async {
    for (int i = 0; i < productList.length; i++) {
      final product = productList[i];
      final dateStr = AppDateFormatter.dateTimeFromFirebase(product.expiryDate);
      final expiryDate = DateFormat("dd-MM-yyyy").parse(dateStr);

      await LocalNotificationServices.showExpiryNotification(
        id: product.userId.hashCode, // unique per product
        title: 'Product Expiry Reminder',
        body: '${product.productName} will expire in 5 days!',
        expiryDate: expiryDate,
        payload: product.userId, // for tapping
      );
    }

  }

}