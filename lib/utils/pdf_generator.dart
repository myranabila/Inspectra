import 'dart:typed_data';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

class PdfGenerator {
  /// Generate inspection report matching the format:
  /// Page 1: Findings, NDT & Recommendations
  /// Page 2+: Photos Report with findings for each photo
  static Future<Uint8List> generateVisualInspectionReport({
    required Map<String, dynamic> inspection,
    required Map<String, dynamic> reportData,
    required bool requireExternal,
    required bool requireWeld,
    required bool requireInternal,
    required bool requireThickness,
  }) async {
    final pdf = pw.Document();
    
    // Extract data
    final inspectionId = inspection['inspection_id_display'] ?? inspection['equipment_id'] ?? 'N/A';
    final reportNumber = inspection['report_number'] ?? 'N/A';
    final equipmentTag = inspection['equipment_id'] ?? 'R-001';
    final equipmentType = inspection['equipment_type'] ?? 'Reactor';
    final equipmentDescription = inspection['title'] ?? equipmentType;
    final area = inspection['area'] ?? inspection['location'] ?? 'Plant 1';
    final reportDate = DateFormat('dd MMM yyyy').format(DateTime.now());
    final inspectionDate = reportData['inspection_date'] ?? reportDate;
    final inspectorName = inspection['inspector']?['username'] ?? 'Inspector';
    final plant = area.split('>').first.trim(); // Extract plant from area
    
    // Process photos
    final photoSections = reportData['photo_sections'] as Map<String, dynamic>? ?? {};
    final allPhotos = reportData['photos'] as List<dynamic>? ?? [];
    final equipmentSectionsRaw = reportData['equipment_sections_data'] as List<dynamic>?;
    
    int equipmentCount = photoSections['equipment'] ?? 0;
    int externalCount = photoSections['external'] ?? 0;
    int weldCount = photoSections['weld'] ?? 0;
    int internalCount = photoSections['internal'] ?? 0;
    
    // Process Equipment Sections specifically
    // If equipmentSectionsData is present, use it. Otherwise fall back to legacy flat list logic.
    List<PhotoWithFinding> equipmentPhotoData = [];
    
    if (equipmentSectionsRaw != null && equipmentSectionsRaw.isNotEmpty) {
       for (var section in equipmentSectionsRaw) {
          final xFiles = section['photos'] as List<Object?>? ?? [];
          List<pw.ImageProvider> sectionImages = [];
          for (var xf in xFiles) {
             if (xf is XFile) {
               final bytes = await xf.readAsBytes();
               sectionImages.add(pw.MemoryImage(bytes));
             }
          }
          
          List<String> findingLines = (section['findings'] as List<dynamic>? ?? []).cast<String>();
          List<String> recLines = (section['recommendations'] as List<dynamic>? ?? []).cast<String>();
          
          if (sectionImages.isNotEmpty) {
             equipmentPhotoData.add(PhotoWithFinding(
               photoNumber: '${section['section_number']}', // Just "1", "2" etc. Sub-labels are handled in layout
               image: sectionImages.first, // Legacy field, ignored if multiImages is set
               multiImages: sectionImages, // NEW: List of images for grid
               finding: findingLines.join('\n'),
               recommendation: recLines.join('\n'),
               isSectionGroup: true,
             ));
          }
       }
    } else {
      // Legacy fallback
       List<pw.ImageProvider> equipmentImages = await _processPhotos(allPhotos, 0, equipmentCount);
       int photoCounter = 1;
       for (int i = 0; i < equipmentImages.length; i++) {
        equipmentPhotoData.add(PhotoWithFinding(
          photoNumber: '${photoCounter}.1',
          image: equipmentImages[i],
          finding: reportData['equipment_finding'] ?? 'Equipment in good condition',
          recommendation: reportData['equipment_recommendation'] ?? 'Nil',
        ));
        photoCounter++;
      }
    }

    List<pw.ImageProvider> externalImages = await _processPhotos(allPhotos, equipmentCount, externalCount);
    List<pw.ImageProvider> weldImages = await _processPhotos(allPhotos, equipmentCount + externalCount, weldCount);
    List<pw.ImageProvider> internalImages = await _processPhotos(allPhotos, equipmentCount + externalCount + weldCount, internalCount);
    
    // ========== PAGE 1: FINDINGS, NDT & RECOMMENDATIONS ==========
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              _buildReportHeader(
                reportNumber: reportNumber,
                plant: plant,
                reportDate: reportDate,
                equipmentTag: equipmentTag,
                equipmentDescription: equipmentDescription,
                doshRegistration: reportNumber,
                pageNumber: 1,
              ),
              
              pw.SizedBox(height: 12),
              
              // Equipment Details Table
              _buildEquipmentDetailsTable(
                equipmentTag: equipmentTag,
                equipmentType: equipmentType,
                area: area,
                inspectionDate: inspectionDate,
              ),
              
              pw.SizedBox(height: 12),
              
              // FINDINGS, NDT & RECOMMENDATIONS Section Header
              _buildPage1SectionHeader(),
              
              pw.SizedBox(height: 8),
              
              // Findings Table
              _buildFindingsTable(
                reportData: reportData,
                requireExternal: requireExternal,
                requireWeld: requireWeld,
                requireInternal: requireInternal,
                requireThickness: requireThickness,
              ),
              
              pw.SizedBox(height: 12),
              
              // NDT Results Table
              _buildNDTTable(),
              
              pw.SizedBox(height: 12),
              
              // Recommendations Table
              _buildRecommendationsTable(
                recommendation: reportData['overall_recommendation'] ?? 'Continue routine inspection schedule',
              ),
              
              pw.Spacer(),
              
              // Footer with signatures
              _buildPage1Footer(inspectorName: inspectorName),
            ],
          );
        },
      ),
    );
    
    // ========== PAGE 2+: PHOTOS REPORT ==========
    List<PhotoWithFinding> photosWithFindings = [];
    photosWithFindings.addAll(equipmentPhotoData); // Add new structured sections

    int photoCounter = equipmentPhotoData.length + 1;

    // External photos - Legacy block removed as they are now part of equipmentPhotoData
    // via 'equipment_sections_data' in _submitReport
    // if (requireExternal) { ... }
    
    // Weld photos
    if (requireWeld) {
      for (int i = 0; i < weldImages.length; i++) {
        String finding = reportData['weld_finding'] ?? 'Welds appear sound';
        if (reportData['weld_condition'] != null) {
          finding = '${reportData['weld_condition']}: $finding';
        }
        photosWithFindings.add(PhotoWithFinding(
          photoNumber: photoCounter.toString(),
          image: weldImages[i],
          finding: finding,
          recommendation: reportData['weld_section_recommendation'] ?? 'Nil',
        ));
        photoCounter++;
      }
    }
    
    // Internal photos
    if (requireInternal && (reportData['internal_accessible'] ?? false)) {
      for (int i = 0; i < internalImages.length; i++) {
        String finding = reportData['internal_finding'] ?? 'Internal surfaces acceptable';
        if (reportData['internal_condition'] != null) {
          finding = '${reportData['internal_condition']}: $finding';
        }
        photosWithFindings.add(PhotoWithFinding(
          photoNumber: photoCounter.toString(),
          image: internalImages[i],
          finding: finding,
          recommendation: reportData['internal_section_recommendation'] ?? 'Nil',
        ));
        photoCounter++;
      }
    }
    
    if (photosWithFindings.isNotEmpty) {
      // Generate photo pages
      final photoPages = _generatePhotoPages(
        photosWithFindings: photosWithFindings,
        reportNumber: reportNumber,
        plant: plant,
        reportDate: reportDate,
        equipmentTag: equipmentTag,
        equipmentDescription: equipmentDescription,
        doshRegistration: reportNumber,
        inspectorName: inspectorName,
      );
      
      for (var page in photoPages) {
        pdf.addPage(page);
      }
    }
    
    return pdf.save();
  }

  // ========== HELPER: Process Photos ==========
  static Future<List<pw.ImageProvider>> _processPhotos(
    List<dynamic> allPhotos,
    int startIdx,
    int count,
  ) async {
    List<pw.ImageProvider> images = [];
    
    for (int i = 0; i < count && (startIdx + i) < allPhotos.length; i++) {
      try {
        final photo = allPhotos[startIdx + i];
        if (photo is XFile) {
          final bytes = await photo.readAsBytes();
          final image = pw.MemoryImage(bytes);
          images.add(image);
        }
      } catch (e) {
        print('Error processing photo: $e');
      }
    }
    
    return images;
  }

  // ========== PAGE 1 COMPONENTS ==========
  
  static pw.Widget _buildReportHeader({
    required String reportNumber,
    required String plant,
    required String reportDate,
    required String equipmentTag,
    required String equipmentDescription,
    required String doshRegistration,
    required int pageNumber,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1),
      ),
      child: pw.Row(
        children: [
          // Left section (empty)
          pw.Container(
            width: 80,
            decoration: const pw.BoxDecoration(
              border: pw.Border(right: pw.BorderSide(color: PdfColors.black)),
            ),
          ),
          
          // Center section (Title)
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Column(
                children: [
                  pw.Text(
                    'MAJOR TURNAROUND 2025',
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    'PRESSURE VESSEL INSPECTION REPORT',
                    style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          
          // Right section (Report details)
          pw.Container(
            width: 150,
            padding: const pw.EdgeInsets.all(6),
            decoration: const pw.BoxDecoration(
              border: pw.Border(left: pw.BorderSide(color: PdfColors.black)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Report no.:', style: const pw.TextStyle(fontSize: 8)),
                pw.Text(reportNumber, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                pw.Divider(),
                pw.Text('Report date:', style: const pw.TextStyle(fontSize: 8)),
                pw.Text(reportDate, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPage1SectionHeader() {
    return pw.Container(
      color: PdfColors.grey300,
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        'FINDINGS, NDT & RECOMMENDATIONS',
        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  static pw.Widget _buildPage1SectionTitle(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Text(
        title,
        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline),
      ),
    );
  }

  static pw.Widget _buildPage1Finding({
    String? title,
    String? content,
    List<pw.Widget>? findings,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (title != null && title.isNotEmpty)
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, fontStyle: pw.FontStyle.italic),
          ),
        if (content != null)
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 10, top: 4),
            child: pw.Text(content, style: const pw.TextStyle(fontSize: 9)),
          ),
        if (findings != null) ...findings,
      ],
    );
  }

  static List<pw.Widget> _buildFindingsList({
    required Map<String, dynamic> reportData,
    required bool requireExternal,
    required bool requireWeld,
    required bool requireInternal,
    required bool requireThickness,
  }) {
    List<pw.Widget> findings = [];
    int counter = 1;
    
    // External findings
    if (requireExternal) {
      String externalFinding = reportData['external_finding'] ?? 'No issues detected';
      String externalCondition = reportData['external_condition'] ?? 'Satisfactory';
      findings.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(left: 10, top: 4),
          child: pw.Text(
            '4.$counter $externalCondition: $externalFinding',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.blue),
          ),
        ),
      );
      counter++;
    }
    
    // Weld findings
    if (requireWeld) {
      String weldFinding = reportData['weld_finding'] ?? 'Welds appear sound';
      String weldCondition = reportData['weld_condition'] ?? 'Satisfactory';
      findings.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(left: 10, top: 4),
          child: pw.Text(
            '4.$counter $weldCondition: $weldFinding',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.blue),
          ),
        ),
      );
      counter++;
    }
    
    // Internal findings
    if (requireInternal && (reportData['internal_accessible'] ?? false)) {
      String internalFinding = reportData['internal_finding'] ?? 'Internal surfaces acceptable';
      String internalCondition = reportData['internal_condition'] ?? 'Satisfactory';
      findings.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(left: 10, top: 4),
          child: pw.Text(
            '4.$counter $internalCondition: $internalFinding',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.blue),
          ),
        ),
      );
      counter++;
    }
    
    // Thickness findings (if applicable)
    if (requireThickness) {
      String thicknessCondition = reportData['thickness_condition'] ?? 'Satisfactory';
      findings.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(left: 10, top: 4),
          child: pw.Text(
            '4.$counter Thickness measurements within acceptable range - $thicknessCondition',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.blue),
          ),
        ),
      );
    }
    
    return findings;
  }

  static pw.Widget _buildPage1Footer({required String inspectorName}) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black),
      ),
      child: pw.Column(
        children: [
          // Signature row
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(6),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(right: pw.BorderSide(color: PdfColors.black)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Inspected by:', style: const pw.TextStyle(fontSize: 8)),
                      pw.SizedBox(height: 20),
                      pw.Text(inspectorName, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(6),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(right: pw.BorderSide(color: PdfColors.black)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Reviewed by:', style: const pw.TextStyle(fontSize: 8)),
                      pw.SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Approved by [Client]:', style: const pw.TextStyle(fontSize: 8)),
                      pw.SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // DOSH Officer section
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(6),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: PdfColors.black)),
            ),
            child: pw.Text(
              'Recommendation/Comment by DOSH Officer (if applicable):',
              style: const pw.TextStyle(fontSize: 8),
            ),
          ),
          pw.Container(
            height: 30,
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: PdfColors.black)),
            ),
          ),
          // Action taken section
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(6),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: PdfColors.black)),
            ),
            child: pw.Text(
              'Action taken by Plant 1 on recommendation by DOSH (if applicable):',
              style: const pw.TextStyle(fontSize: 8),
            ),
          ),
          pw.Container(
            height: 30,
          ),
        ],
      ),
    );
  }

  // ========== NEW TABLE-BASED LAYOUTS FOR CLEANER STRUCTURE ==========
  
  static pw.Widget _buildEquipmentDetailsTable({
    required String equipmentTag,
    required String equipmentType,
    required String area,
    required String inspectionDate,
  }) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
      children: [
        // Header Row
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _buildTableCell('EQUIPMENT DETAILS', isHeader: true, colspan: 4),
          ],
        ),
        // Data Rows
        pw.TableRow(
          children: [
            _buildTableCell('Equipment Tag:', bold: true),
            _buildTableCell(equipmentTag),
            _buildTableCell('Equipment Type:', bold: true),
            _buildTableCell(equipmentType),
          ],
        ),
        pw.TableRow(
          children: [
            _buildTableCell('Location/Area:', bold: true),
            _buildTableCell(area),
            _buildTableCell('Inspection Date:', bold: true),
            _buildTableCell(inspectionDate),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildFindingsTable({
    required Map<String, dynamic> reportData,
    required bool requireExternal,
    required bool requireWeld,
    required bool requireInternal,
    required bool requireThickness,
  }) {
    List<pw.TableRow> rows = [
      // Header
      pw.TableRow(
        decoration: pw.BoxDecoration(color: PdfColors.grey300),
        children: [
          _buildTableCell('INSPECTION FINDINGS', isHeader: true),
          _buildTableCell('CONDITION', isHeader: true),
          _buildTableCell('DETAILS', isHeader: true),
        ],
      ),
    ];

    // Equipment (always included)
    rows.add(pw.TableRow(
      children: [
        _buildTableCell('Equipment Identification'),
        _buildTableCell('N/A'),
        _buildTableCell(reportData['equipment_finding'] ?? 'Equipment in good condition'),
      ],
    ));

    // External Visual
    if (requireExternal) {
      rows.add(pw.TableRow(
        children: [
          _buildTableCell('External Visual'),
          _buildTableCell(reportData['external_condition'] ?? 'Satisfactory'),
          _buildTableCell(reportData['external_finding'] ?? 'No visible defects'),
        ],
      ));
    }

    // Weld Visual
    if (requireWeld) {
      rows.add(pw.TableRow(
        children: [
          _buildTableCell('Weld Visual'),
          _buildTableCell(reportData['weld_condition'] ?? 'Satisfactory'),
          _buildTableCell(reportData['weld_finding'] ?? 'Welds appear sound'),
        ],
      ));
    }

    // Internal Visual
    if (requireInternal && (reportData['internal_accessible'] ?? false)) {
      rows.add(pw.TableRow(
        children: [
          _buildTableCell('Internal Visual'),
          _buildTableCell(reportData['internal_condition'] ?? 'Satisfactory'),
          _buildTableCell(reportData['internal_finding'] ?? 'Internal surfaces acceptable'),
        ],
      ));
    }

    // Thickness
    if (requireThickness) {
      rows.add(pw.TableRow(
        children: [
          _buildTableCell('Thickness Measurement'),
          _buildTableCell(reportData['thickness_condition'] ?? 'Satisfactory'),
          _buildTableCell('Measurements within acceptable range - refer to thickness data'),
        ],
      ));
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(3),
      },
      children: rows,
    );
  }

  static pw.Widget _buildNDTTable() {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _buildTableCell('NON-DESTRUCTIVE TESTING (NDT)', isHeader: true),
            _buildTableCell('RESULT', isHeader: true),
          ],
        ),
        pw.TableRow(
          children: [
            _buildTableCell('Ultrasonic Thickness Measurement (UTTM)'),
            _buildTableCell('No significant wall loss detected. Refer to UTTM report for details.'),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildRecommendationsTable({
    required String recommendation,
  }) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _buildTableCell('OVERALL RECOMMENDATIONS', isHeader: true),
          ],
        ),
        pw.TableRow(
          children: [
            _buildTableCell(recommendation, minHeight: 40),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    bool bold = false,
    int colspan = 1,
    double minHeight = 25,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      constraints: pw.BoxConstraints(minHeight: minHeight),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: (isHeader || bold) ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  // ========== PAGE 2+ COMPONENTS (PHOTOS) ==========
  
  static List<pw.Page> _generatePhotoPages({
    required List<PhotoWithFinding> photosWithFindings,
    required String reportNumber,
    required String plant,
    required String reportDate,
    required String equipmentTag,
    required String equipmentDescription,
    required String doshRegistration,
    required String inspectorName,
  }) {
    List<pw.Page> pages = [];
    int pageNumber = 2;
    
    // Group photos (2 per page works well)
    for (int i = 0; i < photosWithFindings.length; i += 2) {
      final photosOnPage = photosWithFindings.skip(i).take(2).toList();
      
      pages.add(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                _buildReportHeader(
                  reportNumber: reportNumber,
                  plant: plant,
                  reportDate: reportDate,
                  equipmentTag: equipmentTag,
                  equipmentDescription: equipmentDescription,
                  doshRegistration: doshRegistration,
                  pageNumber: pageNumber,
                ),
                
                pw.SizedBox(height: 10),
                
                // Equipment details
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Equipment tag no: $equipmentTag',
                        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        'Plant/Unit/Area: Page 1',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 5),
                
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Equipment description: $equipmentDescription',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                      pw.Text(
                        'DOSH registration no.: $doshRegistration',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 10),
                
                // PHOTOS REPORT header
                pw.Container(
                  color: PdfColors.black,
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(
                    'PHOTOS REPORT',
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  ),
                ),
                
                pw.SizedBox(height: 10),
                
                // Photos with findings
                ...photosOnPage.map((photoData) => _buildPhotoRow(photoData)),
                
                pw.Spacer(),
                
                // Footer
                pw.Container(
                  padding:const pw.EdgeInsets.all(8),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(top: pw.BorderSide(color: PdfColors.black)),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Inspected by: $inspectorName', style: const pw.TextStyle(fontSize: 9)),
                      pw.Text('Date: $reportDate', style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );
      
      pageNumber++;
    }
    
    return pages;
  }

  static pw.Widget _buildPhotoRow(PhotoWithFinding photoData) {
    // If it's a section group with multiple photos
    if (photoData.isSectionGroup && photoData.multiImages != null && photoData.multiImages!.isNotEmpty) {
      return pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 15),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.black),
        ),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Photo section (Left Column)
            pw.Container(
              width: 300, // Slightly wider for 3 photos
              padding: const pw.EdgeInsets.all(8),
              decoration: const pw.BoxDecoration(
                border: pw.Border(right: pw.BorderSide(color: PdfColors.black)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    color: PdfColors.black,
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(
                      'Photo ${photoData.photoNumber}',
                      style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white),
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  // Grid of photos
                  pw.Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: List.generate(photoData.multiImages!.length, (index) {
                       final img = photoData.multiImages![index];
                       final label = '${photoData.photoNumber}.${index + 1}';
                       return pw.Column(
                         children: [
                            pw.Container(
                              width: 90, // Fit 3 in ~300 width
                              height: 90,
                              decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey)),
                              child: pw.Image(img, fit: pw.BoxFit.cover),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Container(
                               padding: const pw.EdgeInsets.all(2),
                               decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.red)),
                               child: pw.Text(label, style: const pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                            )
                         ],
                       );
                    }),
                  ),
                ],
              ),
            ),

            // Finding & Recommendation section (Right Column)
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Finding:',
                        style: pw.TextStyle(
                            fontSize: 9, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline)),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      photoData.finding,
                      style:
                          const pw.TextStyle(fontSize: 8, color: PdfColors.blue),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text('Recommendation:',
                        style: pw.TextStyle(
                            fontSize: 9, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline)),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      photoData.recommendation,
                      style:
                          const pw.TextStyle(fontSize: 8, color: PdfColors.blue),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Default Fallback (Legacy single photo)
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Photo section
          pw.Container(
            width: 250,
            padding: const pw.EdgeInsets.all(8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(right: pw.BorderSide(color: PdfColors.black)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  color: PdfColors.black,
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(
                    'Photo ${photoData.photoNumber}',
                    style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white),
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Container(
                  height: 150,
                  child: pw.Image(photoData.image, fit: pw.BoxFit.contain),
                ),
              ],
            ),
          ),

          // Finding & Recommendation section
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Finding:',
                      style: pw.TextStyle(
                          fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    photoData.finding,
                    style:
                        const pw.TextStyle(fontSize: 9, color: PdfColors.blue),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text('Recommendation:',
                      style: pw.TextStyle(
                          fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    photoData.recommendation,
                    style:
                        const pw.TextStyle(fontSize: 9, color: PdfColors.blue),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper class to store photo with its finding
class PhotoWithFinding {
  final String photoNumber;
  final pw.ImageProvider image; // Primary image (legacy)
  final List<pw.ImageProvider>? multiImages; // NEW: support for multiple images
  final String finding;
  final String recommendation;
  final bool isSectionGroup; // NEW: flag to indicate this is a section group

  PhotoWithFinding({
    required this.photoNumber,
    required this.image,
    required this.finding,
    required this.recommendation,
    this.multiImages,
    this.isSectionGroup = false,
  });
}
