import 'package:flutter/services.dart';

class RingtoneService {
  static const MethodChannel _channel = MethodChannel('ringtone_channel');

  // Fetch ringtone list
  static Future<List<dynamic>> getRingtones() async {
    final List<dynamic> ringtones = await _channel.invokeMethod('getRingtones');
    return ringtones;
  }
}
