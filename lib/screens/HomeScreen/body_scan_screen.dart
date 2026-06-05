import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:permission_handler/permission_handler.dart';

class BodyScanScreen extends StatefulWidget {
  final double heightCm;
  final String gender;

  const BodyScanScreen({
    super.key,
    required this.heightCm,
    required this.gender,
  });

  @override
  State<BodyScanScreen> createState() => _BodyScanScreenState();
}

class _BodyScanScreenState extends State<BodyScanScreen> {
  CameraController? _cameraController;
  late PoseDetector _poseDetector;

  bool _isLoading = true;
  bool _isProcessing = false;

  String _status =
      'Stand straight and make sure your full body is inside the frame.';

  @override
  void initState() {
    super.initState();

    _poseDetector = PoseDetector(
      options: PoseDetectorOptions(
        mode: PoseDetectionMode.single,
        model: PoseDetectionModel.accurate,
      ),
    );

    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final permission = await Permission.camera.request();

      if (!permission.isGranted) {
        setState(() {
          _isLoading = false;
          _status = 'Camera permission is required to start body scan.';
        });
        return;
      }

      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        setState(() {
          _isLoading = false;
          _status = 'No camera found on this device.';
        });
        return;
      }

      final camera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isLoading = false;
          _status =
              'Stand 2 meters away, keep your body straight, then tap Start Scan.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _status = 'Camera error: $e';
        });
      }
    }
  }

  Future<void> _captureAndAnalyze() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isProcessing) {
      return;
    }

    setState(() {
      _isProcessing = true;
      _status = 'Scanning your body...';
    });

    try {
      final image = await _cameraController!.takePicture();
      final inputImage = InputImage.fromFilePath(image.path);

      final poses = await _poseDetector.processImage(inputImage);

      if (poses.isEmpty) {
        setState(() {
          _isProcessing = false;
          _status =
              'No body detected. Make sure your full body appears in the camera.';
        });
        return;
      }

      final result = _estimateMeasurementsFromPose(poses.first);

      if (result == null) {
        setState(() {
          _isProcessing = false;
          _status =
              'Body landmarks are not clear. Stand straight and try again.';
        });
        return;
      }

      if (mounted) {
        Navigator.pop(context, result);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _status = 'Scan failed: $e';
        });
      }
    }
  }

  Map<String, double>? _estimateMeasurementsFromPose(Pose pose) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];

    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];

    final nose = pose.landmarks[PoseLandmarkType.nose];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];

    if (leftShoulder == null ||
        rightShoulder == null ||
        leftHip == null ||
        rightHip == null ||
        nose == null ||
        leftAnkle == null ||
        rightAnkle == null) {
      return null;
    }

    final ankleY = (leftAnkle.y + rightAnkle.y) / 2;
    final bodyHeightPixels = (ankleY - nose.y).abs();

    if (bodyHeightPixels <= 0) return null;

    final cmPerPixel = widget.heightCm / bodyHeightPixels;

    final shoulderWidthPixels = (leftShoulder.x - rightShoulder.x).abs();
    final hipWidthPixels = (leftHip.x - rightHip.x).abs();

    final shoulderWidthCm = shoulderWidthPixels * cmPerPixel;
    final hipWidthCm = hipWidthPixels * cmPerPixel;

    final chest = shoulderWidthCm * 2.25;
    final hips = hipWidthCm * 2.35;

    final waistRatio = widget.gender == 'male' ? 0.88 : 0.76;
    final waist = hips * waistRatio;

    return {
      'chest': chest,
      'waist': waist,
      'hips': hips,
    };
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _poseDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('AI Body Scan'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Stack(
              children: [
                Positioned.fill(
                  child: _cameraController != null &&
                          _cameraController!.value.isInitialized
                      ? CameraPreview(_cameraController!)
                      : Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              _status,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                ),

                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: BodyFramePainter(),
                    ),
                  ),
                ),

                Positioned(
                  left: 20,
                  right: 20,
                  top: 24,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Text(
                      'For better results:\nWear fitted clothes • Stand straight • Show full body',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        height: 1.4,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),

                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 120,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      _status,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),

                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 40,
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _captureAndAnalyze,
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.camera_alt),
                    label: Text(
                      _isProcessing ? 'Scanning...' : 'Start Scan',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class BodyFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final outlinePaint = Paint()
      ..color = Colors.white.withOpacity(0.88)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final guidePaint = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;

    final centerX = size.width / 2;

    // Main vertical positions
    final topY = size.height * 0.17;

    // Head
    final headRadius = size.width * 0.075;
    final headCenter = Offset(centerX, topY + headRadius);
    canvas.drawCircle(headCenter, headRadius, outlinePaint);

    // Body points
    final shoulderY = topY + headRadius * 2 + 18;
    final chestY = size.height * 0.36;
    final waistY = size.height * 0.49;
    final hipY = size.height * 0.64;
    final kneeY = size.height * 0.76;
    final bottomY = size.height * 0.84;

    // Widths
    final shoulderHalfWidth = size.width * 0.185;
    final chestHalfWidth = size.width * 0.175;
    final waistHalfWidth = size.width * 0.145;
    final hipHalfWidth = size.width * 0.18;
    final ankleHalfWidth = size.width * 0.105;

    final path = Path();

    // Start from left shoulder
    path.moveTo(centerX - shoulderHalfWidth, shoulderY);

    // Left upper body: shoulder to chest
    path.quadraticBezierTo(
      centerX - shoulderHalfWidth - 4,
      (shoulderY + chestY) / 2,
      centerX - chestHalfWidth,
      chestY,
    );

    // Left chest to waist
    path.quadraticBezierTo(
      centerX - chestHalfWidth + 4,
      (chestY + waistY) / 2,
      centerX - waistHalfWidth,
      waistY,
    );

    // Left waist to hip
    path.quadraticBezierTo(
      centerX - waistHalfWidth - 8,
      (waistY + hipY) / 2,
      centerX - hipHalfWidth,
      hipY,
    );

    // Left hip to ankle
    path.quadraticBezierTo(
      centerX - hipHalfWidth + 12,
      kneeY,
      centerX - ankleHalfWidth,
      bottomY,
    );

    // Bottom curve between legs
    path.quadraticBezierTo(
      centerX,
      bottomY - 20,
      centerX + ankleHalfWidth,
      bottomY,
    );

    // Right ankle to hip
    path.quadraticBezierTo(
      centerX + hipHalfWidth - 12,
      kneeY,
      centerX + hipHalfWidth,
      hipY,
    );

    // Right hip to waist
    path.quadraticBezierTo(
      centerX + waistHalfWidth + 8,
      (waistY + hipY) / 2,
      centerX + waistHalfWidth,
      waistY,
    );

    // Right waist to chest
    path.quadraticBezierTo(
      centerX + chestHalfWidth - 4,
      (chestY + waistY) / 2,
      centerX + chestHalfWidth,
      chestY,
    );

    // Right chest to shoulder
    path.quadraticBezierTo(
      centerX + shoulderHalfWidth + 4,
      (shoulderY + chestY) / 2,
      centerX + shoulderHalfWidth,
      shoulderY,
    );

    // Shoulder top line
    path.quadraticBezierTo(
      centerX,
      shoulderY - 6,
      centerX - shoulderHalfWidth,
      shoulderY,
    );

    canvas.drawPath(path, outlinePaint);

    // Center guide line
    canvas.drawLine(
      Offset(centerX, shoulderY),
      Offset(centerX, bottomY),
      guidePaint,
    );

    // Shoulder guide
    canvas.drawLine(
      Offset(centerX - shoulderHalfWidth, shoulderY),
      Offset(centerX + shoulderHalfWidth, shoulderY),
      guidePaint,
    );

    // Waist guide
    canvas.drawLine(
      Offset(centerX - waistHalfWidth, waistY),
      Offset(centerX + waistHalfWidth, waistY),
      guidePaint,
    );

    // Hip guide
    canvas.drawLine(
      Offset(centerX - hipHalfWidth, hipY),
      Offset(centerX + hipHalfWidth, hipY),
      guidePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}