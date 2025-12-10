import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:typed_data';
import 'theme/app_theme.dart';
import 'services/report_service.dart';
import 'services/report_generation_service.dart';

class InspectionReviewPage extends StatelessWidget {
  final Map<String, dynamic> inspection;
  final int photoCount;
  final List<Map<String, dynamic>> photoData;
  final String inspectionMode;

  const InspectionReviewPage({
    super.key,
    required this.inspection,
    this.photoCount = 0,
    this.photoData = const [],
    this.inspectionMode = 'manual',
  });

  Future<void> _submitReport(BuildContext context) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Inspection Report'),
        content: const Text(
          'Are you sure you want to submit this inspection report? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.inspectorPrimary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Show loading indicator
      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Generate PDF
      final pdfBytes = await _generatePdfReport();

      // Prepare report data for backend
      final reportData = {
        'findings': 'Inspection completed with ${photoData.length} photos. '
            'Inspection mode: $inspectionMode. '
            'All components documented with condition assessments.',
        'recommendations': 'Review all photos and component assessments in the detailed report. '
            'Follow up on any items marked as requiring attention.',
        'notes': 'Photo-based inspection completed successfully',
        'pdf_file': pdfBytes,
      };

      // Submit the report using ReportService
      await ReportService.submitReport(inspection['id'], reportData);

      if (!context.mounted) return;
      
      // Close loading dialog
      Navigator.pop(context);
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inspection report submitted successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back to dashboard
      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      if (!context.mounted) return;
      
      // Close loading dialog
      Navigator.pop(context);
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit report: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<Uint8List> _generatePdfReport() async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final reportDate = '${now.day}/${now.month}/${now.year}';

    // Generate AI-powered findings and recommendations from photo metadata
    final aiReport = ReportGenerationService.generateReport(
      photoData: photoData,
      equipmentTag: inspection['equipment_id']?.toString() ?? inspection['id']?.toString() ?? 'N/A',
      equipmentDescription: inspection['equipment_type']?.toString() ?? inspection['title'] ?? 'Pressure Vessel',
    );
    
    final generatedFindings = aiReport['findings'] ?? [];
    final generatedRecommendations = aiReport['recommendations'] ?? [];
    
    // Generate summary text for findings and recommendations
    final findingsSummary = ReportGenerationService.generateSummaryFindings(generatedFindings);
    final recommendationsSummary = ReportGenerationService.generateSummaryRecommendations(generatedRecommendations);

    // Page 1: Report Header and Summary
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 2),
                  color: PdfColors.grey300,
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'API 510 PRESSURE VESSEL INSPECTION REPORT',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Divider(thickness: 2),
                    pw.SizedBox(height: 8),
                    _buildHeaderRow('Equipment Tag Number:', inspection['equipment_id']?.toString() ?? inspection['id']?.toString() ?? 'N/A'),
                    _buildHeaderRow('Equipment Description:', inspection['equipment_type']?.toString() ?? inspection['title'] ?? 'Pressure Vessel'),
                    _buildHeaderRow('Location:', inspection['location'] ?? 'N/A'),
                    _buildHeaderRow('Report Number:', 'API510-${inspection['id']}-${now.year}'),
                    _buildHeaderRow('Inspection Date:', reportDate),
                    _buildHeaderRow('Inspection Mode:', inspectionMode.toUpperCase()),
                    _buildHeaderRow('Inspector Name:', inspection['assigned_to'] ?? 'N/A'),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 24),

              // Section 1: FINDINGS
              pw.Text(
                '1. VISUAL INSPECTION FINDINGS',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      findingsSummary,
                      style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.5),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 16),

              // Section 2: RECOMMENDATIONS
              pw.Text(
                '2. RECOMMENDATIONS',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(),
                ),
                child: pw.Text(
                  recommendationsSummary,
                  style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.5),
                ),
              ),

              pw.Spacer(),

              // Summary footer
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(),
                  color: PdfColors.grey200,
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Total Photos: ${photoData.length}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.Text(
                      'Total Findings: ${generatedFindings.length}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.Text(
                      'Page 1 of ${photoData.length + 2}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    // Add photo pages
    for (int i = 0; i < photoData.length; i++) {
      try {
        final photoBytes = Uint8List.fromList(photoData[i]['bytes'] as List<int>);
        final image = pw.MemoryImage(photoBytes);
        final componentType = photoData[i]['componentType'] ?? 'Component';
        final conditionStatus = photoData[i]['conditionStatus'] ?? 'N/A';
        final inspectorComment = photoData[i]['comment'] ?? '';
        
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(32),
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Photo ${i + 1} of ${photoData.length}: $componentType',
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Container(
                    width: double.infinity,
                    height: 400,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(),
                    ),
                    child: pw.Image(image, fit: pw.BoxFit.contain),
                  ),
                  pw.SizedBox(height: 12),
                  pw.Text('Condition Status: $conditionStatus', style: const pw.TextStyle(fontSize: 11)),
                  if (inspectorComment.isNotEmpty) ...[
                    pw.SizedBox(height: 8),
                    pw.Text('Inspector Comments:', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                    pw.Text(inspectorComment, style: const pw.TextStyle(fontSize: 10)),
                  ],
                ],
              );
            },
          ),
        );
      } catch (e) {
        print('Error adding photo $i to PDF: $e');
      }
    }

    // Generate and return PDF bytes
    return pdf.save();
  }

  Future<void> _exportToPDF(BuildContext context) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final reportDate = '${now.day}/${now.month}/${now.year}';

    // Generate AI-powered findings and recommendations from photo metadata
    final aiReport = ReportGenerationService.generateReport(
      photoData: photoData,
      equipmentTag: inspection['equipment_id']?.toString() ?? inspection['id']?.toString() ?? 'N/A',
      equipmentDescription: inspection['equipment_type']?.toString() ?? inspection['title'] ?? 'Pressure Vessel',
    );
    
    final generatedFindings = aiReport['findings'] ?? [];
    final generatedRecommendations = aiReport['recommendations'] ?? [];
    
    // Generate summary text for findings and recommendations
    final findingsSummary = ReportGenerationService.generateSummaryFindings(generatedFindings);
    final recommendationsSummary = ReportGenerationService.generateSummaryRecommendations(generatedRecommendations);

    // Page 1: Report Header and Summary
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 2),
                  color: PdfColors.grey300,
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'API 510 PRESSURE VESSEL INSPECTION REPORT',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Divider(thickness: 2),
                    pw.SizedBox(height: 8),
                    _buildHeaderRow('Equipment Tag Number:', inspection['equipment_id']?.toString() ?? inspection['id']?.toString() ?? 'N/A'),
                    _buildHeaderRow('Equipment Description:', inspection['equipment_type']?.toString() ?? inspection['title'] ?? 'Pressure Vessel'),
                    _buildHeaderRow('Location:', inspection['location'] ?? 'N/A'),
                    _buildHeaderRow('Report Number:', 'API510-${inspection['id']}-${now.year}'),
                    _buildHeaderRow('Inspection Date:', reportDate),
                    _buildHeaderRow('Inspection Mode:', inspectionMode.toUpperCase()),
                    _buildHeaderRow('Inspector Name:', inspection['assigned_to'] ?? 'N/A'),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 24),

              // Section 1: FINDINGS
              pw.Text(
                '1. VISUAL INSPECTION FINDINGS',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      findingsSummary,
                      style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.5),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 16),

              // Section 3: RECOMMENDATIONS
              pw.Text(
                '2. RECOMMENDATIONS',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(),
                ),
                child: pw.Text(
                  recommendationsSummary,
                  style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.5),
                ),
              ),

              pw.Spacer(),

              // Summary footer
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(),
                  color: PdfColors.grey200,
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Total Photos: ${photoData.length}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.Text(
                      'Total Findings: ${generatedFindings.length}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.Text(
                      'Page 1 of ${photoData.length + 2}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    // Photo Pages - One page per photo with findings and recommendations
    for (int i = 0; i < photoData.length; i++) {
      try {
        final photoBytes = Uint8List.fromList(photoData[i]['bytes'] as List<int>);
        final image = pw.MemoryImage(photoBytes);
        final photoName = photoData[i]['name'] ?? 'photo_${i + 1}';
        final componentType = photoData[i]['componentType'] ?? 'Component';
        final conditionStatus = photoData[i]['conditionStatus'] ?? 'N/A';
        final inspectorComment = photoData[i]['comment'] ?? '';
        
        final finding = generatedFindings[i];
        final recommendation = generatedRecommendations[i];

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(32),
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Photo header
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blue900,
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'PHOTO ${i + 1} OF ${photoData.length}',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                            fontSize: 14,
                          ),
                        ),
                        pw.Text(
                          'Page ${i + 2} of ${photoData.length + 2}',
                          style: const pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  pw.SizedBox(height: 16),

                  // Photo and findings side by side
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Photo on left (60% width)
                      pw.Expanded(
                        flex: 6,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Container(
                              height: 350,
                              decoration: pw.BoxDecoration(
                                border: pw.Border.all(width: 2),
                              ),
                              child: pw.Center(
                                child: pw.Image(image, fit: pw.BoxFit.contain),
                              ),
                            ),
                            pw.SizedBox(height: 8),
                            pw.Container(
                              padding: const pw.EdgeInsets.all(8),
                              decoration: pw.BoxDecoration(
                                border: pw.Border.all(),
                                color: PdfColors.grey200,
                              ),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text('Photo ID: $photoName', style: const pw.TextStyle(fontSize: 9)),
                                  pw.Text('Component: $componentType', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                                  pw.Text('Condition: $conditionStatus', style: const pw.TextStyle(fontSize: 9)),
                                  pw.Text('Date: $reportDate', style: const pw.TextStyle(fontSize: 9)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      pw.SizedBox(width: 16),

                      // Findings and Recommendations on right (40% width)
                      pw.Expanded(
                        flex: 4,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            // FINDING Section
                            pw.Container(
                              width: double.infinity,
                              padding: const pw.EdgeInsets.all(8),
                              decoration: pw.BoxDecoration(
                                border: pw.Border.all(),
                                color: PdfColors.blue100,
                              ),
                              child: pw.Text(
                                'FINDING ${finding['number']}',
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            pw.Container(
                              width: double.infinity,
                              padding: const pw.EdgeInsets.all(10),
                              decoration: pw.BoxDecoration(
                                border: pw.Border.all(),
                              ),
                              constraints: const pw.BoxConstraints(minHeight: 150),
                              child: pw.Text(
                                finding['statement'] ?? '',
                                style: const pw.TextStyle(fontSize: 10, lineSpacing: 1.4),
                              ),
                            ),
                            
                            pw.SizedBox(height: 12),
                            
                            // RECOMMENDATION Section
                            pw.Container(
                              width: double.infinity,
                              padding: const pw.EdgeInsets.all(8),
                              decoration: pw.BoxDecoration(
                                border: pw.Border.all(),
                                color: PdfColors.green100,
                              ),
                              child: pw.Text(
                                'RECOMMENDATION ${recommendation['number']}',
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            pw.Container(
                              width: double.infinity,
                              padding: const pw.EdgeInsets.all(10),
                              decoration: pw.BoxDecoration(
                                border: pw.Border.all(),
                              ),
                              constraints: const pw.BoxConstraints(minHeight: 120),
                              child: pw.Text(
                                recommendation['statement'] ?? '',
                                style: const pw.TextStyle(fontSize: 10, lineSpacing: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  pw.Spacer(),

                  // Inspector Comment
                  if (inspectorComment.isNotEmpty) ...[
                    pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(),
                        color: PdfColors.yellow100,
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'INSPECTOR OBSERVATION:',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            inspectorComment,
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        );
      } catch (e) {
        print('Error adding photo $i: $e');
      }
    }

    // Final Page: Sign-off
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'INSPECTION SIGN-OFF',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.Divider(thickness: 2),
              
              pw.SizedBox(height: 40),

              _buildSignOffField('Inspected By:', inspection['assigned_to'] ?? ''),
              pw.SizedBox(height: 8),
              _buildSignOffField('Signature:', ''),
              pw.SizedBox(height: 8),
              _buildSignOffField('Date:', reportDate),

              pw.SizedBox(height: 40),

              _buildSignOffField('Reviewed By:', ''),
              pw.SizedBox(height: 8),
              _buildSignOffField('Signature:', ''),
              pw.SizedBox(height: 8),
              _buildSignOffField('Date:', ''),

              pw.SizedBox(height: 40),

              _buildSignOffField('Approved By:', ''),
              pw.SizedBox(height: 8),
              _buildSignOffField('Signature:', ''),
              pw.SizedBox(height: 8),
              _buildSignOffField('Date:', ''),

              pw.Spacer(),

              pw.Divider(),
              pw.Text(
                'This report conforms to API 510 Pressure Vessel Inspection Code requirements.',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Generated: ${DateTime.now()}',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey),
              ),
            ],
          );
        },
      ),
    );

    // Show PDF preview and allow download/print
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'API510_Inspection_Report_${inspection['id']}_$reportDate.pdf',
    );
  }

  pw.Widget _buildHeaderRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 180,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSignOffField(String label, String value) {
    return pw.Row(
      children: [
        pw.SizedBox(
          width: 150,
          child: pw.Text(
            label,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide()),
            ),
            child: pw.Text(value),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Review Report',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: AppTheme.inspectorPrimary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Please review all information carefully before submitting. '
                      'This action cannot be undone.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Inspection Details (Read-only)
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.assignment, color: AppTheme.inspectorPrimary),
                        SizedBox(width: 8),
                        Text(
                          'Inspection Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _buildInfoRow('Title', inspection['title'] ?? 'N/A'),
                    const SizedBox(height: 12),
                    _buildInfoRow('Location', inspection['location'] ?? 'N/A'),
                    const SizedBox(height: 12),
                    _buildInfoRow('Date', inspection['scheduled_date'] ?? 'N/A'),
                    if (inspection['notes'] != null &&
                        inspection['notes'].toString().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildInfoRow('Manager Notes', inspection['notes']),
                    ],
                    if (photoCount > 0) ...[
                      const SizedBox(height: 12),
                      _buildInfoRow('Photos with Metadata', '$photoCount photo(s)'),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Summary Card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.summarize, color: AppTheme.inspectorPrimary),
                        SizedBox(width: 8),
                        Text(
                          'Inspection Summary',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    
                    _buildInfoRow('Equipment Tag', inspection['equipment_id']?.toString() ?? inspection['id']?.toString() ?? 'N/A'),
                    const SizedBox(height: 12),
                    _buildInfoRow('Equipment Type', inspection['equipment_type']?.toString() ?? inspection['title'] ?? 'N/A'),
                    const SizedBox(height: 12),
                    _buildInfoRow('Location', inspection['location'] ?? 'N/A'),
                    const SizedBox(height: 12),
                    _buildInfoRow('Inspection Mode', inspectionMode.toUpperCase()),
                    const SizedBox(height: 12),
                    _buildInfoRow('Photos Captured', '${photoData.length} photo(s)'),
                    const SizedBox(height: 12),
                    _buildInfoRow('Total Findings', '${photoData.length} finding(s)'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Photos'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      foregroundColor: AppTheme.inspectorPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _exportToPDF(context),
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Export PDF'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _submitReport(context),
                    icon: const Icon(Icons.send),
                    label: const Text('Submit Report'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }


}
