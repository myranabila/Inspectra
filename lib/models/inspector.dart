import 'package:cloud_firestore/cloud_firestore.dart';

class Inspector {
  final String id, name, email, phone, badge;
  Inspector({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.badge,
  });

  factory Inspector.fromFirestore(DocumentSnapshot<Map<String,dynamic>> d) =>
      Inspector(
        id: d.id,
        name:  d.data()?['name']  ?? '',
        email: d.data()?['email'] ?? '',
        phone: d.data()?['phone'] ?? '',
        badge: d.data()?['badge'] ?? '',
      );

  Map<String,dynamic> toMap() =>
      {'name':name,'email':email,'phone':phone,'badge':badge};
}