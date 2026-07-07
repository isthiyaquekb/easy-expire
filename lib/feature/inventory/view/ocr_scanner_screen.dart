import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:easyexpire/core/utils/ocr_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:permission_handler/permission_handler.dart';

/// Number of consecutive recognition passes with the same result
/// before we accept it as a stable detection.
const int _kStabilityThreshold = 2;

/// How often (milliseconds) we run text recognition on a frame.
const int _kRecognitionIntervalMs = 500;

/// Seconds before we show the "try better lighting" hint.
const int _kTimeoutSeconds = 10;

class OcrScannerScreen extends StatefulWidget {
  const OcrScannerScreen({super.key});

  @override
  State<OcrScannerScreen> createState() => _OcrScannerScreenState();
}

class _OcrScannerScreenState extends State<OcrScannerScreen>
    with WidgetsBindingObserver {
  // ── Camera ──────────────────────────────────────────────────────────────
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;

  // ── ML Kit ──────────────────────────────────────────────────────────────
  final TextRecognizer _textRecognizer = TextRecognizer();

  // ── State ───────────────────────────────────────────────────────────────
  bool _isInitializing = true;
  bool _permissionDenied = false;
  bool _isProcessing = false; // throttle flag for the recognition loop
  bool _hasPopped = false; // guard against double-pop
  bool _disposed = false; // set true the instant dispose() begins

  // Stability tracking
  OcrParseResult? _lastResult;
  int _stableCount = 0;
  bool _isSuccess = false;

  // Accumulate the best result seen across the current stability window,
  // so a slightly-worse final frame doesn't discard a good earlier match.
  OcrParseResult? _bestResultInWindow;

  // Timeout
  Timer? _timeoutTimer;
  bool _timedOut = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      _stopImageStream().then((_) {
        if (!_disposed) controller.dispose();
      });
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  // ── Camera setup ────────────────────────────────────────────────────────

  Future<void> _initCamera() async {
    if (_disposed) return;
    setState(() {
      _isInitializing = true;
      _permissionDenied = false;
    });

    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted && !_disposed) {
        setState(() {
          _isInitializing = false;
          _permissionDenied = true;
        });
      }
      return;
    }

    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        if (mounted && !_disposed) setState(() => _isInitializing = false);
        return;
      }

      final backCamera = _cameras!.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      final controller = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      _cameraController = controller;
      await controller.initialize();

      if (!mounted || _disposed) {
        await controller.dispose();
        return;
      }

      setState(() => _isInitializing = false);
      _startImageStream();
      _startTimeoutTimer();
    } catch (e) {
      log('OcrScannerScreen: camera init error: $e');
      if (mounted && !_disposed) setState(() => _isInitializing = false);
    }
  }

  void _startImageStream() {
    if (_disposed) return;
    _cameraController?.startImageStream(_onCameraImage);
  }

  Future<void> _stopImageStream() async {
    try {
      final controller = _cameraController;
      if (controller != null &&
          controller.value.isInitialized &&
          controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
    } on CameraException catch (e) {
      log('OcrScannerScreen: Ignored CameraException stopping stream: ${e.code}');
    } catch (e) {
      log('OcrScannerScreen: Error stopping image stream: $e');
    }
  }

  // ── Recognition loop ────────────────────────────────────────────────────

  void _onCameraImage(CameraImage image) {
    if (_disposed || _isProcessing || _hasPopped) return;
    _isProcessing = true;
    _recognizeText(image).then((_) {
      Future.delayed(
        const Duration(milliseconds: _kRecognitionIntervalMs),
            () {
          if (mounted && !_disposed) _isProcessing = false;
        },
      );
    });
  }

  Future<void> _recognizeText(CameraImage image) async {
    try {
      final inputImage = _cameraImageToInputImage(image);
      if (inputImage == null) return;

      final recognizedText = await _textRecognizer.processImage(inputImage);
      if (!mounted || _hasPopped || _disposed) return;

      log('OcrScannerScreen: recognized: ${recognizedText.text}');

      if (recognizedText.text.trim().isEmpty) {
        _resetStability();
        return;
      }

      final currentResult = OcrParser.parse(recognizedText);
      log('OcrScannerScreen: Parsed current result: $currentResult');

      // Keep the best result seen in this window: prefer spatial matches
      // over fallback ones, and prefer filling in a field over a null one.
      if (currentResult.hasAnyResult) {
        final betterExpiry = currentResult.expiryDate != null &&
            (_bestResultInWindow?.expiryDate == null ||
                (currentResult.expirySource == OcrFieldSource.spatial &&
                    _bestResultInWindow?.expirySource !=
                        OcrFieldSource.spatial));
        final betterBatch = currentResult.batchNumber != null &&
            (_bestResultInWindow?.batchNumber == null ||
                (currentResult.batchSource == OcrFieldSource.spatial &&
                    _bestResultInWindow?.batchSource !=
                        OcrFieldSource.spatial));

        if (_bestResultInWindow == null || betterExpiry || betterBatch) {
          _bestResultInWindow = OcrParseResult(
            expiryDate: currentResult.expiryDate ?? _bestResultInWindow?.expiryDate,
            expirySource: currentResult.expiryDate != null
                ? currentResult.expirySource
                : _bestResultInWindow?.expirySource,
            batchNumber: currentResult.batchNumber ?? _bestResultInWindow?.batchNumber,
            batchSource: currentResult.batchNumber != null
                ? currentResult.batchSource
                : _bestResultInWindow?.batchSource,
          );
          log('OcrScannerScreen: Accumulated best-in-window: $_bestResultInWindow');
        }
      }

      if (!currentResult.hasAnyResult) {
        _resetStability();
        return;
      }

      if (_lastResult != null && currentResult.matchesFor(_lastResult!)) {
        if (mounted && !_disposed) setState(() => _stableCount++);
        _resetTimeout();
      } else {
        if (mounted && !_disposed) {
          setState(() {
            _lastResult = currentResult;
            _stableCount = 1;
            _timedOut = false;
          });
        }
        _resetTimeout();
      }

      if (_stableCount >= _kStabilityThreshold) {
        _onStableResult(_bestResultInWindow ?? currentResult);
      }
    } catch (e) {
      log('OcrScannerScreen: recognition error: $e');
    }
  }

  /// Converts a [CameraImage] from the stream to the [InputImage] format
  /// expected by ML Kit.
  InputImage? _cameraImageToInputImage(CameraImage image) {
    final camera = _cameraController?.description;
    if (camera == null) return null;

    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else {
      var rotationCompensation =
      _orientationOffset[_cameraController!.value.deviceOrientation];
      if (rotationCompensation == null) return null;
      if (camera.lensDirection == CameraLensDirection.front) {
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) {
      return null;
    }

    if (image.planes.length != 1) return null;
    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  static const Map<DeviceOrientation, int> _orientationOffset = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  // ── Stability helpers ───────────────────────────────────────────────────

  void _resetStability() {
    if (mounted && !_disposed) {
      setState(() {
        _stableCount = 0;
        _lastResult = null;
        _bestResultInWindow = null;
      });
    }
  }

  Future<void> _onStableResult(OcrParseResult result) async {
    if (_hasPopped || _disposed) return;
    _hasPopped = true;
    _cancelTimeoutTimer();

    await _stopImageStream();

    if (mounted && !_disposed) setState(() => _isSuccess = true);

    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted && !_disposed) {
      Navigator.of(context).pop(result);
    }
  }

  // ── Timeout ─────────────────────────────────────────────────────────────

  void _startTimeoutTimer() {
    _cancelTimeoutTimer();
    _timeoutTimer = Timer(Duration(seconds: _kTimeoutSeconds), () {
      if (!mounted || _hasPopped || _disposed) return;
      setState(() => _timedOut = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'No text detected. Try better lighting or hold the camera closer.',
          ),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: _retryDetection,
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    });
  }

  void _resetTimeout() {
    if (_timedOut) return;
    _cancelTimeoutTimer();
    _startTimeoutTimer();
  }

  void _cancelTimeoutTimer() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
  }

  void _retryDetection() {
    if (!mounted || _disposed) return;
    setState(() {
      _stableCount = 0;
      _lastResult = null;
      _bestResultInWindow = null;
      _timedOut = false;
    });
    _startTimeoutTimer();
  }

  // ── Dispose ─────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _cancelTimeoutTimer();

    _stopImageStream().then((_) {
      try {
        _cameraController?.dispose();
      } catch (e) {
        log('OcrScannerScreen: Error disposing camera controller: $e');
      }
    });

    _textRecognizer.close();
    super.dispose();
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan Package'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0.5,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_permissionDenied) {
      return _buildPermissionDeniedView();
    }
    if (_isInitializing ||
        _cameraController == null ||
        !_cameraController!.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(_cameraController!),
        _ScanOverlay(isSuccess: _isSuccess),
        Positioned(
          bottom: 60,
          left: 0,
          right: 0,
          child: _buildStatusIndicator(),
        ),
      ],
    );
  }

  Widget _buildStatusIndicator() {
    if (_isSuccess) {
      return const _StatusBadge(
        icon: Icons.check_circle_outline_rounded,
        label: 'Detected!',
        color: Colors.green,
      );
    }

    if (_stableCount > 0) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              value: _stableCount / _kStabilityThreshold,
              strokeWidth: 3,
              color: Colors.white,
              backgroundColor: Colors.white24,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Hold steady… ($_stableCount/$_kStabilityThreshold)',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
            ),
          ),
        ],
      );
    }

    if (_timedOut) {
      return const _StatusBadge(
        icon: Icons.lightbulb_outline_rounded,
        label: 'Too dark or too far. Try better lighting.',
        color: Colors.orange,
      );
    }

    return const Text(
      'Point at batch / expiry info on the packaging',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.white70,
        fontSize: 14,
        shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
      ),
    );
  }

  Widget _buildPermissionDeniedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.no_photography_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Camera permission required',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Please grant camera access in Settings to use the OCR scanner.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () async {
                await openAppSettings();
                if (mounted) Navigator.of(context).pop();
              },
              child: const Text('Open Settings'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Supporting widgets ──────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatusBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 40),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 17,
            fontWeight: FontWeight.bold,
            shadows: const [Shadow(blurRadius: 4, color: Colors.black54)],
          ),
        ),
      ],
    );
  }
}

/// Darkened overlay with a transparent rectangular cut-out to guide the user.
///
/// Sized as a fraction of the screen rather than fixed pixels, so it scales
/// sensibly across phone sizes: wide enough to fit a full product label,
/// tall enough to capture a couple of lines of batch/expiry text at once.
class _ScanOverlay extends StatelessWidget {
  final bool isSuccess;

  const _ScanOverlay({required this.isSuccess});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _OverlayPainter(isSuccess: isSuccess),
      child: const SizedBox.expand(),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  final bool isSuccess;

  const _OverlayPainter({required this.isSuccess});

  @override
  void paint(Canvas canvas, Size size) {
    final dimPaint = Paint()..color = Colors.black.withValues(alpha: 0.55);

    // Bigger viewfinder: ~90% of width, ~38% of height, centered slightly
    // above vertical middle so it's comfortable to hold at chest height.
    const double hPadFraction = 0.05;
    const double heightFraction = 0.38;
    final double hPad = size.width * hPadFraction;
    final double height = size.height * heightFraction;
    final double top = size.height * 0.28;

    final rect = Rect.fromLTWH(hPad, top, size.width - hPad * 2, height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(16));

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(rrect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, dimPaint);

    final borderPaint = Paint()
      ..color = isSuccess ? Colors.greenAccent : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRRect(rrect, borderPaint);

    // Corner accents for a more "scanner-like" feel.
    final cornerPaint = Paint()
      ..color = isSuccess ? Colors.greenAccent : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    const double cornerLen = 24;

    void drawCorner(Offset origin, Offset dx, Offset dy) {
      canvas.drawLine(origin, origin + dx, cornerPaint);
      canvas.drawLine(origin, origin + dy, cornerPaint);
    }

    drawCorner(rect.topLeft, const Offset(cornerLen, 0), const Offset(0, cornerLen));
    drawCorner(rect.topRight, const Offset(-cornerLen, 0), const Offset(0, cornerLen));
    drawCorner(rect.bottomLeft, const Offset(cornerLen, 0), const Offset(0, -cornerLen));
    drawCorner(rect.bottomRight, const Offset(-cornerLen, 0), const Offset(0, -cornerLen));
  }

  @override
  bool shouldRepaint(_OverlayPainter oldDelegate) =>
      oldDelegate.isSuccess != isSuccess;
}