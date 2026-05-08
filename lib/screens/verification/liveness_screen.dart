import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:madadgar/config/theme.dart';
import 'package:madadgar/screens/verification/verification_summary_screen.dart';

class LivenessScreen extends StatefulWidget {
  final File cnicImageFile;
  final String cnicNumber;
  final String dateOfBirth;

  const LivenessScreen({
    super.key,
    required this.cnicImageFile,
    required this.cnicNumber,
    required this.dateOfBirth,
  });

  @override
  State<LivenessScreen> createState() => _LivenessScreenState();
}

class _LivenessScreenState extends State<LivenessScreen> {
  CameraController? _cameraController;
  late final FaceDetector _faceDetector;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  bool _livenessPassed = false;
  
  // Liveness state tracking
  bool _eyesClosedOnce = false;

  @override
  void initState() {
    super.initState();
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true, // Need this for blink detection
        enableLandmarks: true,
        performanceMode: FaceDetectorMode.fast,
      ),
    );
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      frontCamera,
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
    if (_isProcessing || _livenessPassed) return;
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
      final List<Face> faces = await _faceDetector.processImage(inputImage);

      _checkLiveness(faces);
    } catch (e) {
      print('Error processing face image: $e');
    } finally {
      _isProcessing = false;
    }
  }

  void _checkLiveness(List<Face> faces) {
    if (faces.isEmpty) return;
    
    // Assume the largest face is the target
    final face = faces.first;
    
    // Check blink probability
    if (face.leftEyeOpenProbability != null && face.rightEyeOpenProbability != null) {
      final leftOpen = face.leftEyeOpenProbability!;
      final rightOpen = face.rightEyeOpenProbability!;
      
      // If both eyes are closed (probability < 0.2)
      if (leftOpen < 0.2 && rightOpen < 0.2) {
        _eyesClosedOnce = true;
      }
      
      // If eyes are opened again after being closed
      if (_eyesClosedOnce && leftOpen > 0.8 && rightOpen > 0.8) {
        setState(() {
          _livenessPassed = true;
        });
        _captureAndProceed();
      }
    }
  }

  Future<void> _captureAndProceed() async {
    await _cameraController!.stopImageStream();
    final XFile picture = await _cameraController!.takePicture();
    
    if (!mounted) return;
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => VerificationSummaryScreen(
          cnicImageFile: widget.cnicImageFile,
          faceImageFile: File(picture.path),
          cnicNumber: widget.cnicNumber,
          dateOfBirth: widget.dateOfBirth,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liveness Check', style: TextStyle(color: Colors.white)),
        backgroundColor: MadadgarTheme.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isCameraInitialized
          ? Stack(
              children: [
                Positioned.fill(
                  child: CameraPreview(_cameraController!),
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: FaceOverlayPainter(),
                  ),
                ),
                Positioned(
                  top: 50,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      const Text(
                        'Position your face in the oval',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _eyesClosedOnce ? 'Great! Now open your eyes' : 'Please blink your eyes',
                        style: const TextStyle(
                          color: Colors.yellowAccent,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_livenessPassed)
                  Positioned.fill(
                    child: Container(
                      color: Colors.green.withOpacity(0.5),
                      child: const Center(
                        child: Icon(Icons.check_circle, color: Colors.white, size: 80),
                      ),
                    ),
                  ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}

class FaceOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black54;
    
    final double ovalWidth = size.width * 0.7;
    final double ovalHeight = ovalWidth * 1.3;
    
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: ovalWidth,
      height: ovalHeight,
    );

    // Draw dark overlay everywhere EXCEPT the oval
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()..addOval(rect),
      ),
      paint,
    );

    // Draw border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    
    canvas.drawOval(rect, borderPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
