import 'dart:developer';
import 'package:audioplayers/audioplayers.dart';
import 'package:easyexpire/core/services/ringtone_services.dart';
import 'package:easyexpire/feature/settings/model/ringtone_model.dart';
import 'package:easyexpire/utils/Permissions/app_permissions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

class SettingsViewmodel extends ChangeNotifier{
  final player = AudioPlayer();
  List<RingtoneModel> ringtoneList = [];

  bool _isNotificationEnable=false;
  bool get isNotificationEnable=>_isNotificationEnable;

  void initialize()async{
    // _loadInitialPermissionState();
    loadRingtones();
  }

  Future<void> _loadInitialPermissionState() async {
    _isNotificationEnable = await AppPermissions.instance.isNotificationPermissionCurrentlyGranted();
    notifyListeners();
  }

  void loadRingtones() async {
    var ringtones = await RingtoneService.getRingtones();

    for (var toneData in ringtones) {
      // Assuming RingtoneService.getRingtones() returns a list of maps
      // that already contain 'title' and 'uri' keys.
      ringtoneList.add(RingtoneModel(
        title: toneData['title'] as String,
        path: toneData['path'] as String,
        // You might want to extract the ID here if your RingtoneService provides it directly
        id: _extractIdFromUri(toneData['path'] as String),
      ));
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
      await player.play(DeviceFileSource(path),volume: 2);
    } catch (e) {
      print("Error playing with audioplayers: $e");
    }
  }

  void change(bool val) async {
    if (val) {
      await AppPermissions.instance.requestNotificationPermission();
      _isNotificationEnable = await AppPermissions.instance.isNotificationPermissionCurrentlyGranted();

      log("PERMISSION IS :$isNotificationEnable");
    }else{
      _isNotificationEnable=false;
    }
    notifyListeners();
  }

}

int? _extractIdFromUri(String uri) {
  final uriSegments = uri.split('/');
  if (uriSegments.isNotEmpty) {
    final lastSegment = uriSegments.last;
    final questionMarkIndex = lastSegment.indexOf('?');
    final idString = questionMarkIndex != -1 ? lastSegment.substring(0, questionMarkIndex) : lastSegment;
    return int.tryParse(idString);
  }
  return null;
}