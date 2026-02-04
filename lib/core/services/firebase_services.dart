import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easyexpire/core/constant/app_keys.dart';
import 'package:easyexpire/feature/login/model/user_model.dart';
import 'package:easyexpire/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get_storage/get_storage.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';

class FirebaseServices {
  static final FirebaseServices _instance = FirebaseServices._internal();
  final storageBox = GetStorage();
  factory FirebaseServices() => _instance;

  FirebaseServices._internal();

  FirebaseAuth get auth => FirebaseAuth.instance;
  FirebaseFirestore get fireStore => FirebaseFirestore.instance;

  final String userCollection = 'Users';
  final String productCollection = 'products';

  Future<void> initializeFirebase() async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    // await requestNotificationPermission();
  }

  // Method to get the current authenticated user
  User? getCurrentAuthUser() {
    return auth.currentUser;
  }

  // Method to get user details from Firestore
  Future<UserModel?> getCurrentUserDetails() async {
    User? user = auth.currentUser;
    if (user != null) {
      // Query Firestore for the document where id == user.uid
      QuerySnapshot querySnapshot = await fireStore
          .collection(userCollection)
          .where('id', isEqualTo: user.uid) // Match Firestore document with Firebase Auth UID
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        var userData = querySnapshot.docs.first.data() as Map<String, dynamic>;
        return UserModel.fromMap(userData);
      } else {
        print("User document not found in Firestore.");
      }
    } else {
      print("No user is signed in.");
    }
    return null;
  }


  Future<void> appLogout() async {
    auth.signOut();
    log("AUTH O SIGN OUT FIREBASE");
    storageBox.write(AppKeys.keyIsLoggedIn, false);
  }
 /* Future<void> requestNotificationPermission() async {
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      print("User denied push notifications.");
    }
  }*/
}
