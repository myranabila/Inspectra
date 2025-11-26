import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart'; 

import 'providers/inspector_provider.dart';
// Note: Ensure your MediaItem model file path is correct
import 'models/media_item.dart'; 

// --- DATA MODEL PLACEHOLDERS/MOCK DATA ---

// Helper definitions to infer type based on file extension
const String imageType = 'jpg';
const String documentType = 'pdf';


final List<MediaItem> mockMediaItems = [
  MediaItem(
    id: '1', name: 'building-a-floor-3.jpg', size: '2.3 MB',
    date: DateTime.now().subtract(const Duration(days: 20)),
    tags: ['structure', 'building-a'], type: imageType, url: 'MOCK_URL_1',
  ),
  MediaItem(
    id: '2', name: 'electrical-panel-system.jpg', size: '1.8 MB',
    date: DateTime.now().subtract(const Duration(days: 22)),
    tags: ['electrical', 'panel'], type: imageType, url: 'MOCK_URL_2',
  ),
  MediaItem(
    id: '3', name: 'hvac-unit-block-b.jpg', size: '2.1 MB',
    date: DateTime.now().subtract(const Duration(days: 23)),
    tags: ['hvac', 'mechanical'], type: imageType, url: 'MOCK_URL_3',
  ),
  MediaItem(
    id: '4', name: 'floor-plan-level-3.pdf', size: '3.5 MB',
    date: DateTime.now().subtract(const Duration(days: 24)),
    tags: ['document', 'plan'], type: documentType, url: 'MOCK_URL_4',
  ),
];


// =========================================================================
// --- WIDGETS DEFINED AT TOP LEVEL ---
// =========================================================================

// 1. Upload View (Stateful content)
class UploaderView extends StatefulWidget {
  const UploaderView({super.key});

  @override
  State<UploaderView> createState() => _UploaderViewState();
}

class _UploaderViewState extends State<UploaderView> {
  String _uploadStatus = 'Ready to upload.';
  Color _statusColor = Colors.green;
  List<PlatformFile> _selectedFiles = []; 

  // --- FILE PICKING IMPLEMENTATION ---
  Future<void> _pickFile() async {
    setState(() {
      _uploadStatus = 'Opening file picker...';
      _statusColor = Colors.orange;
    });
    
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'png', 'jpeg', 'pdf', 'doc', 'docx', 'xlsx'],
        allowMultiple: true,
        withData: true, 
      );

      if (!mounted) return;

      if (result != null && result.files.isNotEmpty) {
        
        setState(() {
          _selectedFiles = result.files;
          int count = _selectedFiles.length;
          _uploadStatus = 'Selected $count file(s). Ready to process.';
          _statusColor = Colors.blue;
        });
        
      } else {
        setState(() {
          _selectedFiles = [];
          _uploadStatus = 'Selection cancelled.';
          _statusColor = Colors.red;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _uploadStatus = 'Error picking file: $e';
        _statusColor = Colors.red;
        debugPrint('File picker error: $e');
      });
    }
  }

  // --- LIVE UPLOAD IMPLEMENTATION ---
  Future<void> _startUpload() async {
    if (_selectedFiles.isEmpty) return; 

    setState(() {
      _uploadStatus = 'Uploading ${_selectedFiles.length} file(s) to Firebase Storage...';
      _statusColor = Colors.orange.shade800;
    });

    final provider = Provider.of<InspectorProvider>(context, listen: false);
    
    try {
      // NOTE: This call is defined in InspectorProvider
      await provider.uploadMediaFiles(_selectedFiles); 

      if (!mounted) return;

      setState(() {
        _uploadStatus = 'Upload Complete! Files processed and saved to Firestore.';
        _statusColor = Colors.teal.shade700;
        _selectedFiles = []; 
      });
      
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _uploadStatus = 'Upload failed! Error: ${e.toString().substring(0, 50)}...';
        _statusColor = Colors.red;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InspectorProvider>();
    final userName = provider.inspectorUser?.name ?? 'Inspector';
    final fileCount = _selectedFiles.length;

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Welcome, $userName!', 
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Upload Photos & Documents for Inspection Jobs',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const Divider(height: 40),

              // --- Upload Area (Clickable) ---
              GestureDetector(
                onTap: _pickFile, 
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    border: Border.all(
                      color: Colors.blue.shade200, 
                      style: BorderStyle.solid
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_upload, size: 60, color: Colors.blue.shade400),
                      const SizedBox(height: 10),
                      Text(
                        'Click or tap to select files.',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // --- Action Button: Select Files ---
              ElevatedButton.icon(
                onPressed: _pickFile, 
                icon: const Icon(Icons.photo_library),
                label: const Text('SELECT FILES'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),

              // --- Conditional Proceed/Upload Button ---
              if (fileCount > 0) 
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: ElevatedButton.icon(
                    onPressed: _startUpload, 
                    icon: const Icon(Icons.cloud_upload_sharp),
                    label: Text('PROCEED & UPLOAD $fileCount FILE(S)'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.teal.shade500,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

              const SizedBox(height: 20),
              // Display dynamic status based on state
              Text(_uploadStatus, 
                textAlign: TextAlign.center, 
                style: TextStyle(color: _statusColor)
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// 2. Media Library View (The new grid structure)
class MediaLibraryView extends StatelessWidget {
  final List<MediaItem> items;
  final String typeFilter; 
  
  const MediaLibraryView({required this.items, required this.typeFilter, super.key});

  List<MediaItem> get _filteredItems {
    if (typeFilter == 'All') return items;
    if (typeFilter == 'image') {
      return items.where((i) => ['jpg', 'png', 'jpeg'].contains(i.type.toLowerCase())).toList();
    }
    if (typeFilter == 'document') {
      return items.where((i) => ['pdf', 'doc', 'docx', 'xlsx'].contains(i.type.toLowerCase())).toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final displayItems = _filteredItems;

    if (displayItems.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Text("No media items found for this filter. Upload some!"),
      ));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4, 
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.7, 
        ),
        itemCount: displayItems.length,
        itemBuilder: (context, index) {
          final item = displayItems[index];
          return MediaCard(item: item);
        },
      ),
    );
  }
}

// 3. Media Card for Grid Item
class MediaCard extends StatelessWidget {
  final MediaItem item;
  
  const MediaCard({required this.item, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPdf = item.type.toLowerCase() == 'pdf';
    
    // Format date: 11/4/2025
    final dateString = '${item.date.month}/${item.date.day}/${item.date.year % 100}';
    final sizeString = item.size; 

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade300)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Preview Area ---
          Expanded(
            child: Container(
              alignment: Alignment.center,
              width: double.infinity,
              color: Colors.grey.shade100, 
              child: isPdf
                  ? Stack( 
                      alignment: Alignment.center,
                      children: [
                        const Icon(Icons.picture_as_pdf, size: 48, color: Colors.red),
                        const Positioned(
                          bottom: 5,
                          child: Text('PDF', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                        )
                      ],
                    )
                  : const Icon(Icons.image_outlined, size: 48, color: Colors.grey),
            ),
          ),
          
          // --- Details ---
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(sizeString, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600)),
                    Text(dateString, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600)),
                  ],
                ),
                const SizedBox(height: 8),
                // --- Tags ---
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: item.tags.map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 25), 
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(tag, style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, color: theme.colorScheme.primary, fontWeight: FontWeight.w500)),
                  )).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


// 4. Main UploadScreen (Tab Host)

class UploadScreen extends StatelessWidget {
  const UploadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // You only need to read the provider in the build method here
    final provider = context.read<InspectorProvider>(); 

    return DefaultTabController(
      length: 2, // Upload | Library
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Media Manager'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/'), 
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Uploader'),
              Tab(text: 'Media Library'),
            ],
            // Styling to match the uploaded image's tab design
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorSize: TabBarIndicatorSize.tab,
          ),
        ),
        backgroundColor: Colors.grey.shade100,
        body: TabBarView(
          children: [
            // Tab 1: Uploader View
            SingleChildScrollView(
              padding: const EdgeInsets.only(top: 32),
              child: Center(
                child: Container(
                  width: 600,
                  constraints: const BoxConstraints(minHeight: 500),
                  child: const UploaderView(),
                ),
              ),
            ),
            
            // Tab 2: Media Library View 
            MediaLibraryHost(provider: provider),
          ],
        ),
      ),
    );
  }
}

// 5. Separate Widget to host the Library and its nested tabs
class MediaLibraryHost extends StatelessWidget {
  final InspectorProvider provider;
  const MediaLibraryHost({required this.provider, super.key});

  @override
  Widget build(BuildContext context) {
    final mediaStream = provider.mediaStream;
    
    if (mediaStream == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return DefaultTabController(
      length: 3, // All, Images, Documents
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row (Media Library text, Search, Grid/List Toggle)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Media Library', style: Theme.of(context).textTheme.titleLarge),
                const Row(
                  children: [
                    SizedBox(
                      width: 250,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search files...',
                          prefixIcon: Icon(Icons.search, size: 20),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                          isDense: true,
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Icon(Icons.grid_view, color: Colors.grey, size: 20),
                    Icon(Icons.more_vert, color: Colors.grey, size: 20),
                  ],
                ),
              ],
            ),
          ),
          
          // Filter Tabs (All, Images, Documents)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(left: 16.0),
            child: const TabBar(
              tabs: [
                Tab(text: 'All'),
                Tab(text: 'Images'),
                Tab(text: 'Documents'),
              ],
              isScrollable: true,
              labelPadding: EdgeInsets.symmetric(horizontal: 16.0),
              indicatorSize: TabBarIndicatorSize.label,
              indicatorColor: Colors.blue,
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
            ),
          ),
          
          // Content Area (The actual grid)
          Expanded(
            child: StreamBuilder<List<MediaItem>>(
              stream: mediaStream, // Use the live stream
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading media: ${snapshot.error}'));
                }
                final allItems = snapshot.data ?? [];

                return TabBarView(
                  children: [
                    // Tab 1: All
                    MediaLibraryView(items: allItems, typeFilter: 'All'),
                    // Tab 2: Images
                    MediaLibraryView(items: allItems, typeFilter: 'image'),
                    // Tab 3: Documents
                    MediaLibraryView(items: allItems, typeFilter: 'document'),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}