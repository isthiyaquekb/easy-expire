import 'dart:developer';
import 'package:audioplayers/audioplayers.dart';
import 'package:easyexpire/core/constant/app_keys.dart';
import 'package:easyexpire/core/services/ringtone_services.dart';
import 'package:easyexpire/feature/settings/model/ringtone_model.dart';
import 'package:easyexpire/utils/Permissions/app_permissions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

class SettingsViewmodel extends ChangeNotifier {
  final player = AudioPlayer();
  List<RingtoneModel> ringtoneList = [];

  bool _isNotificationEnable = false;
  bool get isNotificationEnable => _isNotificationEnable;

  void initialize() async {
    _loadInitialPermissionState();
    // loadRingtones();
  }

  Future<void> _loadInitialPermissionState() async {
    _isNotificationEnable =
        await AppPermissions.instance
            .isNotificationPermissionCurrentlyGranted();
    notifyListeners();
  }

  void loadRingtones() async {
    var ringtones = await RingtoneService.getRingtones();

    for (var toneData in ringtones) {
      // Assuming RingtoneService.getRingtones() returns a list of maps
      // that already contain 'title' and 'uri' keys.
      ringtoneList.add(
        RingtoneModel(
          title: toneData['title'] as String,
          path: toneData['path'] as String,
          // You might want to extract the ID here if your RingtoneService provides it directly
          id: _extractIdFromUri(toneData['path'] as String),
        ),
      );
      // print("Ringtone Object: $ringtoneList");
      print("Ringtone URI: ${toneData['path']}");
      notifyListeners();
    }

    for (var tone in ringtones) {
      print("Ringtone: ${tone['title']} - ${tone['path']}");
    }
  }

  void playSound(String path) async {
    log("LOG PATH:$path");
    try {
      await player.play(DeviceFileSource(path), volume: 2);
    } catch (e) {
      print("Error playing with audioplayers: $e");
    }
  }

  void change(bool val) async {
    if (val) {
      bool permissionGranted =
          await AppPermissions.instance.requestNotificationPermission();
      _isNotificationEnable = permissionGranted; // State is now reliable
      log("onChange value: $_isNotificationEnable"); // Use the updated state
    } else {
      _isNotificationEnable = false;
      log("onChange value: $_isNotificationEnable"); // Use the updated state
    }
    notifyListeners();
    final storageBox = GetStorage();
    await storageBox.write(
      AppKeys.keyIsPermissionEnabled,
      _isNotificationEnable,
    );
  }

  /*  Future<void> change(bool value) async {
    if (value) {
      // User wants to ENABLE notifications
      bool permissionGranted = await AppPermissions.instance.requestNotificationPermission();

      if (permissionGranted) {
        _isNotificationEnable = true;
        log("User enabled notifications and permission granted.");
      } else {
        // Permission denied by user or system (e.g., permanently denied)
        _isNotificationEnable = false;
        log("User attempted to enable notifications, but permission was denied.");
        // Optionally, show a message or direct to settings if permanently denied
        if (await Permission.notification.isPermanentlyDenied) {
          // TODO: Direct user to app settings
          log("Notification permission is permanently denied. User must enable in settings.");
        }
      }
    } else {
      // User wants to DISABLE notifications via the toggle
      _isNotificationEnable = false;
      log("User disabled notifications via toggle.");
      // Optional: Cancel all scheduled notifications if disabling
      // await LocalNotificationServices.cancelAllNotifications(); // Implement if needed
    }

    notifyListeners(); // Update UI

    // Save the final state to SharedPreferences
    final storageBox = GetStorage();
    await storageBox.write(AppKeys.keyIsPermissionEnabled, _isNotificationEnable);
  }*/

  // --- In SettingsViewmodel ---
  Future<void> deleteAccount(BuildContext context) async {
    // 1. Show confirmation dialog
    bool confirmDelete =
        await showDialog(
          context: context,
          builder:
              (BuildContext dialogContext) => AlertDialog(
                title: const Text('Confirm Deletion'),
                content: const Text(
                  'Are you sure you want to delete your account? This action cannot be undone.',
                ),
                actions: <Widget>[
                  TextButton(
                    child: const Text('Cancel'),
                    onPressed: () {
                      Navigator.of(
                        dialogContext,
                      ).pop(false); // Dismiss dialog, return false
                    },
                  ),
                  TextButton(
                    child: const Text('Delete'),
                    onPressed: () {
                      Navigator.of(
                        dialogContext,
                      ).pop(true); // Dismiss dialog, return true
                    },
                  ),
                ],
              ),
        ) ??
        false; // Default to false if dialog is dismissed without selection

    if (!confirmDelete) {
      return; // User cancelled
    }

    // 2. Perform deletion logic
    try {
      // --- Firebase Example ---
      // Assuming you use Firebase Auth and Firestore
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // User not logged in, maybe navigate to login or show error
        throw Exception("User not logged in.");
      }

      // Delete user data from Firestore (e.g., user profile, product data)
      // You'll need to know where user-specific data is stored.
      // Example: await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
      // Example: await FirebaseFirestore.instance.collection('products').where('userId', isEqualTo: user.uid).get().then((snapshot) => snapshot.docs.forEach((doc) => doc.reference.delete()));
      // Be thorough here! Delete all associated data.

      // Delete the user account itself
      await user.delete();

      // 3. Navigate to login screen or show success message
      // Navigator.of(context).pushReplacementNamed(AppRoutes.login); // Example navigation
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account deleted successfully. Please log in again.'),
        ),
      );
      // You might need to navigate programmatically after the current build method finishes
      // or use a Navigator key. For simplicity, showing SnackBar is shown here.
    } catch (e) {
      // Handle errors (e.g., re-authentication required for deletion, network issues)
      print("Error deleting account: $e");
      String errorMessage = "Failed to delete account. Please try again.";
      if (e is FirebaseAuthException) {
        if (e.code == 'requires-recent-login') {
          errorMessage = "Please re-login to delete your account.";
          // You might want to navigate to the login screen here
        } else {
          errorMessage = e.message ?? errorMessage;
        }
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
      // Re-throw or handle as needed
      throw Exception(errorMessage);
    }
  }

  // --- In SettingsPage.dart ---
  //   ListTile(
  //   leading: const Icon(Icons.delete_forever_outlined),
  //   title: const Text('Delete My Account'),
  //   onTap: () async {
  //   // Call the ViewModel method
  //   // Make sure the ViewModel is accessible via Provider or similar
  //   final settingsProvider = Provider.of<SettingsViewmodel>(context, listen: false);
  //   try {
  //   await settingsProvider.deleteAccount(context);
  //   // If deleteAccount navigated, this part might not be reached.
  //   // If it only shows SnackBar, you might want to navigate here after success.
  //   } catch (e) {
  //   // Error is likely already shown by SnackBar in ViewModel, but you could add more UI feedback here.
  //   }
  //   },
  //   ),
}

int? _extractIdFromUri(String uri) {
  final uriSegments = uri.split('/');
  if (uriSegments.isNotEmpty) {
    final lastSegment = uriSegments.last;
    final questionMarkIndex = lastSegment.indexOf('?');
    final idString =
        questionMarkIndex != -1
            ? lastSegment.substring(0, questionMarkIndex)
            : lastSegment;
    return int.tryParse(idString);
  }
  return null;
}
