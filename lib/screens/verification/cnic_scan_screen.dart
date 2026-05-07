import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:***REMOVED***/config/theme.dart';
import 'package:***REMOVED***/screens/verification/liveness_screen.dart';

class CnicScanScreen extends StatefulWidget {
  const CnicScanScreen({super.key});

  @override
  State<CnicScanScreen> createState() => _CnicScanScreenState();
}

class _CnicScanScreenState extends State<CnicScanScreen> {
  CameraController? _cameraController;
  final TextRecognizer _textRecognizer = TextRecognizer();
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  bool _cnicFound = false;
  
  // Extracted Data
  String _cnicNumber = '';
  String _dateOfBirth = '';
  String _issueDate = '';
  String _expiryDate = '';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      firstCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _cameraController!.initialize();
    if (!mounted) return;

    setState(() {
      _isCameraInitialized = true;
    });

    _cameraController!.startImageStream(_processImageStream);
  }

  void _processImageStream(CameraImage image) async {
    if (_isProcessing || _cnicFound) return;
    _isProcessing = true;

    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());
      final camera = _cameraController!.description;
      final imageRotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation) ?? InputImageRotation.rotation0deg;

      final inputImageFormat = InputImageFormatValue.fromRawValue(image.format.raw) ?? InputImageFormat.nv21;

      final inputImageData = InputImageMetadata(
        size: imageSize,
        rotation: imageRotation,
        format: inputImageFormat,
        bytesPerRow: image.planes[0].bytesPerRow,
      );

      final inputImage = InputImage.fromBytes(bytes: bytes, metadata: inputImageData);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

      _extractCnicData(recognizedText.text);
    } catch (e) {
      print('Error processing image: $e');
    } finally {
      _isProcessing = false;
    }
  }

  void _extractCnicData(String text) {
    // Basic CNIC Regex: 5 digits, hyphen, 7 digits, hyphen, 1 digit
    final RegExp cnicRegExp = RegExp(r'\b\d{5}-\d{7}-\d{1}\b');
    final match = cnicRegExp.firstMatch(text);

    if (match != null) {
      _cnicNumber = match.group(0)!;
      
      // Try to extract DOB (very basic pattern matching)
      final RegExp dobRegExp = RegExp(r'\b(DOB|Date of Birth)[\s:]*([\d]{2}[\.\/-][\d]{2}[\.\/-][\d]{4})\b', caseSensitive: false);
      final dobMatch = dobRegExp.firstMatch(text);
      if (dobMatch != null && dobMatch.groupCount >= 2) {
        _dateOfBirth = dobMatch.group(2)!;
      }

      setState(() {
        _cnicFound = true;
      });
      _captureAndProceed();
    }
  }

  Future<void> _captureAndProceed() async {
    await _cameraController!.stopImageStream();
    final XFile picture = await _cameraController!.takePicture();
    
    if (!mounted) return;
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LivenessScreen(
          cnicImageFile: File(picture.path),
          cnicNumber: _cnicNumber,
          dateOfBirth: _dateOfBirth,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan CNIC', style: TextStyle(color: Colors.white)),
        backgroundColor: MadadgarTheme.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isCameraInitialized
          ? Stack(
              children: [
                Positioned.fill(
                  child: CameraPreview(_cameraController!),
                ),
                // Overlay for CNIC frame
                Positioned.fill(
                  child: CustomPaint(
                    painter: CnicOverlayPainter(),
                  ),
                ),
                const Positioned(
                  top: 50,
                  left: 0,
                  right: 0,
                  child: Text(
                    'Position your CNIC within the frame',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(color: Colors.black, blurRadius: 4),
                      ],
                    ),
                  ),
                ),
                if (_cnicFound)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black54,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: MadadgarTheme.primaryColor,
                        ),
                      ),
                    ),
                  ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}

class CnicOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black54;
    
    final double cardWidth = size.width * 0.9;
    final double cardHeight = cardWidth * 0.63; // Standard ID card ratio
    
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: cardWidth,
      height: cardHeight,
    );

    // Draw dark overlay everywhere EXCEPT the card rect
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(12))),
      ),
      paint,
    );

    // Draw border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(12)),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
