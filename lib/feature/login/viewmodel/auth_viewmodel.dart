import 'dart:developer';

import 'package:easyexpire/core/constant/app_keys.dart';
import 'package:easyexpire/core/services/firebase_services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:toastification/toastification.dart';

import '../model/user_model.dart';

class AuthViewModel extends ChangeNotifier {
  final storageBox = GetStorage();
  final loginFormKey = GlobalKey<FormState>();
  final signupFormKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  TextEditingController get emailController => _emailController;
  TextEditingController get passwordController => _passwordController;

  final TextEditingController _signupEmailController = TextEditingController();
  final TextEditingController _signupPasswordController = TextEditingController();
  final TextEditingController _signupStoreNameController = TextEditingController();
  final TextEditingController _signupStoreAddressController = TextEditingController();
  final TextEditingController _signupPhoneController = TextEditingController();

  TextEditingController get signupEmailController => _signupEmailController;
  TextEditingController get signupPasswordController =>
      _signupPasswordController;
  TextEditingController get signupStoreNameController =>
      _signupStoreNameController;
  TextEditingController get signupStoreAddressController =>
      _signupStoreAddressController;
  TextEditingController get signupPhoneController => _signupPhoneController;

  final FirebaseServices _firebaseServices = FirebaseServices();

  User? _user;

  User? get user => _user;

  bool _isSignupValid = false;
  bool get isSignupValid => _isSignupValid;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isPasswordVisible = false;
  bool get isPasswordVisible => _isPasswordVisible;

  String? storeNameValidator(String value) {
    if (value.isEmpty) {
      return 'Please enter a store name.';
    }
    return null;
  }

  String? storeAddressValidator(String value) {
    if (value.isEmpty) {
      return 'Please enter a store address.';
    }
    return null;
  }

  String? emailValidator(String value) {
    if (value.isEmpty || !value.contains('@')) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  String? passwordValidator(String value) {
    if (value.isEmpty) {
      return 'Please enter a valid password';
    } else if (value.length < 8) {
      return 'Password requires 8 characters or more';
    }
    return null;
  }

  Future<bool> login(String email, String password) async {
    try {
      UserCredential userCredential = await _firebaseServices.auth
          .signInWithEmailAndPassword(email: email, password: password);
      _user = userCredential.user;
      storageBox.write(AppKeys.keyIsLoggedIn, true);
      storageBox.write(AppKeys.keyUserId, _user?.uid);
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      log("LOGIN EXCEPTION:$e");
      if (e.code == 'invalid-credential') {
        log("INVALID CREDENTIAL PLEASE CHECK");
        Toastification().show(
          type: ToastificationType.error,
          style: ToastificationStyle.flatColored,
          title:Text("Invalid Credentials"),
          description: Text("Please check your email and password"),
          alignment: Alignment.topRight,
          autoCloseDuration: const Duration(seconds: 4),
        );
      }
      return false;
    } catch (e) {
      print("Login Error: $e");
      return false;
    }
  }

  void signUpSession(BuildContext context) {
    _isSignupValid = signupFormKey.currentState!.validate();
    FocusScope.of(context).unfocus();
    if (isSignupValid) {
      log("ON SAVED STORE NAME: ${signupStoreNameController.text}");
      log("ON SAVED STORE ADDRESS: ${signupStoreAddressController.text}");
      log("ON SAVED EMAIL: ${signupEmailController.text}");
      log("ON SAVED PASSWORD: ${signupPasswordController.text}");

      signUp(
        context,
        signupEmailController.text,
        signupPasswordController.text,
        signupStoreNameController.text,
        signupStoreAddressController.text,
      );
    }
  }

  Future<bool> logout() async {
    try {
      await _firebaseServices.auth.signOut();
      _user = null;
      _emailController.clear();
      _passwordController.clear();
      storageBox.write(AppKeys.keyIsLoggedIn, false);
      notifyListeners();

      return true;
    } catch (e) {
      log("Logout exception:${e.toString()}");
      return false;
    }
  }

  void signUp(
    BuildContext context,
    String email,
    String password,
    String storeName,
    String storeAddress,
  ) async {
    try {
      UserCredential userCredential = await _firebaseServices.auth
          .createUserWithEmailAndPassword(email: email, password: password);
      _user = userCredential.user;

      if (user != null) {
        _isLoading = false;
        final userData = UserModel(
          storeName: storeName,
          storeAddress: storeAddress,
          email: email,
          id: user!.uid.toString(),
          phoneCode: '',
          phone: '',
        );
        createUser(userData, context);
      } else {
        _isLoading = false;
        // Get.offAllNamed(AppRoutes.signUp);
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        // Email already exists
        log('The account already exists for that email.');
        // Show a snackbar or dialog to inform the user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('The account already exists for that email.')),
        );
      } else {
        // Handle other Firebase Auth exceptions
        log('Firebase Auth Error: ${e.code}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Firebase Auth Error: ${e.message ?? 'An error occurred.'}',
            ),
          ),
        );
      }
    } catch (e) {
      log("SIGNUP exception:${e.toString()}");
    }
  }

  void createUser(UserModel userData, BuildContext context) async {
    await _firebaseServices.fireStore
        .collection("Users")
        .add(userData.toMap())
        .whenComplete(() {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Success ,Your account has been created')),
          );
        })
        .catchError((error, stackTrace) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failure ,Something went wrong')),
          );
        });
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
    print("AuthViewModel disposed"); // Add for debugging
  }

  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    print("AuthViewModel togglePasswordVisibility called ${_isPasswordVisible}");
    notifyListeners();
  }

  void setIsLoading(bool isLoading) {
    _isLoading = isLoading;
    notifyListeners();
  }
}
