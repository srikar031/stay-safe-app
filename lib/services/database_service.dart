import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final String uid;
  DatabaseService({required this.uid});

  // Collection reference
  final CollectionReference userCollection = FirebaseFirestore.instance.collection('users');
  final CollectionReference emergencyCollection = FirebaseFirestore.instance.collection('emergencies');

  // Update user data
  Future updateUserData(String name, String email, String customMessage, String country) async {
    return await userCollection.doc(uid).set({
      'name': name,
      'email': email,
      'customMessage': customMessage,
      'country': country,
      'emergencyContacts': [],
    });
  }

  // Get user data stream
  Stream<DocumentSnapshot> get userData {
    return userCollection.doc(uid).snapshots();
  }

  // Update emergency contacts
  Future updateEmergencyContacts(List<Map<String, String>> contacts) async {
    return await userCollection.doc(uid).update({'emergencyContacts': contacts});
  }

  // Update custom message
  Future updateCustomMessage(String message) async {
    return await userCollection.doc(uid).update({'customMessage': message});
  }

  // Update country
  Future updateCountry(String country) async {
    return await userCollection.doc(uid).update({'country': country});
  }

  // Create emergency record
  Future createEmergencyRecord(Map<String, dynamic> emergencyData) async {
    return await emergencyCollection.add({
      'userId': uid,
      'timestamp': Timestamp.now(),
      'location': emergencyData['location'],
      'status': 'active',
      'message': emergencyData['message'],
      'contactsNotified': emergencyData['contactsNotified'],
    });
  }

  // Update emergency status
  Future updateEmergencyStatus(String emergencyId, String status) async {
    return await emergencyCollection.doc(emergencyId).update({'status': status});
  }
}