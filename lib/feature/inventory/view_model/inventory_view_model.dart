import 'dart:developer';
import 'package:easyexpire/core/services/notification_history_service.dart';
import 'package:easyexpire/core/services/product_notification_coordinator.dart';
import 'package:easyexpire/core/utils/expiry_date_calculator.dart';
import 'package:easyexpire/core/utils/ocr_parser.dart';
import 'package:easyexpire/feature/dashboard/viewmodel/dashboard_provider.dart';
import 'package:easyexpire/feature/home/viewmodel/home_viewmodel.dart';
import 'package:easyexpire/feature/inventory/model/inventory_model.dart';
import 'package:easyexpire/feature/login/model/user_model.dart';
import 'package:easyexpire/utils/Formatter/app_date_formatter.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/firebase_services.dart';

class InventoryViewModel extends ChangeNotifier {
  final FirebaseServices _firebaseServices;
  final FirebaseFirestore? _firestore;

  InventoryViewModel({
    FirebaseServices? firebaseServices,
    FirebaseFirestore? firestore,
  })  : _firebaseServices = firebaseServices ?? FirebaseServices(),
        _firestore = firestore;

  FirebaseFirestore get firestore => _firestore ?? _firebaseServices.fireStore;

  TextEditingController _barcodeController = TextEditingController();
  TextEditingController _nameController = TextEditingController();
  TextEditingController _dateController = TextEditingController();
  TextEditingController _quantityController = TextEditingController();
  TextEditingController _batchNoController = TextEditingController();

  TextEditingController get barcodeController => _barcodeController;
  TextEditingController get nameController => _nameController;
  TextEditingController get dateController => _dateController;
  TextEditingController get quantityController => _quantityController;
  TextEditingController get batchNoController => _batchNoController;

  // final formKey = GlobalKey<FormState>();
  GlobalKey<FormState> get formKey => GlobalKey<FormState>();

  var currentDate = DateTime.now();
  var currentDateTime = DateTime.now();
  var dayLeft = 0;
  var nowDate = "";
  var selectedDate = "";
  var userId = "";

  void initialize() async {
    var userData = await fetchUserDetails();
    if (userData != null) {
      print("User ID: ${userData.id}");
      print("Store Name: ${userData.storeName}");
      print("Email: ${userData.email}");
      userId = userData.id;
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

  void setBarCode(String barcode) {
    _barcodeController.text = barcode;
    //calculateDaysRemaining("12/05/2024" as DateTime,DateTime.now());
    notifyListeners();
  }

  /// Applies OCR-detected values to the form controllers.
  ///
  /// Only fills fields where [result] has a non-null value — existing
  /// controller content is preserved for fields the OCR didn't detect.
  void applyOcrResult(OcrParseResult result) {
    if (result.batchNumber != null && result.batchNumber!.isNotEmpty) {
      _batchNoController.text = result.batchNumber!;
    }
    if (result.expiryDate != null) {
      combineDateWithCurrentTime(result.expiryDate!);
      _dateController.text = DateFormat(
        'dd/MM/yyyy',
      ).format(result.expiryDate!);
      calculateDaysRemaining(result.expiryDate!, DateTime.now());
    }
    notifyListeners();
  }

  ///NAME VALIDATOR
  String? nameValidator(String value) {
    if (value.isEmpty) {
      return 'Please enter a name.';
    }
    return null;
  }

  ///DATE VALIDATOR
  String? dateValidator(String value) {
    if (value.isEmpty) {
      return 'Please enter a date.';
    }
    return null;
  }

  String? batchValidator(String value) {
    if (value.isEmpty) {
      return 'This field cannot be empty.';
    }
    return null;
  }

  ///QUANTITY VALIDATOR
  String? quantityValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a quantity.';
    }
    final trimmed = value.trim();
    final parsed = int.tryParse(trimmed);
    if (parsed == null) {
      return 'Please enter a valid whole number.';
    }
    if (parsed <= 0) {
      return 'Quantity must be greater than 0.';
    }
    if (parsed > 999999) {
      return 'Quantity exceeds maximum limit.';
    }
    return null;
  }

  void onSelectingDate() {
    print("PRINTING SELECTED DATE:${dateController.text}");
    final inputFormat = DateFormat("dd/MM/yyyy");
    // Parse the date string with the correct format
    DateTime parsedDate = inputFormat.parse(dateController.text);
    DateTime tempDate = DateFormat(
      "yyyy-MM-dd hh:mm:ss",
    ).parse(parsedDate.toString());
    print("PRINTING FORMATTED DATE:$tempDate");
  }

  void pickDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    DateTime initial = currentDate.isBefore(today) ? today : currentDate;

    var pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: today,
      lastDate: DateTime(2040),
    );

    if (pickedDate == null) return;

    if (pickedDate != currentDate) {
      combineDateWithCurrentTime(pickedDate);
    }

    nowDate = DateFormat('yyyy-MM-dd').format(currentDate).toString();

    selectedDate = DateFormat('dd/MM/yyyy').format(currentDate);
    _dateController.text = selectedDate;
    calculateDaysRemaining(pickedDate, DateTime.now());
    log("CURRENT DATE SELECTED :$selectedDate");

    notifyListeners();
  }

  void combineDateWithCurrentTime(DateTime pickedDate) {
    DateTime now = DateTime.now();
    DateTime combinedDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      now.hour,
      now.minute,
      now.second,
      now.millisecond,
      now.microsecond,
    );
    print("Combined DateTime: $combinedDateTime");
    currentDate = combinedDateTime;
    print('DATETIME NOW:${DateTime.now()}');
    print('CURRENT PICKED DATE TIME:$combinedDateTime');
    print('CURRENT PICKED DATE:$currentDate');
  }

  Future<void> submit(BuildContext context) async {
    final qtyError = quantityValidator(quantityController.text);
    if (qtyError != null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(qtyError),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final effectiveUserId =
        userId.isNotEmpty
            ? userId
            : (_firebaseServices.auth.currentUser?.uid ?? '');
    final parsedQuantity = int.parse(quantityController.text.trim());

    var data = InventoryModel(
      userId: effectiveUserId,
      productName: nameController.text.trim(),
      expiryDate: AppDateFormatter.firebaseTimestampFormatter(
        currentDate.toString(),
      ),
      batchNo: batchNoController.text.trim(),
      quantity: parsedQuantity,
      daysLeft: dayLeft,
    );
    await addProduct(data, context);
  }

  Future<void> addProduct(InventoryModel data, BuildContext context) async {
    try {
      final docRef = await _firebaseServices.fireStore
          .collection(_firebaseServices.productCollection)
          .add(data.toMap());

      final productWithId = InventoryModel(
        id: docRef.id,
        productName: data.productName,
        userId: data.userId,
        expiryDate: data.expiryDate,
        batchNo: data.batchNo,
        quantity: data.quantity,
        daysLeft: data.daysLeft,
      );

      try {
        await ProductNotificationCoordinator()
            .scheduleProductNotifications(productWithId);
      } catch (notifErr) {
        log("Error scheduling notifications for added product: $notifErr");
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product added successfully')),
        );
      }
      resetFields();
      if (context.mounted) {
        Provider.of<HomeViewModel>(
          context,
          listen: false,
        ).getAllProduct(data.userId);
        Provider.of<DashboardProvider>(
          context,
          listen: false,
        ).changeBottomNavIndex(0);
      }
    } catch (e) {
      log('Error adding product: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add product: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Updates an existing product in Firestore and reconciles scheduled notifications.
  Future<bool> updateProduct(
    InventoryModel updatedProduct, [
    BuildContext? context,
  ]) async {
    final productId = updatedProduct.id;
    if (productId == null || productId.isEmpty) {
      log('[INVENTORY] Error updating product: document ID is missing.');
      return false;
    }

    final currentUid =
        userId.isNotEmpty
            ? userId
            : (_firebaseServices.auth.currentUser?.uid ?? '');
    if (updatedProduct.userId.isNotEmpty &&
        currentUid.isNotEmpty &&
        updatedProduct.userId != currentUid) {
      log('[INVENTORY] Unauthorized update attempt on product $productId by $currentUid');
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unauthorized: You do not own this product.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }

    try {
      await firestore
          .collection(_firebaseServices.productCollection)
          .doc(productId)
          .update(updatedProduct.toMap());

      try {
        await ProductNotificationCoordinator()
            .scheduleProductNotifications(updatedProduct);
      } catch (notifErr) {
        log('[INVENTORY] Error reconciling notification for updated product: $notifErr');
      }

      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product updated successfully')),
        );
        Provider.of<HomeViewModel>(
          context,
          listen: false,
        ).getAllProduct(updatedProduct.userId);
      }
      return true;
    } catch (e) {
      log('[INVENTORY] Error updating product: $e');
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update product: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  /// Deletes a product from Firestore and cleans up associated notification records.
  Future<bool> deleteProduct(
    InventoryModel product, [
    BuildContext? context,
  ]) async {
    final productId = product.id;
    if (productId == null || productId.isEmpty) {
      log('[INVENTORY] Error deleting product: document ID is missing.');
      return false;
    }

    final currentUid =
        userId.isNotEmpty
            ? userId
            : (_firebaseServices.auth.currentUser?.uid ?? '');
    if (product.userId.isNotEmpty &&
        currentUid.isNotEmpty &&
        product.userId != currentUid) {
      log('[INVENTORY] Unauthorized deletion attempt on product $productId by $currentUid');
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unauthorized: You do not own this product.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }

    try {
      await firestore
          .collection(_firebaseServices.productCollection)
          .doc(productId)
          .delete();

      try {
        await NotificationHistoryService().deleteNotification(
          userId: product.userId,
          productId: productId,
        );
      } catch (historyErr) {
        log('[INVENTORY] Error deleting notification history for $productId: $historyErr');
      }

      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted successfully')),
        );
        Provider.of<HomeViewModel>(
          context,
          listen: false,
        ).getAllProduct(product.userId);
      }
      return true;
    } catch (e) {
      log('[INVENTORY] Error deleting product: $e');
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete product: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  void calculateDaysRemaining(DateTime from, DateTime to) {
    dayLeft = calculateCalendarDaysRemaining(from, to);
    print("Calculated DATE IS $dayLeft");
  }

  void getAllProductFromDB() async {
    // var productList=await LocalDatabase.queryAllProducts();
    //
    // notifyListeners();
    // print("Product List invent $productList");
  }

  void resetFields() {
    _barcodeController = TextEditingController();
    _nameController = TextEditingController();
    _quantityController = TextEditingController();
    _dateController = TextEditingController();
    _batchNoController = TextEditingController();
    notifyListeners();
  }
}
