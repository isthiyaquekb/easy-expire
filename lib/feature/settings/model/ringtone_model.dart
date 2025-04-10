class RingtoneModel {
  final String title;
  final String path;
  final int? id; // Extracted from the URI

  RingtoneModel({required this.title, required this.path, this.id});

  // Factory constructor to create a RingtoneModel object from the log format
  factory RingtoneModel.fromLog(String logLine) {
    // Extract the relevant part of the log line
    final startIndex = logLine.indexOf("Ringtone: ");
    if (startIndex == -1) {
      throw FormatException("Invalid log line format: '$logLine'");
    }
    final ringtoneData = logLine.substring(startIndex + "Ringtone: ".length);

    // Split the title and URI
    final parts = ringtoneData.split(" - ");
    if (parts.length != 2) {
      throw FormatException("Invalid ringtone data format: '$ringtoneData'");
    }
    final titlePart = parts[0];
    final uriPart = parts[1];

    // Extract the title from the URI parameters
    final uriParamsStart = uriPart.indexOf("?");
    String? extractedTitle;
    String uriWithoutParams = uriPart;
    if (uriParamsStart != -1) {
      uriWithoutParams = uriPart.substring(0, uriParamsStart);
      final paramsString = uriPart.substring(uriParamsStart + 1);
      final params = Uri.splitQueryString(paramsString);
      extractedTitle = params['title'];
    }

    // Extract the ID from the URI
    int? extractedId;
    final uriSegments = uriWithoutParams.split('/');
    if (uriSegments.isNotEmpty) {
      final lastSegment = uriSegments.last;
      extractedId = int.tryParse(lastSegment);
    }

    return RingtoneModel(
      title: extractedTitle ?? titlePart.trim(), // Use extracted title if available, otherwise the part before " - "
      path: uriPart.trim(),
      id: extractedId,
    );
  }

  // Optional: Method to convert Ringtone object back to a similar log string
  String toLogString() {
    return "Ringtone: $title - $path";
  }

  @override
  String toString() {
    return 'RingtoneModel(title: $title, uri: $path, id: $id)';
  }
}