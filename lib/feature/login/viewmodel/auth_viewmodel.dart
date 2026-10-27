import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easyexpire/core/constant/app_keys.dart';
import 'package:easyexpire/core/services/fcm_service.dart';
import 'package:easyexpire/core/services/firebase_services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:toastification/toastification.dart';

import '../model/user_model.dart';

class PasswordResetResult {
  final bool success;
  final String? errorMessage;
  final String? errorCode;

  const PasswordResetResult({
    required this.success,
    this.errorMessage,
    this.errorCode,
  });
}

class AuthViewModel extends ChangeNotifier {
  final storageBox = GetStorage();
  final loginFormKey = GlobalKey<FormState>();
  final signupFormKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  TextEditingController get emailController => _emailController;
  TextEditingController get passwordController => _passwordController;

  final TextEditingController _signupEmailController = TextEditingController();
  final TextEditingController _signupPasswordController =
      TextEditingController();
  final TextEditingController _signupStoreNameController =
      TextEditingController();
  final TextEditingController _signupStoreAddressController =
      TextEditingController();
  final TextEditingController _signupPhoneController = TextEditingController();

  TextEditingController get signupEmailController => _signupEmailController;
  TextEditingController get signupPasswordController =>
      _signupPasswordController;
  TextEditingController get signupStoreNameController =>
      _signupStoreNameController;
  TextEditingController get signupStoreAddressController =>
      _signupStoreAddressController;
  TextEditingController get signupPhoneController => _signupPhoneController;

  final FirebaseAuth? _customAuth;
  final FirebaseServices _firebaseServices = FirebaseServices();

  FirebaseAuth get _auth => _customAuth ?? _firebaseServices.auth;

  AuthViewModel({FirebaseAuth? auth}) : _customAuth = auth;

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
      if (_user != null) {
        FcmService().syncTokenToFirestore(_user!.uid);
      }
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      log("LOGIN EXCEPTION:$e");
      if (e.code == 'invalid-credential') {
        log("INVALID CREDENTIAL PLEASE CHECK");
        Toastification().show(
          type: ToastificationType.error,
          style: ToastificationStyle.flatColored,
          title: Text("Invalid Credentials"),
          description: Text("Please check your email and password"),
          alignment: Alignment.topRight,
          autoCloseDuration: const Duration(seconds: 4),
        );
      }
      return false;
    } catch (e) {
      log("Login Error: $e");
      return false;
    }
  }

  Future<PasswordResetResult> sendPasswordResetEmail(String email) async {
    final trimmedEmail = email.trim();
    if (kDebugMode) {
      debugPrint('[AUTH-RESET] Initiating password reset for: "$trimmedEmail"');
    }

    try {
      await _auth.sendPasswordResetEmail(email: trimmedEmail);
      if (kDebugMode) {
        debugPrint(
          '[AUTH-RESET] SUCCESS: sendPasswordResetEmail call succeeded for "$trimmedEmail"',
        );
      }
      return const PasswordResetResult(success: true);
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[AUTH-RESET] FirebaseAuthException: code="${e.code}", message="${e.message}"',
        );
      }
      final String userFriendlyMessage;
      switch (e.code) {
        case 'user-not-found':
          userFriendlyMessage = 'No account found with this email address.';
          break;
        case 'invalid-email':
          userFriendlyMessage = 'The email address is not valid.';
          break;
        case 'too-many-requests':
          userFriendlyMessage = 'Too many attempts. Please try again later.';
          break;
        case 'network-request-failed':
          userFriendlyMessage =
              'Network error. Please check your internet connection.';
          break;
        case 'operation-not-allowed':
          userFriendlyMessage =
              'Password reset is not enabled for this project.';
          break;
        default:
          userFriendlyMessage =
              e.message ?? 'Failed to send password reset email. Please try again.';
          break;
      }
      return PasswordResetResult(
        success: false,
        errorMessage: userFriendlyMessage,
        errorCode: e.code,
      );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('[AUTH-RESET] Unexpected error: $e\n$stackTrace');
      }
      return const PasswordResetResult(
        success: false,
        errorMessage: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  void signUpSession(BuildContext context) {
    _isSignupValid = signupFormKey.currentState!.validate();
    FocusScope.of(context).unfocus();
    if (isSignupValid) {
      log("ON SAVED STORE NAME: ${signupStoreNameController.text}");
      log("ON SAVED STORE ADDRESS: ${signupStoreAddressController.text}");
      log("ON SAVED EMAIL: ${signupEmailController.text}");

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
      await _firebaseServices.appLogout();
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

      if (!context.mounted) return;
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
      if (!context.mounted) return;
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
    try {
      await _firebaseServices.fireStore
          .collection("Users")
          .doc(userData.id)
          .set(userData.toMap(), SetOptions(merge: true));
      await FcmService().syncTokenToFirestore(userData.id);
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Success, Your account has been created')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failure, Something went wrong')),
      );
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
    log("AuthViewModel disposed"); // Add for debugging
  }

  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    log("AuthViewModel togglePasswordVisibility called $_isPasswordVisible");
    notifyListeners();
  }

  void setIsLoading(bool isLoading) {
    _isLoading = isLoading;
    notifyListeners();
  }
}
