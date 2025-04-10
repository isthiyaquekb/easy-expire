import 'package:easyexpire/feature/dashboard/viewmodel/dashboard_provider.dart';
import 'package:easyexpire/feature/home/viewmodel/home_viewmodel.dart';
import 'package:easyexpire/feature/inventory/model/inventory_model.dart';
import 'package:easyexpire/feature/login/model/user_model.dart';
import 'package:easyexpire/utils/Formatter/app_date_formatter.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/services/firebase_services.dart';

class InventoryViewModel extends ChangeNotifier {
  final FirebaseServices _firebaseServices = FirebaseServices();

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

  final formKey = GlobalKey<FormState>();

  var currentDate = DateTime.now();
  var currentDateTime = DateTime.now();
  var dayLeft = 0;
  var nowDate = "";
  var selectedDate = "";
  var userId = "";

  void initialize() async{
    var userData=await fetchUserDetails();
    if (userData != null) {
      print("User ID: ${userData.id}");
      print("Store Name: ${userData.storeName}");
      print("Email: ${userData.email}");
      userId=userData.id;
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

  void onSelectingDate() {
    print("PRINTING SELECTED DATE:${dateController.text}");
    final inputFormat = DateFormat("dd/MM/yyyy");
    // Parse the date string with the correct format
    DateTime parsedDate = inputFormat.parse(dateController.text);
    DateTime tempDate =
        DateFormat("yyyy-MM-dd hh:mm:ss").parse(parsedDate.toString());
    print("PRINTING FORMATTED DATE:$tempDate");
  }

  void pickDate(BuildContext context) async {
    var pickedDate = await showDatePicker(
        context: context,
        initialDate: currentDate,
        firstDate: DateTime.now(),
        lastDate: DateTime(2040));

    if (pickedDate != null && pickedDate != currentDate) {
      combineDateWithCurrentTime(pickedDate);
    }

    nowDate = DateFormat('yyyy-MM-dd').format(currentDate).toString();

    selectedDate = DateFormat('dd/MM/yyyy').format(currentDate);
    calculateDaysRemaining(pickedDate!, DateTime.now());
    print("CURRENT DATE SELECTED :$selectedDate");

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
    if (formKey.currentState!.validate()) {
      // print("BARCODE NUMBER:${barcodeController.text}");
      print("PRODUCT NAME:${nameController.text}");
      print("QUANTITY NAME:${quantityController.text}");
      print("DATE EXPIRY:$currentDate");
      print("DAY LEFT:$dayLeft");
      print("BATCH EXPIRY:${batchNoController.text}");
      var data = InventoryModel(
          userId: userId,
          productName: nameController.text,
          expiryDate: AppDateFormatter.firebaseTimestampFormatter(currentDate.toString()),
          batchNo: batchNoController.text,
          quantity: int.parse(quantityController.text),daysLeft: dayLeft);
      await addProduct(data, context);
      print("JSON TO DB:${data.toMap()}");
    }
  }

  Future<void> addProduct(
      InventoryModel data,
      BuildContext context,
      ) async {
    try {
      await _firebaseServices.fireStore.collection(_firebaseServices.collectionName).add(data.toMap()).then((value) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Product added successfully')),
        );
        resetFields();
        Provider.of<HomeViewModel>(context,listen: false).getAllProduct(userId);
        Provider.of<DashboardProvider>(context, listen: false).changeBottomNavIndex(0);
      },);


    } catch (e) {
      print('Error adding product: $e');
    }
  }

  void calculateDaysRemaining(DateTime from, DateTime to) {
    var fromDate = DateTime(from.year, from.month, from.day);
    var toDate = DateTime(to.year, to.month, to.day);
    dayLeft = (fromDate.difference(toDate).inHours / 24).round();

    print("Calculated DATE IS $dayLeft");
  }

  void getAllProductFromDB() async {
    // var productList=await LocalDatabase.queryAllProducts();
    //
    // notifyListeners();
    // print("Product List invent $productList");
  }

  void resetFields() {
    _barcodeController=TextEditingController();
    _nameController=TextEditingController();
    _quantityController=TextEditingController();
    _dateController=TextEditingController();
    _batchNoController=TextEditingController();
    notifyListeners();
  }
}
