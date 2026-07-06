import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  bool _isDetecting = false; // Flag to prevent multiple pops

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0.5,
      ),
      body: MobileScanner(
        controller: MobileScannerController(
          detectionSpeed: DetectionSpeed.normal, // Adjust as needed
          facing: CameraFacing.back,
        ),
        onDetect: (capture) {
          if (_isDetecting) return; // Ignore if already processing a detection

          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            final barcode = barcodes.first;

            if (barcode.rawValue != null) {
              setState(() {
                _isDetecting = true; // Set flag before popping
              });
              Navigator.of(context).pop(barcode.rawValue);
            } else {
              // Only show snackbar and pop if not already detecting
              setState(() {
                _isDetecting = true; // Set flag before popping
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No valid barcode data found.')),
              );
              Navigator.of(context).pop(); // Go back without data
            }
          }
        },
      ),
    );
  }
}
