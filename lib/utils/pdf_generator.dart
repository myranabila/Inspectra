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

    // Local sanitize shortcut
    String sanitize(String? text) => PdfGenerator.sanitizeText(text);

    
    // Extract data
    final inspectionId = sanitize(inspection['inspection_id_display'] ?? inspection['equipment_id'] ?? 'N/A');
    final reportNumber = sanitize(inspection['report_number'] ?? 'N/A');
    final equipmentTag = sanitize(inspection['equipment_id'] ?? 'R-001');
    final equipmentType = sanitize(inspection['equipment_type'] ?? 'Reactor');
    final equipmentDescription = sanitize(inspection['title'] ?? equipmentType);
    final area = sanitize(inspection['area'] ?? inspection['location'] ?? 'Plant 1');
    final reportDate = DateFormat('dd MMM yyyy').format(DateTime.now());
    final inspectionDate = sanitize(reportData['inspection_date'] ?? reportDate);
    final inspectorName = sanitize(inspection['inspector_name'] ?? inspection['inspector']?['username'] ?? 'Inspector');
    final plant = area.split('>').first.trim(); // Extract plant from area
    final currentYear = DateFormat('yyyy').format(DateTime.now());
    
    // Get DOSH registration from inspection data (manually entered by manager)
    final doshRegistration = sanitize(inspection['dosh_registration'] ?? '');
    
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
               finding: sanitize(findingLines.join('\n')),
               recommendation: sanitize(recLines.join('\n')),
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
                  doshRegistration: doshRegistration, // Equipment-specific DOSH number
                  pageNumber: 1,
                  year: currentYear,
                ),
              
              pw.SizedBox(height: 12),
              
              // FINDINGS, NDT & RECOMMENDATIONS Section Header
              pw.Container(
                width: double.infinity,
                color: PdfColors.grey300,
                padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: pw.Text(
                  'FINDINGS, NDT & RECOMMENDATIONS',
                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.center,
                ),
              ),

              pw.Container(
                 padding: const pw.EdgeInsets.all(5),
                 decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black)),
                 child: pw.Column(
                   crossAxisAlignment: pw.CrossAxisAlignment.start,
                   children: [
                      // Disclaimer text (small, top of box)
                      pw.Text(
                        'Conditions: With respect to the internal surface, describe and state location of any scale, oil or other deposits... (static text)',
                        style: const pw.TextStyle(fontSize: 5, color: PdfColors.grey700),
                      ),
                      pw.Divider(color: PdfColors.black),
                      
                      // FINDINGS
                      pw.Text('FINDINGS', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline)),
                      pw.SizedBox(height: 4),
                      
                      pw.Text('Initial/Pre-Inspection - Not applicable', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 8),
                      
                      pw.Text('Post/Final Inspection', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 6),
                      
                      // External (includes Equipment)
                      pw.Text('External', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline)),
                      ..._buildDetailedFindingsList(
                          reportData: reportData, 
                          type: 'external', // Group 1
                          forcedPrefix: '1'
                      ),
                      
                      pw.SizedBox(height: 10),
                      
                      // Internal
                      if (requireInternal) ...[
                        pw.Text('Internal', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline)),
                        ..._buildDetailedFindingsList(
                            reportData: reportData, 
                            type: 'internal', // Group 2
                            forcedPrefix: '2'
                        ),
                      ],
                      
                      pw.SizedBox(height: 10),
                      
                      // NON-DESTRUCTIVE TESTINGS
                      pw.Text('NON-DESTRUCTIVE TESTINGS', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline)),
                      pw.Text('UTTM: ${sanitizeText(reportData['thickness_finding'])}', style: const pw.TextStyle(fontSize: 9)),
                      
                      pw.SizedBox(height: 10),
                      
                      // RECOMMENDATIONS
                      pw.Text('RECOMMENDATIONS', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline)),
                      ..._buildDetailedRecommendationsList(reportData: reportData),
                   ],
                 ),
              ),
              
              pw.Spacer(),
              
              // Footer with signatures
              // Footer with signatures
              _buildPage1Footer(
                inspectorName: inspectorName,
                managerName: inspection['manager_username'] ?? inspection['manager']?['username']
              ),
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
    // Weld photos - Handled via equipment_sections_data
    // if (requireWeld) { ... }
    
    // Internal photos
    // Internal photos
    // Handled via equipment_sections_data
    // if (requireInternal && (reportData['internal_accessible'] ?? false)) { ... }
    
    if (photosWithFindings.isNotEmpty) {
      // Generate photo pages
      final photoPages = _generatePhotoPages(
        photosWithFindings: photosWithFindings,
        reportNumber: reportNumber,
        plant: plant,
        reportDate: reportDate,
        equipmentTag: equipmentTag,
        equipmentDescription: equipmentDescription,
        doshRegistration: doshRegistration, // Equipment-specific DOSH number
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
    required String year,
  }) {
    // Sanitize
    plant = sanitizeText(plant);
    equipmentTag = sanitizeText(equipmentTag);
    equipmentDescription = sanitizeText(equipmentDescription);
    doshRegistration = sanitizeText(doshRegistration);
    reportNumber = sanitizeText(reportNumber);
    reportDate = sanitizeText(reportDate);

    // Style constants
    final borderBlack = pw.Border.all(color: PdfColors.black, width: 1);
    final textStyleBold = pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold);
    final textStyleNormal = const pw.TextStyle(fontSize: 9);
    final textStyleTitle = pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold);
    final textStyleSubtitle = pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold);

    return pw.Column(
      children: [
        // Top Box: Title and Report Details
        pw.Container(
          decoration: pw.BoxDecoration(border: borderBlack),
          child: pw.Row(
            children: [
               // Title Section
               pw.Expanded(
                 flex: 3,
                 child: pw.Container(
                   decoration: const pw.BoxDecoration(
                     border: pw.Border(right: pw.BorderSide(color: PdfColors.black)),
                   ),
                   padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                   child: pw.Column(
                     mainAxisAlignment: pw.MainAxisAlignment.center,
                     children: [
                       pw.Text('MAJOR TURNAROUND $year', style: textStyleTitle, textAlign: pw.TextAlign.center),
                       pw.Text('PRESSURE VESSEL INSPECTION REPORT', style: textStyleSubtitle, textAlign: pw.TextAlign.center),
                     ],
                   ),
                 ),
               ),
               // Report Details Section
               pw.Expanded(
                 flex: 1,
                 child: pw.Column(
                   children: [
                     pw.Container(
                       padding: const pw.EdgeInsets.all(5),
                       width: double.infinity,
                       decoration: const pw.BoxDecoration(
                         border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black)),
                       ),
                       child: pw.Column(
                         crossAxisAlignment: pw.CrossAxisAlignment.start,
                         children: [
                           pw.Text('Report no.:', style: const pw.TextStyle(fontSize: 8)),
                           pw.Text(reportNumber, style: textStyleBold),
                         ],
                       ),
                     ),
                     pw.Container(
                       padding: const pw.EdgeInsets.all(5),
                       width: double.infinity,
                       child: pw.Column(
                         crossAxisAlignment: pw.CrossAxisAlignment.start,
                         children: [
                           pw.Text('Report date:', style: const pw.TextStyle(fontSize: 8)),
                           pw.Text(reportDate, style: textStyleBold),
                         ],
                       ),
                     ),
                   ],
                 ),
               ),
            ],
          ),
        ),
        
        // Bottom Box: Equipment Details
        pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border(left: pw.BorderSide(color: PdfColors.black), right: pw.BorderSide(color: PdfColors.black), bottom: pw.BorderSide(color: PdfColors.black)),
          ),
          child: pw.Column(
            children: [
              // Row 1
              pw.Container(
                decoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black)),
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(5),
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(right: pw.BorderSide(color: PdfColors.black)),
                        ),
                        child: pw.RichText(text: pw.TextSpan(children: [
                          pw.TextSpan(text: 'Equipment tag no.: ', style: textStyleBold),
                          pw.TextSpan(text: equipmentTag, style: textStyleBold),
                        ])),
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.RichText(text: pw.TextSpan(children: [
                          pw.TextSpan(text: 'Plant/Unit/Area: ', style: textStyleBold),
                          pw.TextSpan(text: plant, style: textStyleNormal),
                        ])),
                      ),
                    ),
                  ],
                ),
              ),
              // Row 2
              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(5),
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(right: pw.BorderSide(color: PdfColors.black)),
                      ),
                      child: pw.RichText(text: pw.TextSpan(children: [
                        pw.TextSpan(text: 'Equipment description: ', style: textStyleBold),
                        pw.TextSpan(text: equipmentDescription, style: textStyleNormal),
                      ])),
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.RichText(text: pw.TextSpan(children: [
                        pw.TextSpan(text: 'DOSH registration no.: ', style: textStyleBold),
                        pw.TextSpan(text: doshRegistration, style: textStyleBold), // Should be empty
                      ])),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
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
      String externalFinding = (reportData['external_finding'] ?? 'No issues detected').toString().replaceAll(RegExp(r'[^\x00-\x7F]'), '-');
      String externalCondition = (reportData['external_condition'] ?? 'Satisfactory').toString().replaceAll(RegExp(r'[^\x00-\x7F]'), '-');
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
      String weldFinding = (reportData['weld_finding'] ?? 'Welds appear sound').toString().replaceAll(RegExp(r'[^\x00-\x7F]'), '-');
      String weldCondition = (reportData['weld_condition'] ?? 'Satisfactory').toString().replaceAll(RegExp(r'[^\x00-\x7F]'), '-');
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
      String internalFinding = (reportData['internal_finding'] ?? 'Internal surfaces acceptable').toString().replaceAll(RegExp(r'[^\x00-\x7F]'), '-');
      String internalCondition = (reportData['internal_condition'] ?? 'Satisfactory').toString().replaceAll(RegExp(r'[^\x00-\x7F]'), '-');
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
      String thicknessCondition = (reportData['thickness_condition'] ?? 'Satisfactory').toString().replaceAll(RegExp(r'[^\x00-\x7F]'), '-');
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

  static pw.Widget _buildPage1Footer({
    required String inspectorName,
    String? managerName,
  }) {
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
                      pw.SizedBox(height: 20),
                      if (managerName != null && managerName.isNotEmpty)
                         pw.Text(managerName, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
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
                      pw.Text('Approved by (Client):', style: const pw.TextStyle(fontSize: 8)),
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
            _buildTableCell(sanitizeText(equipmentTag)),
            _buildTableCell('Equipment Type:', bold: true),
            _buildTableCell(sanitizeText(equipmentType)),
          ],
        ),
        pw.TableRow(
          children: [
            _buildTableCell('Location/Area:', bold: true),
            _buildTableCell(sanitizeText(area)),
            _buildTableCell('Inspection Date:', bold: true),
            _buildTableCell(sanitizeText(inspectionDate)),
          ],
        ),
      ],
    );
  }

  static List<pw.Widget> _buildDetailedFindingsList({
    required Map<String, dynamic> reportData,
    required String type, 
    required String forcedPrefix,
  }) {
    List<pw.Widget> widgets = [];
    final sections = reportData['equipment_sections_data'] as List<dynamic>? ?? [];
    
    // Filter logic based on explicit 'type' field
    // External Group: 'equipment', 'external', 'weld'
    // Internal Group: 'internal'
    
    for (var section in sections) {
       String sectionType = (section['type'] ?? 'equipment').toString();
       bool isInternal = sectionType == 'internal';
       
       // If requesting 'external' list, skip internal sections
       if (type == 'external' && isInternal) continue;
       
       // If requesting 'internal' list, skip non-internal sections
       if (type == 'internal' && !isInternal) continue;
       
       List<String> findings = (section['findings'] as List<dynamic>? ?? []).cast<String>();
       
       for (var f in findings) {
         widgets.add(pw.Padding(
           padding: const pw.EdgeInsets.only(bottom: 2),
           child: pw.Text(
             PdfGenerator.sanitizeText(f),
             style: const pw.TextStyle(fontSize: 9),
           ),
         ));
       }
    }
    
    if (widgets.isEmpty) {
        widgets.add(pw.Text('Nil', style: const pw.TextStyle(fontSize: 9)));
    }
    
    return widgets;
  }

  static List<pw.Widget> _buildDetailedRecommendationsList({
    required Map<String, dynamic> reportData,
  }) {
    List<pw.Widget> widgets = [];
    final sections = reportData['equipment_sections_data'] as List<dynamic>? ?? [];
    
    for (var section in sections) {
       List<String> recs = (section['recommendations'] as List<dynamic>? ?? []).cast<String>();
       for (var r in recs) {
          // Check for Nil/nil
          if (r.toLowerCase().contains('nil')) continue;
          
          widgets.add(pw.Padding(
           padding: const pw.EdgeInsets.only(bottom: 2),
           child: pw.Text(
             PdfGenerator.sanitizeText(r),
             style: const pw.TextStyle(fontSize: 9),
           ),
         ));
       }
    }
    
    if (widgets.isEmpty) {
       widgets.add(pw.Text('To be monitored on next opportunity.', style: const pw.TextStyle(fontSize: 9)));
    }
    
    return widgets;
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
                  doshRegistration: doshRegistration, // Equipment-specific DOSH number
                  pageNumber: pageNumber,
                  year: DateFormat('yyyy').format(DateTime.now()), // Assuming current year for photo pages too
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
                      sanitizeText(photoData.finding),
                      style:
                          const pw.TextStyle(fontSize: 8, color: PdfColors.blue),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text('Recommendation:',
                        style: pw.TextStyle(
                            fontSize: 9, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline)),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      sanitizeText(photoData.recommendation),
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
                    sanitizeText(photoData.finding),
                    style:
                        const pw.TextStyle(fontSize: 9, color: PdfColors.blue),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text('Recommendation:',
                      style: pw.TextStyle(
                          fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    sanitizeText(photoData.recommendation),
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

  // ========== UTILS ==========
  static String sanitizeText(String? text) {
    if (text == null) return '';
    return text
        .replaceAll('–', '-')
        .replaceAll('—', '-')
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll('‘', "'")
        .replaceAll('’', "'")
        .replaceAll('•', '*')
        .replaceAll(RegExp(r'\u00A0'), ' ') // Non-breaking space
        .replaceAll(RegExp(r'[^\x00-\x7F]'), ' '); // Strip any other non-ASCII
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
