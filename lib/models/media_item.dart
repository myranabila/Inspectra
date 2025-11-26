import 'package:cloud_firestore/cloud_firestore.dart';

class MediaItem {
  final String id;
  final String name;
  final String type; // e.g., 'jpg', 'pdf'
  final String size; // e.g., '2.30 MB'
  final DateTime date;
  final List<String> tags;
  final String url; // <-- NEW: Firebase Storage Download URL

  MediaItem({
    required this.id,
    required this.name,
    required this.type,
    required this.size,
    required this.date,
    required this.tags,
    required this.url, // <-- Added to constructor
  });

  // --- Factory Constructor for Reading from Firestore ---
  factory MediaItem.fromFirestore(DocumentSnapshot<Map<String, dynamic>> d) {
    final data = d.data();
    return MediaItem(
      id: d.id,
      name: data?['name'] ?? 'Unknown File',
      type: data?['type'] ?? 'other',
      size: data?['size'] ?? '0 MB',
      date: (data?['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      tags: List<String>.from(data?['tags'] ?? []),
      url: data?['url'] ?? '', // <-- Reading URL from Firestore
    );
  }

  // --- Method for Writing to Firestore ---
  Map<String, dynamic> toFirestore(String uid) => {
    'name': name,
    'type': type,
    'size': size,
    'date': Timestamp.fromDate(date),
    'tags': tags,
    'userId': uid,
    'url': url, // <-- Writing URL to Firestore
  };
}