import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/rendering.dart';
import 'theme/app_theme.dart';
import 'services/dashboard_service.dart';

class PdfPreviewPage extends StatefulWidget {
  final Uint8List pdfBytes;
  final Map<String, dynamic> reportData;
  final int inspectionId;
  final VoidCallback onEdit;

  const PdfPreviewPage({
    super.key,
    required this.pdfBytes,
    required this.reportData,
    required this.inspectionId,
    required this.onEdit,
  });

  @override
  State<PdfPreviewPage> createState() => _PdfPreviewPageState();
}

class _PdfPreviewPageState extends State<PdfPreviewPage> with TickerProviderStateMixin {
  double _zoomLevel = 1.0; // 100% = 1 full page visible
  final ScrollController _scrollController = ScrollController();
  late AnimationController _backgroundController;

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  void _updateZoom(double newZoom) {
    setState(() {
      _zoomLevel = newZoom.clamp(0.5, 3.0);
    });
  }

  Future<void> _submitFinalReport(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.send_rounded, color: AppTheme.primaryRed, size: 28),
            ),
            const SizedBox(width: 16),
            Text('Submit Report', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to submit this inspection report?',
              style: GoogleFonts.inter(fontSize: 15),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accentYellow.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.accentYellow.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppTheme.accentYellow, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Once submitted, the report will be sent to the manager for review.',
                      style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Submit', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppTheme.primaryRed,
                  ),
                ),
                const SizedBox(height: 24),
                Text('Submitting Report...', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16)),
                const SizedBox(height: 8),
                Text('Please wait', style: GoogleFonts.inter(color: AppTheme.textSecondary)),
              ],
            ),
          ),
        ),
      );

      await DashboardService.submitVisualInspectionReport(
        inspectionId: widget.inspectionId,
        inspectionDate: widget.reportData['inspection_date'],
        equipmentFinding: widget.reportData['equipment_finding'],
        equipmentRecommendation: widget.reportData['equipment_recommendation'],
        externalFinding: widget.reportData['external_finding'],
        externalRecommendation: widget.reportData['external_recommendation'],
        weldFinding: widget.reportData['weld_finding'],
        weldRecommendation: widget.reportData['weld_recommendation'],
        internalAccessible: widget.reportData['internal_accessible'],
        internalFinding: widget.reportData['internal_finding'],
        internalRecommendation: widget.reportData['internal_recommendation'],
        thicknessData: widget.reportData['thickness_data'],
        overallCondition: widget.reportData['overall_condition'],
        generalRecommendation: widget.reportData['general_recommendation'],
        photoFiles: widget.reportData['photos'],
        photoSections: widget.reportData['photo_sections'],
        pdfBytes: widget.pdfBytes,
      );

      if (!context.mounted) return;
      Navigator.of(context).pop(); // Close loading
      Navigator.of(context).pop(); // Close preview
      Navigator.of(context).pop(); // Close workflow

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text('Report Submitted Successfully!', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
            ],
          ),
          backgroundColor: AppTheme.statusCompleted,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop(); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Animated gradient background
          AnimatedBuilder(
            animation: _backgroundController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(
                      math.cos(_backgroundController.value * 2 * math.pi),
                      math.sin(_backgroundController.value * 2 * math.pi),
                    ),
                    end: Alignment(
                      math.cos(_backgroundController.value * 2 * math.pi + math.pi),
                      math.sin(_backgroundController.value * 2 * math.pi + math.pi),
                    ),
                    colors: const [
                      Color(0xFFDC2626),
                      Color(0xFFB91C1C),
                      Color(0xFF991B1B),
                      Color(0xFF7F1D1D),
                    ],
                    stops: const [0.0, 0.3, 0.7, 1.0],
                  ),
                ),
              );
            },
          ),

          // Decorative circles
          Positioned(
            top: -size.height * 0.1,
            right: -size.width * 0.1,
            child: Container(
              width: size.width * 0.4,
              height: size.width * 0.4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -size.height * 0.08,
            left: -size.width * 0.15,
            child: Container(
              width: size.width * 0.5,
              height: size.width * 0.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.03),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Top Header Bar
                _buildHeader(context),

                // PDF Preview Area - FIXED FRAME WITH CHROME-LIKE ZOOM
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 40,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Column(
                        children: [
                          // Info Banner
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppTheme.accentYellow.withOpacity(0.1),
                              border: Border(
                                bottom: BorderSide(color: AppTheme.accentYellow.withOpacity(0.2)),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentYellow.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.zoom_in, color: AppTheme.accentYellow, size: 20),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    'Hold Alt + Scroll to zoom • Normal scroll to navigate pages',
                                    style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
                                  ),
                                ),
                                // Zoom indicator
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: Text(
                                    '${(_zoomLevel * 100).toInt()}%',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // PDF Content - FIXED FRAME, SCALABLE CONTENT
                          Expanded(
                            child: Container(
                              color: const Color(0xFFF3F4F6),
                              child: MouseRegion(
                                cursor: SystemMouseCursors.basic,
                                child: Listener(
                                  behavior: HitTestBehavior.opaque,
                                  onPointerSignal: (event) {
                                    if (event is PointerScrollEvent) {
                                      final isAltPressed =
                                          HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.altLeft) ||
                                          HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.altRight);

                                      if (isAltPressed) {
                                        // ZOOM: Alt + Scroll - CONTINUOUS & UNLIMITED
                                        setState(() {
                                          if (event.scrollDelta.dy < 0) {
                                            // Scroll up = zoom in
                                            _zoomLevel = (_zoomLevel + 0.1).clamp(0.5, 3.0);
                                          } else if (event.scrollDelta.dy > 0) {
                                            // Scroll down = zoom out
                                            _zoomLevel = (_zoomLevel - 0.1).clamp(0.5, 3.0);
                                          }
                                        });
                                        // Alt key doesn't trigger browser zoom - works perfectly!
                                      }
                                      // Without Alt: PdfPreview handles normal scrolling
                                    }
                                  },
                                  child: Center(
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        // FIXED CONTAINER - This NEVER moves or resizes
                                        Container(
                                          width: 794,
                                          height: size.height * 0.75,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.15),
                                                blurRadius: 30,
                                                offset: const Offset(0, 10),
                                              ),
                                            ],
                                          ),
                                        ),
                                        
                                        // CLIPPED CONTENT AREA - Absolutely positioned
                                        Positioned(
                                          left: 0,
                                          top: 0,
                                          right: 0,
                                          bottom: 0,
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: Transform.scale(
                                              scale: _zoomLevel,
                                              alignment: Alignment.center, // CENTER alignment keeps it stable
                                              child: Container(
                                                width: 794,
                                                height: size.height * 0.75,
                                                color: Colors.white,
                                                child: PdfPreview(
                                                  build: (format) => widget.pdfBytes,
                                                  allowPrinting: true,
                                                  allowSharing: false,
                                                  canChangeOrientation: false,
                                                  canDebug: false,
                                                  useActions: false,
                                                  pdfPreviewPageDecoration: const BoxDecoration(
                                                    color: Colors.transparent,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Bottom Action Bar
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border(
                                top: BorderSide(color: Colors.grey.shade200),
                              ),
                            ),
                            child: Row(
                              children: [
                                // Edit Button
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: widget.onEdit,
                                    icon: const Icon(Icons.edit_rounded),
                                    label: Text('Edit Report', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 18),
                                      side: const BorderSide(color: AppTheme.primaryRed, width: 2),
                                      foregroundColor: AppTheme.primaryRed,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 20),
                                // Submit Button
                                Expanded(
                                  flex: 2,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _submitFinalReport(context),
                                    icon: const Icon(Icons.send_rounded),
                                    label: Text(
                                      'Submit Final Report',
                                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryRed,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 18),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      elevation: 0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          // Back Button
          AppTheme.standardBackButton(
            onPressed: () => Navigator.pop(context),
            isLight: true,
            tooltip: 'Back to Report',
          ),
          const SizedBox(width: 20),

          // Logo
          AppTheme.standardSidebarLogo(hasGlow: false),
          const SizedBox(width: 16),

          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PDF Preview',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Review Before Submission',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),

          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.accentYellow,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.pending_rounded, color: Color(0xFF92400E), size: 18),
                const SizedBox(width: 8),
                Text(
                  'Draft',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF92400E),
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
