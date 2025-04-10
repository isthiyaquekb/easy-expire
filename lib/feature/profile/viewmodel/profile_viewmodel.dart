import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easyexpire/core/services/firebase_services.dart';
import 'package:easyexpire/feature/login/model/user_model.dart';
import 'package:flutter/cupertino.dart';

class ProfileViewmodel extends ChangeNotifier{

  final FirebaseServices _firebaseServices = FirebaseServices();

  final _formKey = GlobalKey<FormState>();
  GlobalKey get formKey=>_formKey;

  bool _isValid = false;
  bool get isValid => _isValid;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _storeController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();


  TextEditingController get emailController => _emailController;
  TextEditingController get storeController => _storeController;
  TextEditingController get addressController => _addressController;
  TextEditingController get phoneController => _phoneController;

  var userId = "";
  UserModel userModel = UserModel.empty();
  void initialize()async{
    var userData=await fetchUserDetails();
    if (userData != null) {
      userModel=userData;
      print("User ID: ${userData.id}");
      print("Store Name: ${userData.storeName}");
      print("Email: ${userData.email}");
      userId=userData.id;
      _emailController.text=userModel.email;
      _storeController.text=userModel.storeName;
      _addressController.text=userModel.storeAddress;
      _phoneController.text=userModel.phone;
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

  String? storeNameValidator(String value) {
    if(value.isEmpty){
      return 'please enter a name';
    }
    return null;
  }

  String? storeAddressValidator(String value) {
    if(value.isEmpty){
      return 'please enter an address';
    }
    return null;
  }

  String? phoneValidator(String value) {
    if(value.isEmpty){
      return 'please enter a number';
    }else if(value.length<10){
      return 'please enter a valid number';
    }
    return null;
  }


  String? emailValidator(String value, BuildContext context) {
    if (value.isNotEmpty &&
        RegExp(r"^[a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
            .hasMatch(value)) {
      return null;
    }
    return 'email cannot be blank';
  }

  void sessionProfile(BuildContext context) {
    _isValid = _formKey.currentState!.validate();
    FocusScope.of(context).unfocus();
    if (isValid) {
      log("ON SAVED STORE NAME: ${storeController.text}");
      log("ON SAVED STORE ADDRESS: ${addressController.text}");
      log("ON SAVED EMAIL: ${emailController.text}");
      log("ON SAVED PHONE: ${phoneController.text}");

      updateProfile(
        context,
        userId,
        UserModel(id: userId, storeName: storeController.text, storeAddress: addressController.text, email: emailController.text, phoneCode: '', phone: phoneController.text),
      );
    }
  }

  void updateProfile(BuildContext context,String userId,UserModel userData) async {
    try{
      await _firebaseServices.fireStore
          .collection('Users')
          .doc(userId)
          .set(userData.toMap(), SetOptions(merge: true)); // Merge new fields without overwriting
      log("PROFILE UPDATE RESPONSE");
      // enableEdit(!isEnabled);
      initialize();
      Navigator.pop(context);
    }catch(e){
      log("EXCEPTION:${e.toString()}");
    }
  }


}