import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final String uid;
  DatabaseService({required this.uid});

  final CollectionReference userCollection = FirebaseFirestore.instance.collection('users');
  final CollectionReference emergencyCollection = FirebaseFirestore.instance.collection('emergencies');

  Future updateUserData(String name, String email, String customMessage, String country, {
    String? profileImageUrl,
    bool? aiProcessing,
    double? soundSensitivity,
    int? sosDelay,
  }) async {
    final Map<String, dynamic> data = {
      'name': name,
      'email': email,
      'customMessage': customMessage,
      'country': country,
    };
    if (profileImageUrl != null) data['profileImageUrl'] = profileImageUrl;
    if (aiProcessing != null) data['aiProcessing'] = aiProcessing;
    if (soundSensitivity != null) data['soundSensitivity'] = soundSensitivity;
    if (sosDelay != null) data['sosDelay'] = sosDelay;

    return await userCollection.doc(uid).set(data, SetOptions(merge: true));
  }

  Stream<DocumentSnapshot> get userData {
    return userCollection.doc(uid).snapshots();
  }

  Future updateEmergencyContacts(List<Map<String, dynamic>> contacts) async {
    try {
      // Create a fresh list of standard Maps to ensure no subtype issues
      final List<Map<String, dynamic>> dataToSave = [];
      for (var c in contacts) {
        dataToSave.add({
          'name': c['name'].toString(),
          'phone': c['phone'].toString(),
          'relationship': c['relationship'].toString(),
          'isActive': c['isActive'] == true,
        });
      }

      print('Saving contacts for UID: $uid');
      return await userCollection.doc(uid).update({
        'emergencyContacts': dataToSave,
      });
    } catch (e) {
      print('Database Error: $e');
      // If update fails (e.g. field doesn't exist), try set with merge
      return await userCollection.doc(uid).set({
        'emergencyContacts': contacts,
      }, SetOptions(merge: true));
    }
  }

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

  Future updateEmergencyStatus(String emergencyId, String status) async {
    return await emergencyCollection.doc(emergencyId).update({
      'status': status,
      'resolvedAt': Timestamp.now(),
    });
  }
}
