import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:stay_safe_app/screens/add_contact_dialog.dart';
import 'package:stay_safe_app/services/database_service.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  final DatabaseService _database = DatabaseService(uid: FirebaseAuth.instance.currentUser!.uid);
  
  List<Map<String, String>> _contacts = [];
  final bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  void _loadContacts() async {
    final snapshot = await _database.userCollection.doc(FirebaseAuth.instance.currentUser!.uid).get();
    if (snapshot.exists) {
      final userData = snapshot.data() as Map<String, dynamic>;
      final List<dynamic> contactsData = userData['emergencyContacts'] ?? [];
      
      setState(() {
        _contacts = contactsData.map((contact) {
          final contactMap = contact as Map;
          return {
            'name': contactMap['name'] as String? ?? '',
            'phone': contactMap['phone'] as String? ?? '',
          };
        }).toList();
      });
    }
  }

  void _addContact() {
    showDialog(
      context: context,
      builder: (context) => AddContactDialog(
        onAdd: (name, phone) {
          setState(() {
            _contacts.add({'name': name, 'phone': phone});
          });
          _saveContacts();
        },
      ),
    );
  }

  void _editContact(int index) {
    showDialog(
      context: context,
      builder: (context) => AddContactDialog(
        name: _contacts[index]['name'],
        phone: _contacts[index]['phone'],
        onAdd: (name, phone) {
          setState(() {
            _contacts[index] = {'name': name, 'phone': phone};
          });
          _saveContacts();
        },
      ),
    );
  }

  void _deleteContact(int index) {
    setState(() {
      _contacts.removeAt(index);
    });
    _saveContacts();
  }

  void _saveContacts() async {
    await _database.updateEmergencyContacts(_contacts);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
        backgroundColor: Colors.red,
      ),
      body: Column(
        children: [
          Expanded(
            child: _contacts.isEmpty
                ? const Center(
                    child: Text(
                      'No emergency contacts added yet.\nTap + to add a contact.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: _contacts.length,
                    itemBuilder: (context, index) {
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.red,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          title: Text(_contacts[index]['name']!),
                          subtitle: Text(_contacts[index]['phone']!),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _editContact(index),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteContact(index),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 50),
              ),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Add Emergency Contact',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              onPressed: _addContact,
            ),
          ),
        ],
      ),
    );
  }
}