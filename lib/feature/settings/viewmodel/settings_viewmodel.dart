import 'dart:developer';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easyexpire/core/constant/app_keys.dart';
import 'package:easyexpire/core/constant/app_routes.dart';
import 'package:easyexpire/core/services/ringtone_services.dart';
import 'package:easyexpire/feature/settings/model/ringtone_model.dart';
import 'package:easyexpire/utils/Permissions/app_permissions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

class SettingsViewmodel extends ChangeNotifier {
  AudioPlayer? _player;
  FirebaseFirestore? _firestore;
  FirebaseAuth? _auth;

  SettingsViewmodel({
    AudioPlayer? player,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _player = player,
       _firestore = firestore,
       _auth = auth;

  AudioPlayer get player => _player ??= AudioPlayer();
  FirebaseFirestore get firestore => _firestore ??= FirebaseFirestore.instance;
  FirebaseAuth get auth => _auth ??= FirebaseAuth.instance;

  List<RingtoneModel> ringtoneList = [];

  bool _isNotificationEnable = false;
  bool get isNotificationEnable => _isNotificationEnable;

  int _leadDays = 3;
  int get leadDays => _leadDays;

  String _selectedRingtone = 'Default (System)';
  String get selectedRingtone => _selectedRingtone;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void initialize() async {
    _loadInitialPermissionState();
    _loadPreferences();
    loadRingtones();
  }

  Future<void> _loadInitialPermissionState() async {
    _isNotificationEnable =
        await AppPermissions.instance
            .isNotificationPermissionCurrentlyGranted();
    notifyListeners();
  }

  void _loadPreferences() {
    final storage = GetStorage();
    _leadDays = storage.read<int>(AppKeys.keyLeadDays) ?? 3;
    _selectedRingtone =
        storage.read<String>(AppKeys.keySelectedRingtone) ?? 'Default (System)';
    notifyListeners();
  }

  Future<void> setLeadDays(int days) async {
    _leadDays = days;
    notifyListeners();
    final storage = GetStorage();
    await storage.write(AppKeys.keyLeadDays, days);
  }

  Future<void> selectRingtone(RingtoneModel tone) async {
    _selectedRingtone = tone.title;
    notifyListeners();
    final storage = GetStorage();
    await storage.write(AppKeys.keySelectedRingtone, tone.title);
  }

  Future<void> loadRingtones() async {
    try {
      final ringtones = await RingtoneService.getRingtones();
      ringtoneList.clear();

      for (var toneData in ringtones) {
        ringtoneList.add(
          RingtoneModel(
            title: toneData['title'] as String? ?? 'Tone',
            path: toneData['path'] as String? ?? '',
            id: _extractIdFromUri(toneData['path'] as String? ?? ''),
          ),
        );
      }
    } catch (e) {
      log("Platform ringtone load failed, using standard sound options: $e");
      // Provide built-in ringtone presets if system channel is unavailable
      ringtoneList = [
        RingtoneModel(title: 'Default (System)', path: 'default', id: 1),
        RingtoneModel(title: 'Chime Bell', path: 'chime', id: 2),
        RingtoneModel(title: 'Pulse Alert', path: 'pulse', id: 3),
        RingtoneModel(title: 'Gentle Ping', path: 'ping', id: 4),
        RingtoneModel(title: 'Urgent Alarm', path: 'alarm', id: 5),
      ];
    }
    notifyListeners();
  }

  void playSound(String path) async {
    log("Playing preview sound: $path");
    try {
      if (path.isNotEmpty && !path.startsWith('http')) {
        await player.play(DeviceFileSource(path), volume: 1.0);
      }
    } catch (e) {
      log("Error playing audio: $e");
    }
  }

  void change(bool val) async {
    if (val) {
      bool permissionGranted =
          await AppPermissions.instance.requestNotificationPermission();
      _isNotificationEnable = permissionGranted;
    } else {
      _isNotificationEnable = false;
    }
    notifyListeners();
    final storageBox = GetStorage();
    await storageBox.write(
      AppKeys.keyIsPermissionEnabled,
      _isNotificationEnable,
    );
  }

  Future<void> submitFeedback({
    required String type,
    required String title,
    required String description,
    int? rating,
  }) async {
    final user = auth.currentUser;
    final payload = {
      'userId': user?.uid ?? 'anonymous',
      'userEmail': user?.email ?? '',
      'type': type,
      'title': title,
      'description': description,
      if (rating != null) 'rating': rating,
      'createdAt': FieldValue.serverTimestamp(),
      'appVersion': '1.0.0',
    };

    try {
      await firestore.collection('feedback').add(payload);
      log("Feedback submitted successfully: $payload");
    } catch (e) {
      log("Error submitting feedback to Firestore: $e");
      // Even if Firestore fails (e.g. offline), we complete gracefully
    }
  }

  Future<void> deleteAccount(BuildContext context) async {
    final confirmDelete =
        await showDialog<bool>(
          context: context,
          builder:
              (dialogContext) => AlertDialog(
                title: const Text('Delete Account?'),
                content: const Text(
                  'Are you sure you want to permanently delete your account? All inventory data, notifications, and store settings will be irrecoverably lost.',
                ),
                actions: <Widget>[
                  TextButton(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Delete Permanently'),
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                  ),
                ],
              ),
        ) ??
        false;

    if (!confirmDelete || !context.mounted) {
      return;
    }

    final user = auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No authenticated user found.")),
      );
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      await _executeAccountDeletion(context, user);
    } on FirebaseAuthException catch (e) {
      log("FirebaseAuthException during deletion: ${e.code}");
      if (e.code == 'requires-recent-login') {
        _isLoading = false;
        notifyListeners();

        // Prompt for password re-authentication
        final reauthSuccess = await _promptPasswordReauth(context, user);
        if (reauthSuccess && context.mounted) {
          _isLoading = true;
          notifyListeners();
          try {
            await _executeAccountDeletion(context, user);
          } catch (retryError) {
            log("Error retrying deletion: $retryError");
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to delete account: $retryError'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.message ?? 'Failed to delete account.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      log("Error during account deletion: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete account: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _executeAccountDeletion(BuildContext context, User user) async {
    final uid = user.uid;

    // 1. Cascade delete products
    final productsSnapshot =
        await firestore
            .collection('products')
            .where('userId', isEqualTo: uid)
            .get();
    final batch = firestore.batch();
    for (var doc in productsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // 2. Cascade delete notifications
    final notificationsSnapshot =
        await firestore
            .collection('notifications')
            .where('recipientId', isEqualTo: uid)
            .get();
    for (var doc in notificationsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // 3. Delete user profile doc
    final userDocRef = firestore.collection('users').doc(uid);
    batch.delete(userDocRef);

    await batch.commit();

    // 4. Delete Auth user
    await user.delete();

    // 5. Clear local storage
    final storage = GetStorage();
    await storage.erase();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account deleted successfully.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
    }
  }

  Future<bool> _promptPasswordReauth(BuildContext context, User user) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _ReauthPasswordDialog(user: user),
    );
    return result ?? false;
  }
}

class _ReauthPasswordDialog extends StatefulWidget {
  final User user;
  const _ReauthPasswordDialog({required this.user});

  @override
  State<_ReauthPasswordDialog> createState() => _ReauthPasswordDialogState();
}

class _ReauthPasswordDialogState extends State<_ReauthPasswordDialog> {
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirm Password'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'For security, please enter your password to proceed with deleting your account.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                border: const OutlineInputBorder(),
                errorText: _errorMessage,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          onPressed: _isSubmitting ? null : _verifyAndProceed,
          child:
              _isSubmitting
                  ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                  : const Text('Verify & Delete'),
        ),
      ],
    );
  }

  Future<void> _verifyAndProceed() async {
    final password = _passwordController.text.trim();
    if (password.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your password';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final email = widget.user.email;
      if (email != null && email.isNotEmpty) {
        final credential = EmailAuthProvider.credential(
          email: email,
          password: password,
        );
        await widget.user.reauthenticateWithCredential(credential);
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
            _errorMessage = 'No email associated with user.';
          });
        }
      }
    } catch (reauthErr) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage =
              reauthErr is FirebaseAuthException
                  ? (reauthErr.message ?? 'Authentication failed')
                  : 'Incorrect password';
        });
      }
    }
  }
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
