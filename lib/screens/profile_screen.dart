import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_picker/country_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  
  bool loading = false;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  
  // State variables
  String _name = '';
  String _email = '';
  String _customMessage = '';
  String _countryCode = '';
  String? _profileImageUrl;
  bool _aiProcessing = true;
  double _soundSensitivity = 50.0;
  int _sosDelay = 10;
  
  Country? _selectedCountry;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      _saveProfile();
    }
  }

  Future<String?> _uploadImage(File image) async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      Reference ref = FirebaseStorage.instance.ref().child('profile_pictures').child('$uid.jpg');
      UploadTask uploadTask = ref.putFile(image);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

  void _saveProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => loading = true);
      
      String? imageUrl = _profileImageUrl;
      if (_imageFile != null) {
        imageUrl = await _uploadImage(_imageFile!);
      }
      
      await _database.updateUserData(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _customMessage,
        _countryCode,
        profileImageUrl: imageUrl,
        aiProcessing: _aiProcessing,
        soundSensitivity: _soundSensitivity,
        sosDelay: _sosDelay,
      );
      
      if (mounted) {
        setState(() {
          loading = false;
          _imageFile = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Settings updated successfully")),
        );
      }
    }
  }

  void _showEditNameDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
                validator: (val) => val == null || val.isEmpty ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                validator: (val) => val == null || val.isEmpty ? 'Please enter your email' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              _saveProfile();
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _database.userData,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.exists) {
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          _name = userData['name'] ?? '';
          _email = userData['email'] ?? '';
          
          // Only update controllers if the user isn't currently typing
          if (!loading) {
            _nameController.text = _name;
            _emailController.text = _email;
          }
          
          _customMessage = userData['customMessage'] ?? '';
          _countryCode = userData['country'] ?? '';
          _profileImageUrl = userData['profileImageUrl'];
          _aiProcessing = userData['aiProcessing'] ?? true;
          _soundSensitivity = (userData['soundSensitivity'] ?? 50.0).toDouble();
          _sosDelay = userData['sosDelay'] ?? 10;
          
          if (_countryCode.isNotEmpty && _selectedCountry == null) {
            _selectedCountry = Country.tryParse(_countryCode);
          }
        }
        
        return Scaffold(
          backgroundColor: const Color(0xFFF5F7F8),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF02579C)),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Profile & Settings',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // User Profile Section
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                  ),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 56,
                                backgroundColor: const Color(0xFF02579C).withOpacity(0.1),
                                backgroundImage: _imageFile != null 
                                  ? FileImage(_imageFile!) 
                                  : (_profileImageUrl != null ? NetworkImage(_profileImageUrl!) : null) as ImageProvider?,
                                child: (_imageFile == null && _profileImageUrl == null)
                                  ? const Icon(Icons.person, size: 50, color: Color(0xFF02579C))
                                  : null,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF02579C),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _name.isEmpty ? 'New User' : _name,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 18, color: Color(0xFF02579C)),
                            onPressed: _showEditNameDialog,
                          ),
                        ],
                      ),
                      Text(
                        _email,
                        style: const TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                ),

                // Safety Settings
                _buildSectionHeader('Safety Settings'),
                
                // SOS Delay Selector
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.timer_outlined, color: Color(0xFF02579C), size: 20),
                          SizedBox(width: 12),
                          Text('SOS Countdown Delay', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [5, 6, 7, 8, 9, 10].map((s) => ChoiceChip(
                          label: Text('${s}s'),
                          selected: _sosDelay == s,
                          onSelected: (val) {
                            if (val) {
                              setState(() => _sosDelay = s);
                              _saveProfile();
                            }
                          },
                          selectedColor: const Color(0xFF02579C),
                          labelStyle: TextStyle(color: _sosDelay == s ? Colors.white : Colors.black),
                        )).toList(),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Text("Time to cancel before SOS alerts are sent.", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ),
                    ],
                  ),
                ),

                // Sound Sensitivity Slider
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.graphic_eq, color: Color(0xFF02579C), size: 20),
                              SizedBox(width: 12),
                              Text('Scream Sensitivity', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                            ],
                          ),
                          Text(
                            _soundSensitivity < 33 ? 'Low' : (_soundSensitivity < 66 ? 'Medium' : 'High'),
                            style: const TextStyle(color: Color(0xFF02579C), fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Slider(
                        value: _soundSensitivity,
                        min: 0,
                        max: 100,
                        activeColor: const Color(0xFF02579C),
                        onChanged: (val) => setState(() => _soundSensitivity = val),
                        onChangeEnd: (val) => _saveProfile(),
                      ),
                    ],
                  ),
                ),

                // Logout Button
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await _auth.signOut();
                      if (context.mounted) Navigator.of(context).pushReplacementNamed('/');
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red.withOpacity(0.2)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.logout),
                    label: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            selectedItemColor: const Color(0xFF02579C),
            unselectedItemColor: Colors.grey,
            currentIndex: 3,
            onTap: (index) {
              if (index == 0) Navigator.pushReplacementNamed(context, '/home');
              if (index == 1) Navigator.pushReplacementNamed(context, '/map');
              if (index == 2) Navigator.pushReplacementNamed(context, '/contacts');
            },
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'Safety Map'),
              BottomNavigationBarItem(icon: Icon(Icons.group_outlined), label: 'Circle'),
              BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
      ),
    );
  }
}
