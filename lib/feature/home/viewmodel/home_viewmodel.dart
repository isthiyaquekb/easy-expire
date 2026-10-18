import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easyexpire/feature/inventory/model/inventory_model.dart';
import 'package:easyexpire/feature/login/model/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:intl/intl.dart';

import 'package:easyexpire/core/services/product_notification_coordinator.dart';
import 'package:easyexpire/core/utils/expiry_date_calculator.dart';
import '../../../core/services/firebase_services.dart';
import 'package:easyexpire/core/services/background_service.dart';

class HomeViewModel extends ChangeNotifier {
  final FirebaseServices _firebaseServices = FirebaseServices();
  var selectedCategoryIndex = 0;
  var selectedPopularIndex = 0;
  var dayLeft = 0;
  var productList = <InventoryModel>[];
  var productFilteredList = <InventoryModel>[];
  var focusDate = DateTime.now();
  var pickedDate = "";
  var dateFromDB = "";

  DateTime today = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );
  int? selectedFilter; // Null means "Show All"
  List<InventoryModel> get getProductList => productList;
  var userId = "";

  void initialize() async {
    // checkingForUpdate();
    var userData = await fetchUserDetails();
    if (userData != null) {
      log("User ID: ${userData.id}");
      log("Store Name: ${userData.storeName}");
      log("Email: ${userData.email}");
      userId = userData.id;
      getAllProduct(userId);
      notifyListeners();
    } else {
      log("User not found.");
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
      if (appUpdateInfo.updateAvailability ==
          UpdateAvailability.updateAvailable) {
        await InAppUpdate.startFlexibleUpdate();
        InAppUpdate.completeFlexibleUpdate();
      }
    } on PlatformException catch (e) {
      if (e.code == 'TASK_FAILURE') {
        // Handle the install not allowed error
        log('Update install not allowed: ${e.message}');
      } else {
        // Handle other PlatformExceptions
        log('Platform exception during update: ${e.message}');
      }
    } catch (e) {
      // Handle other exceptions
      log('Error during update check: $e');
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

  void setSelectedDate(DateTime selectedDate) {
    focusDate = selectedDate;
    pickedDate = DateFormat('dd-MMM-yyyy').format(selectedDate);
    // productFilteredList = productList.where((o) => DateFormat('dd-MMM-yyyy').format(DateTime.parse()) == pickedDate).toList();
    notifyListeners();
  }

  void setSelectedFilter(int? days) {
    selectedFilter = days;
    if (days == null) {
      log("DAYS==ALL DAYS:$days");
      productFilteredList = List.from(productList);
    } else if (days == 0) {
      productFilteredList =
          productList.where((product) {
            final daysLeft = calculateCalendarDaysRemaining(
              product.expiryDate.toDate(),
              today,
            );
            return daysLeft <= days;
          }).toList();
    } else {
      productFilteredList =
          productList.where((product) {
            final daysLeft = calculateCalendarDaysRemaining(
              product.expiryDate.toDate(),
              today,
            );
            return daysLeft > 0 && daysLeft <= days;
          }).toList();
    }
    notifyListeners();
  }

  // Example of retrieving all products
  Stream<QuerySnapshot> getProductsStream() {
    return _firebaseServices.fireStore
        .collection(_firebaseServices.productCollection)
        .snapshots();
  }

  //GET ALL PRODUCT

  Future<void> getAllProduct(String userId) async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('products')
              .where('user_id', isEqualTo: userId)
              .orderBy('days_left')
              .get();

      productList =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return InventoryModel.fromMap(data, docId: doc.id);
          }).toList();

      // Calculate days left and filter based on selected filter
      setSelectedFilter(null);
      _calculateDaysLeftAndFilter();
      setupNotification();
      try {
        await ProductNotificationCoordinator().reconcileProducts(productList);
      } catch (reconcileErr) {
        log('Error reconciling product notifications: $reconcileErr');
      }
      notifyListeners();
    } catch (e) {
      log('Error fetching products: $e');
      // Handle error (e.g., show a snackbar)
    }
  }

  void _calculateDaysLeftAndFilter() {
    final now = DateTime.now();
    for (var product in productList) {
      final difference = calculateCalendarDaysRemaining(
        product.expiryDate.toDate(),
        now,
      );
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

  void calculateDaysRemaining(DateTime from, DateTime to, InventoryModel data) {
    dayLeft = calculateCalendarDaysRemaining(from, to);
  }

  Future<void> signOut() async {
    await _firebaseServices.appLogout();
    log("LOGOUT OUT FIREBASE");
  }

  void setupNotification() async {
    final effectiveUserId = userId.isEmpty ? 'test_user_id' : userId;
    // Register the periodic background task to check expiry dates every 1+ hours
    BackgroundService.registerPeriodicExpiryCheck(effectiveUserId);
  }

  Future<void> triggerTestNotification() async {
    final effectiveUserId = userId.isEmpty ? 'test_user_id' : userId;

    // Register a one-off task to test the background worker immediately
    BackgroundService.triggerOneOffTest(effectiveUserId);
  }
}
