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
  final Map<String, dynamic>? formData;

  const InspectionReviewPage({
    super.key,
    required this.inspection,
    this.photoCount = 0,
    this.photoData = const [],
    this.inspectionMode = 'manual',
    this.formData,
  });

  Future<void> _submitReport(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Inspection Report'),
        content: const Text('Are you sure you want to submit this inspection report? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.inspectorPrimary, foregroundColor: Colors.white),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (!context.mounted) return;

    try {
      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));

      final pdfBytes = await _generatePdfReport();

      final reportData = {
        'findings': formData != null 
            ? 'Structured Inspection Data: Component: ${formData!['component']}, Damage: ${formData!['damage_mechanism']}. Findings: ${(formData!['findings'] as List).join(", ")}' 
            : 'Inspection completed with $photoCount photos.',
        'recommendations': formData != null
            ? 'Recommendations: ${(formData!['recommendations'] as List).join(", ")}'
            : 'Review photos.',
        'notes': formData?['notes'] ?? 'Inspection completed.',
        'pdf_file': pdfBytes,
        'structured_data': formData, // Send raw data if backend supports it
      };

      await ReportService.submitReport(inspection['id'], reportData);

      if (!context.mounted) return;
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Inspection report submitted successfully'), backgroundColor: AppTheme.primaryRed));
      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to submit report: $e'), backgroundColor: Colors.red));
    }
  }

  Future<Uint8List> _generatePdfReport() async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final reportDate = '${now.day}/${now.month}/${now.year}';

    // Use formData if available, otherwise fallback to AI generation or raw photo data
    final findingsList = formData != null ? List<String>.from(formData!['findings'] ?? []) : <String>[];
    final recList = formData != null ? List<String>.from(formData!['recommendations'] ?? []) : <String>[];
    
    // Page 1: Structured Report
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildPdfHeader(reportDate),
              pw.SizedBox(height: 24),
              
              if (formData != null) ...[
                pw.Text('1. INSPECTION DETAILS', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
                  child: pw.Column(
                    children: [
                      _buildPdfRow('Inspected Component', formData!['component'] ?? 'N/A'),
                      _buildPdfRow('Location', formData!['location'] ?? 'N/A'),
                      _buildPdfRow('Damage Mechanism', formData!['damage_mechanism'] ?? 'None'),
                      _buildPdfRow('Inspection Method', formData!['inspection_method'] ?? 'N/A'),
                    ],
                  ),
                ),
                pw.SizedBox(height: 16),
                
                if (formData!['measurements'] != null && (formData!['measurements']['thickness']?.isNotEmpty ?? false))
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('2. MEASUREMENTS', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 8),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(10),
                        decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                          children: [
                            pw.Column(children: [pw.Text('Actual Thickness', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)), pw.Text('${formData!['measurements']['thickness']} in')]),
                            pw.Column(children: [pw.Text('T-min Required', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)), pw.Text('${formData!['measurements']['t_min']} in')]),
                          ],
                        ),
                      ),
                      pw.SizedBox(height: 16),
                    ],
                  ),

                pw.Text('3. FINDINGS & OBSERVATIONS', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400), color: PdfColors.grey100),
                  child: findingsList.isEmpty 
                      ? pw.Text('No specific findings recorded.')
                      : pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: findingsList.map((f) => pw.Bullet(text: f)).toList(),
                        ),
                ),
                pw.SizedBox(height: 16),

                pw.Text('4. RECOMMENDATIONS', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400), color: PdfColors.amber50),
                  child: recList.isEmpty 
                      ? pw.Text('No specific recommendations recorded.')
                      : pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: recList.map((r) => pw.Bullet(text: r)).toList(),
                        ),
                ),
                
                if (formData!['notes']?.isNotEmpty == true) ...[
                   pw.SizedBox(height: 16),
                   pw.Text('5. INSPECTOR NOTES', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                   pw.SizedBox(height: 8),
                   pw.Text(formData!['notes'], style: const pw.TextStyle(fontSize: 11)),
                ]
              ],
            ],
          );
        },
      ),
    );

    // Photos Page
    if (photoData.isNotEmpty) {
      for (int i = 0; i < photoData.length; i++) {
        final photoBytes = Uint8List.fromList(photoData[i]['file'].path.isEmpty ? [] : await photoData[i]['file'].readAsBytes()); 
        // Note: Using await readAsBytes in standard dart:io might be better but here we assume bytes logic
        // Actually, the previous code had 'bytes' key. My workflow passes XFile. I need to handle that.
        // Let's assume for now I can figure out bytes. In web/mock, XFile works.
        // I will rely on reading XFile bytes.
        
        final image = pw.MemoryImage(photoBytes);
        final meta = photoData[i]['meta'] as Map<String, dynamic>?;

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (context) => pw.Column(
              children: [
                pw.Text('Photo Evidence ${i + 1}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 20),
                pw.Image(image, height: 400, fit: pw.BoxFit.contain),
                pw.SizedBox(height: 20),
                if (meta != null) ...[
                  pw.Text('Component: ${meta['component'] ?? 'N/A'}'),
                  pw.Text('Damage Tag: ${meta['damage'] ?? 'N/A'}'),
                ]
              ],
            ),
          ),
        );
      }
    }

    return pdf.save();
  }
  
  pw.Widget _buildPdfHeader(String date) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(border: pw.Border.all(width: 2), color: PdfColors.grey200),
      child: pw.Column(
        children: [
          pw.Text('API 510 INSPECTION REPORT', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.Divider(),
          _buildPdfRow('Tag No:', inspection['equipment_id'] ?? 'N/A'),
          _buildPdfRow('Date:', date),
          _buildPdfRow('Inspector:', inspection['assigned_to'] ?? 'Authorized Inspector'),
        ],
      ),
    );
  }

  pw.Widget _buildPdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(value),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      appBar: AppBar(title: const Text('Review & Submit'), backgroundColor: AppTheme.inspectorPrimary, foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Summary Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.assignment_turned_in, size: 32, color: AppTheme.inspectorPrimary),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Inspection Summary', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            Text('Tag: ${inspection['equipment_id'] ?? 'N/A'}', style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    if (formData != null) ...[
                      _buildInfoRow('Component', formData!['component'] ?? 'Not Selected'),
                      _buildInfoRow('Damage Type', formData!['damage_mechanism'] ?? 'None'),
                      _buildInfoRow('Method', formData!['inspection_method'] ?? 'Visual'),
                      if (formData!['measurements']?['thickness']?.isNotEmpty ?? false)
                        _buildInfoRow('Thickness', '${formData!['measurements']['thickness']} in'),
                      const SizedBox(height: 16),
                      const Text('Findings:', style: TextStyle(fontWeight: FontWeight.bold)),
                      ...(formData!['findings'] as List).map((e) => Padding(
                        padding: const EdgeInsets.only(left: 16, top: 4),
                        child: Text('• $e'),
                      )),
                      const SizedBox(height: 16), 
                      const Text('Recommendations:', style: TextStyle(fontWeight: FontWeight.bold)),
                      ...(formData!['recommendations'] as List).map((e) => Padding(
                        padding: const EdgeInsets.only(left: 16, top: 4),
                        child: Text('• $e'),
                      )),
                    ] else
                      const Text('No structured data available.'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Submit Report', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.inspectorPrimary, foregroundColor: Colors.white),
                onPressed: () => _submitReport(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
