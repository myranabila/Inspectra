import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
// Adjust import path as necessary based on your folder structure
import '../models/media_item.dart'; 

// --- Data Model Placeholder (UPDATED) ---
class InspectorUser {
  final String uid;
  final String name;
  final String role;
  // NEW FIELDS for Profile Screen
  final String fullName;
  final String phone;
  
  InspectorUser({
    required this.uid, required this.name, required this.role,
    required this.fullName, required this.phone, // ADDED
  });

  factory InspectorUser.fromFirestore(String uid, Map<String, dynamic> data) {
    return InspectorUser(
      uid: uid,
      name: data['name'] ?? 'Guest User',
      role: data['role'] ?? 'Inspector',
      // MAPPING NEW FIELDS
      fullName: data['fullName'] ?? data['name'] ?? 'N/A', 
      phone: data['phone'] ?? 'N/A',
    );
  }
}

// --------------------------------------------------------------------------
// --- Provider Class: InspectorProvider ---
// --------------------------------------------------------------------------
class InspectorProvider extends ChangeNotifier {
  // --- Firebase Service References ---
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // --- STATE ---
  User? _firebaseUser = FirebaseAuth.instance.currentUser;
  InspectorUser? _inspectorUser;
  bool _isLoading = true;
  Stream<List<MediaItem>>? _mediaStream; 

  // --- CONSTANTS/GETTERS ---
  User? get firebaseUser => _firebaseUser;
  InspectorUser? get inspectorUser => _inspectorUser;
  bool get isLoading => _isLoading;
  String get uid => _firebaseUser?.uid ?? 'debug-inspector-uid-001';
  Stream<List<MediaItem>>? get mediaStream => _mediaStream;

  // --- CONSTRUCTOR ---
  InspectorProvider() {
    _initUserListener();
  }

  // --- INITIALIZATION & LISTENERS ---
  void _initUserListener() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      _firebaseUser = user;
      
      if (user != null) {
        _fetchInspectorUserDetails(user.uid);
        _initializeMediaStream(user.uid); 
      } else {
        _fetchInspectorUserDetails(uid); 
        _initializeMediaStream(uid); 
      }
    });
    
    // Initial load upon startup
    if (_firebaseUser != null || _inspectorUser == null) {
       _fetchInspectorUserDetails(uid);
       _initializeMediaStream(uid);
    }
  }

  // --- MEDIA STREAM INITIALIZATION ---
  void _initializeMediaStream(String userId) {
    _mediaStream = _db.collection('media')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MediaItem.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
            .toList());
    notifyListeners();
  }


  // --- LIVE UPLOAD FUNCTIONALITY ---
  Future<void> uploadMediaFiles(List<PlatformFile> files) async {
    final userId = uid; 
    
    for (var file in files) {
      if (file.bytes == null) continue;
      
      // 1. Upload file to Firebase Storage
      final storageRef = _storage.ref().child('uploads/$userId/${DateTime.now().millisecondsSinceEpoch}_${file.name}');
      final uploadTask = storageRef.putData(file.bytes!);
      
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      // 2. Prepare metadata to save to Firestore
      final newMediaItem = MediaItem(
        id: '', // Firestore generates ID
        name: file.name, 
        type: file.extension ?? 'other', 
        // File size is guaranteed non-null int by file_picker, so no '!' needed
        size: '${(file.size / 1024 / 1024).toStringAsFixed(2)} MB', 
        date: DateTime.now(),
        tags: ['uploaded'], 
        url: downloadUrl, // Store URL
      );
      
      // 3. Save metadata to Firestore
      await _db.collection('media').add(newMediaItem.toFirestore(userId));
    }
  }

  // --- USER DATA FETCHING ---
  Future<void> _fetchInspectorUserDetails(String userId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(userId).get();
      
      if (doc.exists) {
        _inspectorUser = InspectorUser.fromFirestore(
          doc.id, 
          doc.data() as Map<String, dynamic>
        );
      } else {
        // Fallback for when the document does not exist (e.g., debug ID or new sign-up)
        _inspectorUser = InspectorUser(
          uid: userId, 
          name: 'Debug User', 
          role: 'Viewer',
          fullName: 'Development Account',
          phone: 'N/A',
        );
      }
    } catch (e) {
      // This catch block is what causes the 'Welcome, Error!' message if data fetch fails.
      _inspectorUser = InspectorUser(
        uid: userId, 
        name: 'Error', 
        role: 'Error',
        fullName: 'Error Loading',
        phone: 'Error',
      );
      debugPrint('Error fetching user data for UID $userId: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- ACTIONS ---
  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }
}