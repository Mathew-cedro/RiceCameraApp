import 'dart:io';
import 'package:palay_detector_v3/services/image_analyzer.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

import '../services/image_analyzer.dart';

import '../services/supabase_service.dart';
import '../services/theme_notifier.dart';
import '../models/scan_record.dart';

// ─────────────────────────────────────────────
//  CAMERA SCREEN
// ─────────────────────────────────────────────
class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const CameraScreen({super.key, required this.cameras});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.cameras.isNotEmpty) _initCamera(widget.cameras.first);
  }

  Future<void> _initCamera(CameraDescription cam) async {
    _controller = CameraController(
      cam,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    try {
      await _controller!.initialize();
      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _controller!.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera(_controller!.description);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _captureAndAnalyze() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isCapturing) return;
    setState(() => _isCapturing = true);
    try {
      final XFile file = await _controller!.takePicture();
      await _processAndNavigate(file.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Capture failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    await _processAndNavigate(file.path);
  }

  Future<void> _processAndNavigate(String filePath) async {
    setState(() => _isCapturing = true);

    
    final apiService = PalayApiService(); 
    
    final result = await apiService.uploadAndAnalyze(File(filePath)); 

    if (result == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to connect to analysis server')),
        );
        setState(() => _isCapturing = false);
      }
      return;
    }

    // 3. Save to Supabase (exactly as you had it)
    final fileName = path.basename(filePath);
    SupabaseService().saveScan(ScanRecord(
      id: '',
      createdAt: DateTime.now(),
      resultStatus: result.status,
      ripePercent: result.ripePercent,
      yellowPercent: result.yellowPercent,
      brownPercent: result.brownPercent,
      imageName: fileName,
    ));

    // 4. Navigate
    if (mounted) {
      setState(() => _isCapturing = false);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(imagePath: filePath, result: result),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Preview ──
          if (_isInitialized && _controller != null)
            Positioned.fill(child: CameraPreview(_controller!))
          else
            Center(
              child:
                  CircularProgressIndicator(color: theme.colorScheme.primary),
            ),

          // ── Top label ──
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.center_focus_strong_rounded,
                        color: theme.colorScheme.primary, size: 16),
                    const SizedBox(width: 6),
                    const Text(
                      'Point at palay field',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Corner guide ──
          const Center(child: _CropGuide()),

          // ── Bottom controls ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomControls(
              isCapturing: _isCapturing,
              onCapture: _captureAndAnalyze,
              onGallery: _pickFromGallery,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Crop guide ──────────────────────────────────────────────
class _CropGuide extends StatelessWidget {
  const _CropGuide();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 270,
      height: 270,
      child: CustomPaint(painter: _CornerPainter()),
    );
  }
}

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8BC34A)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const len = 28.0;
    final w = size.width;
    final h = size.height;
    for (final pts in [
      [Offset(0, len), Offset.zero, Offset(len, 0)],
      [Offset(w - len, 0), Offset(w, 0), Offset(w, len)],
      [Offset(w, h - len), Offset(w, h), Offset(w - len, h)],
      [Offset(len, h), Offset(0, h), Offset(0, h - len)],
    ]) {
      canvas.drawPath(
        Path()
          ..moveTo(pts[0].dx, pts[0].dy)
          ..lineTo(pts[1].dx, pts[1].dy)
          ..lineTo(pts[2].dx, pts[2].dy),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─── Bottom controls ─────────────────────────────────────────
class _BottomControls extends StatelessWidget {
  final bool isCapturing;
  final VoidCallback onCapture;
  final VoidCallback onGallery;

  const _BottomControls({
    required this.isCapturing,
    required this.onCapture,
    required this.onGallery,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(40, 20, 40, 44),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withOpacity(0.85), Colors.transparent],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Gallery
          GestureDetector(
            onTap: onGallery,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white38),
              ),
              child: const Icon(Icons.photo_library_outlined,
                  color: Colors.white, size: 22),
            ),
          ),

          // Shutter
          GestureDetector(
            onTap: isCapturing ? null : onCapture,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCapturing ? Colors.grey : const Color(0xFF8BC34A),
                border: Border.all(color: Colors.white, width: 3.5),
                boxShadow: isCapturing
                    ? []
                    : [
                        BoxShadow(
                          color: const Color(0xFF8BC34A).withOpacity(0.55),
                          blurRadius: 18,
                          spreadRadius: 2,
                        )
                      ],
              ),
              child: isCapturing
                  ? const Center(
                      child: SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      ),
                    )
                  : const Icon(Icons.camera_alt_rounded,
                      color: Colors.white, size: 30),
            ),
          ),

          // Placeholder to keep shutter centred
          const SizedBox(width: 50, height: 50),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  RESULT SCREEN
// ─────────────────────────────────────────────
class ResultScreen extends StatelessWidget {
  final String imagePath;
  final AnalysisResult result;

  const ResultScreen({
    super.key,
    required this.imagePath,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── App bar with image ──
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 16),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(File(imagePath), fit: BoxFit.cover),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 80,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            theme.scaffoldBackgroundColor,
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Result cards ──
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _StatusCard(result: result),
                const SizedBox(height: 14),
                _BreakdownCard(result: result, theme: theme),
                const SizedBox(height: 14),
                _RipenessMeter(percent: result.ripePercent),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.camera_alt_rounded),
                    label: const Text('Scan Another',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Status card ─────────────────────────────────────────────
class _StatusCard extends StatelessWidget {
  final AnalysisResult result;
  const _StatusCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: result.statusColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: result.statusColor.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: result.statusColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(result.statusIcon, color: result.statusColor, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.status,
                  style: TextStyle(
                    color: result.statusColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  result.advice,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Breakdown card ──────────────────────────────────────────
class _BreakdownCard extends StatelessWidget {
  final AnalysisResult result;
  final ThemeData theme;
  const _BreakdownCard({required this.result, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('COLOUR BREAKDOWN',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.45),
                fontSize: 11,
                letterSpacing: 1.3,
                fontWeight: FontWeight.w700,
              )),
          const SizedBox(height: 14),
          _Row('🟡 Yellow / Golden', result.yellowPercent,
              const Color(0xFFFFD54F), theme),
          const SizedBox(height: 8),
          _Row('🟤 Brown / Mature', result.brownPercent,
              const Color(0xFFA1887F), theme),
          Divider(color: theme.dividerColor, height: 22),
          _Row('Total Ripe Pixels', result.ripePercent, result.statusColor,
              theme,
              bold: true),
        ],
      ),
    );
  }

  Widget _Row(String label, double pct, Color color, ThemeData theme,
      {bool bold = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(label,
              style: TextStyle(
                color:
                    theme.colorScheme.onSurface.withOpacity(bold ? 1.0 : 0.7),
                fontSize: bold ? 14 : 13,
                fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
              )),
        ),
        Text('${pct.toStringAsFixed(1)}%',
            style: TextStyle(
              color: color,
              fontSize: bold ? 15 : 13,
              fontWeight: FontWeight.w700,
            )),
      ],
    );
  }
}

// ─── Ripeness meter ──────────────────────────────────────────
class _RipenessMeter extends StatelessWidget {
  final double percent;
  const _RipenessMeter({required this.percent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clamped = (percent / 100).clamp(0.0, 1.0);
    final color = clamped >= 0.7
        ? const Color(0xFF4CAF50)
        : clamped >= 0.4
            ? const Color(0xFF8BC34A)
            : clamped >= 0.2
                ? const Color(0xFFFF9800)
                : const Color(0xFFF44336);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('RIPENESS METER',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.45),
                    fontSize: 11,
                    letterSpacing: 1.3,
                    fontWeight: FontWeight.w700,
                  )),
              Text('${percent.toStringAsFixed(1)}%',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: clamped,
              minHeight: 12,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
