import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'theme/app_theme.dart';
import 'inspection_review_page.dart';

class InspectionWorkflowPage extends StatefulWidget {
  final Map<String, dynamic> inspection;

  const InspectionWorkflowPage({
    super.key,
    required this.inspection,
  });

  @override
  State<InspectionWorkflowPage> createState() => _InspectionWorkflowPageState();
}

class _InspectionWorkflowPageState extends State<InspectionWorkflowPage> {
  String? _selectedMode;
  
  // Photo upload with metadata
  final ImagePicker _picker = ImagePicker();
  List<XFile> _selectedImages = [];
  
  // Per-photo metadata: componentType, conditionStatus, inspectorComment
  List<Map<String, String?>> _photoMetadata = [];
  
  // Component type options
  final List<String> _componentTypes = [
    'Shell',
    'Head/Dish',
    'Nozzle',
    'Manway',
    'Support/Saddle',
    'Insulation',
    'Piping Connection',
    'Flange',
    'Bolting',
    'Foundation',
    'Nameplate',
    'Safety Valve',
    'Other',
  ];
  
  // Condition status options
  final List<String> _conditionStatuses = [
    'Satisfactory',
    'Minor Corrosion',
    'Moderate Corrosion',
    'Severe Corrosion',
    'Deformation',
    'Crack Detected',
    'Leakage',
    'Damaged',
    'Requires Attention',
    'Nil',
  ];
  
  bool _isLoading = false;

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (images.isNotEmpty) {
        // Limit to 50 photos
        if (_selectedImages.length + images.length > 50) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Maximum 50 photos allowed. You can add ${50 - _selectedImages.length} more photos.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
          
          // Add only up to the limit
          final remainingSlots = 50 - _selectedImages.length;
          setState(() {
            _selectedImages.addAll(images.take(remainingSlots));
            // Initialize metadata for new images
            for (var i = 0; i < remainingSlots; i++) {
              _photoMetadata.add({
                'componentType': null,
                'conditionStatus': null,
                'comment': '',
              });
            }
          });
        } else {
          setState(() {
            _selectedImages.addAll(images);
            // Initialize metadata for new images
            for (var i = 0; i < images.length; i++) {
              _photoMetadata.add({
                'componentType': null,
                'conditionStatus': null,
                'comment': '',
              });
            }
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking images: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      _photoMetadata.removeAt(index);
    });
  }

  Future<void> _performAIInspection() async {
    // Show coming soon message
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.smart_toy, color: Colors.blue),
              SizedBox(width: 12),
              Text('AI Analysis - Coming Soon'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI-powered photo analysis is currently under development.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                'This feature will automatically:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Identify component types from photos'),
              Text('• Detect condition status automatically'),
              Text('• Generate inspection observations'),
              Text('• Create professional findings & recommendations'),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'For now, please use Manual Mode to enter inspection data.',
                        style: TextStyle(color: Colors.blue.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Switch to manual mode
                setState(() => _selectedMode = 'manual');
              },
              child: Text('Switch to Manual Mode'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _proceedToReview() async {
    // Validate that photos have been uploaded
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload at least one photo'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate that all photos have complete metadata
    for (int i = 0; i < _photoMetadata.length; i++) {
      if (_photoMetadata[i]['componentType'] == null || 
          _photoMetadata[i]['conditionStatus'] == null || 
          (_photoMetadata[i]['comment']?.trim().isEmpty ?? true)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please complete all fields for Photo ${i + 1}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // Convert photos to bytes with metadata for PDF
    List<Map<String, dynamic>> photoData = [];
    for (int i = 0; i < _selectedImages.length; i++) {
      try {
        final bytes = await _selectedImages[i].readAsBytes();
        photoData.add({
          'bytes': bytes,
          'name': _selectedImages[i].name,
          'componentType': _photoMetadata[i]['componentType'],
          'conditionStatus': _photoMetadata[i]['conditionStatus'],
          'comment': _photoMetadata[i]['comment'],
        });
      } catch (e) {
        print('Error reading image: $e');
      }
    }

    // Navigate to review page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InspectionReviewPage(
          inspection: widget.inspection,
          photoCount: _selectedImages.length,
          photoData: photoData,
          inspectionMode: _selectedMode ?? 'manual',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Inspection Workflow',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: AppTheme.inspectorPrimary,
        foregroundColor: Colors.white,
      ),
      body: _selectedMode == null
          ? _buildModeSelection()
          : _buildInspectionForm(),
    );
  }

  Widget _buildModeSelection() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.checklist_rtl,
              size: 80,
              color: AppTheme.inspectorPrimary,
            ),
            const SizedBox(height: 24),
            const Text(
              'Select Inspection Mode',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.inspection['title'] ?? 'Inspection Task',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            
            // AI Mode Card
            Card(
              elevation: 4,
              child: InkWell(
                onTap: () {
                  setState(() => _selectedMode = 'AI');
                  _performAIInspection();
                },
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.smart_toy,
                          size: 40,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'AI Inspection Mode',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.orange),
                                  ),
                                  child: Text(
                                    'COMING SOON',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange.shade900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'AI will analyze photos and auto-generate findings (In Development)',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 20),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Manual Mode Card
            Card(
              elevation: 4,
              child: InkWell(
                onTap: () {
                  setState(() => _selectedMode = 'Manual');
                },
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.edit_note,
                          size: 40,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 20),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Manual Inspection Mode',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Manually enter all inspection findings',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInspectionForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Inspection Details Card (Read-only)
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppTheme.inspectorPrimary),
                      const SizedBox(width: 8),
                      const Text(
                        'Inspection Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedMode == 'AI'
                              ? Colors.blue.withValues(alpha: 0.1)
                              : Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _selectedMode == 'AI' ? 'AI MODE' : 'MANUAL MODE',
                          style: TextStyle(
                            color: _selectedMode == 'AI' ? Colors.blue : Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _buildReadOnlyField('Title', widget.inspection['title'] ?? 'N/A'),
                  const SizedBox(height: 12),
                  _buildReadOnlyField('Location', widget.inspection['location'] ?? 'N/A'),
                  const SizedBox(height: 12),
                  if (widget.inspection['equipment_id'] != null || widget.inspection['equipment_type'] != null) ...[
                    _buildReadOnlyField('Equipment ID', widget.inspection['equipment_id'] ?? 'N/A'),
                    const SizedBox(height: 12),
                    _buildReadOnlyField('Equipment Type', widget.inspection['equipment_type'] ?? 'N/A'),
                    const SizedBox(height: 12),
                  ],
                  _buildReadOnlyField('Date', widget.inspection['scheduled_date'] ?? 'N/A'),
                  const SizedBox(height: 12),
                  if (widget.inspection['notes'] != null && 
                      widget.inspection['notes'].toString().isNotEmpty)
                    _buildReadOnlyField('Manager Notes', widget.inspection['notes']),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Photo Upload Section
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.photo_library, color: AppTheme.inspectorPrimary),
                      const SizedBox(width: 8),
                      const Text(
                        'Inspection Photos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_selectedImages.length}/50',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _selectedImages.length >= 50 ? Colors.red : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Upload inspection photos (maximum 50 photos)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Photo Grid
                  if (_selectedImages.isNotEmpty)
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _selectedImages.length,
                      itemBuilder: (context, index) {
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: const Icon(Icons.image, size: 40, color: Colors.grey),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: InkWell(
                                onTap: () => _removeImage(index),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Upload Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _selectedImages.length < 50 ? _pickImages : null,
                      icon: const Icon(Icons.add_photo_alternate),
                      label: Text(_selectedImages.isEmpty ? 'Upload Photos' : 'Add More Photos'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        foregroundColor: AppTheme.inspectorPrimary,
                      ),
                    ),
                  ),
                  
                  if (_selectedMode == 'AI' && _selectedImages.isNotEmpty && !_isLoading) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _performAIInspection,
                        icon: const Icon(Icons.smart_toy),
                        label: const Text('AI Analysis (Coming Soon)'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Photo Metadata Section - Per-Photo Inputs
          if (_selectedImages.isNotEmpty) ...[
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.photo_library, color: AppTheme.inspectorPrimary),
                        SizedBox(width: 8),
                        Text(
                          'Photo Details *',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Complete the required information for each uploaded photo',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const Divider(height: 24),
                    
                    // List of photo metadata inputs
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _selectedImages.length,
                      separatorBuilder: (context, index) => const Divider(height: 32),
                      itemBuilder: (context, index) {
                        return _buildPhotoMetadataCard(index);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          
          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() => _selectedMode = null);
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Change Mode'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    foregroundColor: AppTheme.inspectorPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _proceedToReview,
                  icon: const Icon(Icons.preview),
                  label: const Text('Review Report'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: AppTheme.inspectorPrimary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
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

  Widget _buildPhotoMetadataCard(int index) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.inspectorPrimary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Photo ${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedImages[index].name,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Component Type Dropdown
          DropdownButtonFormField<String>(
            value: _photoMetadata[index]['componentType'],
            decoration: InputDecoration(
              labelText: 'Component Type *',
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: _componentTypes.map((String type) {
              return DropdownMenuItem<String>(
                value: type,
                child: Text(type, style: const TextStyle(fontSize: 13)),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _photoMetadata[index]['componentType'] = newValue;
              });
            },
          ),
          
          const SizedBox(height: 12),
          
          // Condition Status Dropdown
          DropdownButtonFormField<String>(
            value: _photoMetadata[index]['conditionStatus'],
            decoration: InputDecoration(
              labelText: 'Condition Status *',
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: _conditionStatuses.map((String status) {
              return DropdownMenuItem<String>(
                value: status,
                child: Text(status, style: const TextStyle(fontSize: 13)),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _photoMetadata[index]['conditionStatus'] = newValue;
              });
            },
          ),
          
          const SizedBox(height: 12),
          
          // Inspector Comment TextField
          TextField(
            onChanged: (value) {
              setState(() {
                _photoMetadata[index]['comment'] = value;
              });
            },
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Inspector Observation *',
              hintText: 'Enter your detailed observation for this photo',
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(12),
            ),
            controller: TextEditingController(
              text: _photoMetadata[index]['comment'] ?? '',
            )..selection = TextSelection.fromPosition(
              TextPosition(offset: (_photoMetadata[index]['comment'] ?? '').length),
            ),
          ),
        ],
      ),
    );
  }
}
