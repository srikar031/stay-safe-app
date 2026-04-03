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
  
  List<Map<String, dynamic>> _contacts = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  void _loadContacts() async {
    setState(() => _loading = true);
    try {
      final snapshot = await _database.userCollection.doc(FirebaseAuth.instance.currentUser!.uid).get();
      if (snapshot.exists) {
        final userData = snapshot.data() as Map<String, dynamic>;
        final List<dynamic> contactsData = userData['emergencyContacts'] ?? [];
        
        setState(() {
          _contacts = contactsData.map((contact) {
            final contactMap = contact as Map;
            return Map<String, dynamic>.from({
              'name': contactMap['name'] as String? ?? '',
              'phone': contactMap['phone'] as String? ?? '',
              'relationship': contactMap['relationship'] as String? ?? 'Family',
              'isActive': contactMap['isActive'] as bool? ?? true,
            });
          }).toList();
        });
      }
    } catch (e) {
      debugPrint("Error loading contacts: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _addContact() {
    showDialog(
      context: context,
      builder: (context) => AddContactDialog(
        onAdd: (name, phone, relationship) {
          setState(() {
            _contacts.add(Map<String, dynamic>.from({
              'name': name,
              'phone': phone,
              'relationship': relationship,
              'isActive': true,
            }));
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
        relationship: _contacts[index]['relationship'],
        onAdd: (name, phone, relationship) {
          setState(() {
            _contacts[index] = Map<String, dynamic>.from({
              'name': name,
              'phone': phone,
              'relationship': relationship,
              'isActive': _contacts[index]['isActive'],
            });
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

  void _toggleContact(int index, bool value) {
    setState(() {
      _contacts[index]['isActive'] = value;
    });
    _saveContacts();
  }

  void _saveContacts() async {
    try {
      final List<Map<String, dynamic>> contactsToSave = _contacts.map((c) {
        return Map<String, dynamic>.from(c);
      }).toList();

      await _database.updateEmergencyContacts(contactsToSave);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contacts updated successfully')),
        );
      }
    } catch (e) {
      debugPrint("Save error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save contacts: $e')),
        );
      }
    }
  }

  void _showInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Safety Circle'),
        content: const Text(
          'Your Safety Circle consists of trusted individuals who will be notified immediately via SMS if you trigger an SOS. '
          'They will receive your real-time GPS location and a distress message.'
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Got it'))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF02579C)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Safety Circle', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.info_outline, color: Color(0xFF02579C)), onPressed: _showInfo),
        ],
      ),
      body: _loading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                color: const Color(0xFF02579C).withValues(alpha: 0.05),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFF02579C).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.shield_outlined, color: Color(0xFF02579C), size: 32),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Emergency Contacts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          SizedBox(height: 4),
                          Text('These trusted individuals are your "Safety Circle." They will be notified if you trigger an SOS.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('CURRENT CIRCLE', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
                    Text('${_contacts.length} / 5 Contacts', style: const TextStyle(color: Color(0xFF02579C), fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),

              Expanded(
                child: _contacts.isEmpty
                    ? const Center(child: Text('Your circle is empty'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _contacts.length,
                        itemBuilder: (context, index) => _buildContactCard(index),
                      ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: OutlinedButton.icon(
                  onPressed: _contacts.length >= 5 ? null : _addContact,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 60),
                    side: BorderSide(color: Colors.grey[300]!, width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.person_add_outlined, color: Color(0xFF02579C)),
                  label: Text(_contacts.length >= 5 ? 'Circle Full' : 'Add New Contact', style: const TextStyle(color: Color(0xFF02579C), fontWeight: FontWeight.bold)),
                ),
              ),

              Container(
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.red[100]!)),
                child: Row(
                  children: [
                    const Icon(Icons.emergency_outlined, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('SOS Protocol', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('Your safety circle will receive a direct link to your live GPS coordinates.', style: TextStyle(color: Colors.red[700], fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF02579C),
        unselectedItemColor: Colors.grey,
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) Navigator.pushReplacementNamed(context, '/home');
          if (index == 1) Navigator.pushReplacementNamed(context, '/map');
          if (index == 3) Navigator.pushReplacementNamed(context, '/profile');
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'Safety Map'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Circle'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildContactCard(int index) {
    final contact = _contacts[index];
    return Dismissible(
      key: Key(contact['phone']),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => _deleteContact(index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[100]!)),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFF02579C).withValues(alpha: 0.1),
              child: const Icon(Icons.person, color: Color(0xFF02579C), size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(child: Text(contact['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
                        child: Text(contact['relationship']!.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                      ),
                    ],
                  ),
                  Text(contact['isActive'] ? 'Alerts On' : 'Alerts Disabled', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ),
            Switch(
              value: contact['isActive'],
              activeThumbColor: const Color(0xFF02579C),
              onChanged: (val) => _toggleContact(index, val),
            ),
            IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.grey), onPressed: () => _editContact(index)),
          ],
        ),
      ),
    );
  }
}