import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_picker/country_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:stay_safe_app/auth_service.dart';
import 'package:stay_safe_app/services/database_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _auth = AuthService();
  final DatabaseService _database = DatabaseService(uid: FirebaseAuth.instance.currentUser!.uid);
  
  final _formKey = GlobalKey<FormState>();
  bool loading = false;
  
  // Text field state
  String _name = '';
  String _email = '';
  String _customMessage = '';
  String _country = '';
  Country? _selectedCountry;

  @override
  Widget build(BuildContext context) {
    final countryList = [Country.worldWide];

    return StreamBuilder<DocumentSnapshot>(
      stream: _database.userData,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          _name = userData['name'] ?? '';
          _email = userData['email'] ?? '';
          _customMessage = userData['customMessage'] ?? '';
          _country = userData['country'] ?? '';
          
          // Try to find the country from the country list
          if (_country.isNotEmpty) {
            _selectedCountry = countryList.firstWhere(
              (country) => country.countryCode == _country,
              orElse: () => countryList.first,
            );
          } else {
            _selectedCountry = countryList.first;
          }
        }
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('My Profile'),
            backgroundColor: Colors.red,
            actions: [
              TextButton.icon(
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text('Logout', style: TextStyle(color: Colors.white)),
                onPressed: () async {
                  await _auth.signOut();
                },
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  const Text(
                    'Personal Information',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    initialValue: _name,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) => val!.isEmpty ? 'Enter your name' : null,
                    onChanged: (val) {
                      setState(() => _name = val);
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    initialValue: _email,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    enabled: false, // Email should not be editable
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Emergency Settings',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  // Country picker
                  ListTile(
                    title: const Text('Country'),
                    subtitle: Text(_selectedCountry?.name ?? 'Select Country'),
                    trailing: const Icon(Icons.arrow_drop_down),
                    onTap: () {
                      showCountryPicker(
                        context: context,
                        showPhoneCode: false,
                        onSelect: (Country country) {
                          setState(() {
                            _selectedCountry = country;
                            _country = country.countryCode;
                          });
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    initialValue: _customMessage,
                    decoration: const InputDecoration(
                      labelText: 'Custom Emergency Message',
                      hintText: 'Enter a custom message to send to your emergency contacts',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    onChanged: (val) {
                      setState(() => _customMessage = val);
                    },
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text(
                      'Save Profile',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        setState(() => loading = true);
                        
                        await _database.updateUserData(
                          _name,
                          _email,
                          _customMessage,
                          _country,
                        );
                        
                        setState(() => loading = false);
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Profile updated successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}