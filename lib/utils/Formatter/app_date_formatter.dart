import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AppDateFormatter{
  AppDateFormatter._();

  static String formatDateTime(DateTime dateTime) {
    final DateFormat formatter = DateFormat("yyyy-MM-ddTHH:mm:ss.SSS'Z'");
    return formatter.format(dateTime.toLocal());
  }

  static String formatDDYYMM(DateTime dateTime) {
    final DateFormat formatter = DateFormat("dd-MM-yyyy");
    return formatter.format(dateTime.toLocal());
  }

  static String formatDDMMYYYYHHmm(String isoDate){
    // Parse the ISO 8601 date string to a DateTime object
    DateTime dateTime = DateTime.parse(isoDate);

    // Define the desired format
    final DateFormat formatter = DateFormat('d.M.yyyy; HH:mm');

    // Format the DateTime object
    return formatter.format(dateTime);
  }

  ///DATE TIME FROM EPOCH DATETIME
  static String fromEpochDateTime(int millisecondsSinceEpoch) {
    // Create a DateTime object from the milliseconds since epoch
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch, isUtc: true).toLocal();

    // Define the desired format
    final DateFormat formatter = DateFormat('d MMMM yyyy - HH:mm a', 'es_ES'); // Spanish locale

    // Format the DateTime object
    return formatter.format(dateTime);
  }

  static String dateTimeFromFirebase(Timestamp timestamp){
    DateTime firebaseDate = timestamp.toDate();
    // Format the date as "dd-MM-yyyy"
    String formattedDate = DateFormat('dd-MM-yyyy').format(firebaseDate);
    return formattedDate;
  }


  static Timestamp firebaseTimestampFormatter(String dateTimeString) {
    try {
      DateTime dateTime = DateTime.parse(dateTimeString);
      return Timestamp.fromDate(dateTime);
    } catch (e) {
      print('Error parsing DateTime: $e');
      return Timestamp.now(); // or handle the error appropriately
    }
  }

  DateTime convertTimestampToDateTime(Timestamp timestamp) {
    return timestamp.toDate();
  }
}