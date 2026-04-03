import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:stay_safe_app/services/database_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _database = DatabaseService(uid: FirebaseAuth.instance.currentUser!.uid);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _database.userData,
      builder: (context, snapshot) {
        String userName = "User";
        String? profileImageUrl;
        List<Map<String, String>> contacts = [];

        if (snapshot.hasData && snapshot.data!.exists) {
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          userName = userData['name'] ?? "User";
          profileImageUrl = userData['profileImageUrl'];
          final List<dynamic> contactsData = userData['emergencyContacts'] ?? [];
          contacts = contactsData.map((contact) {
            final contactMap = contact as Map;
            return {
              'name': contactMap['name'] as String? ?? '',
              'phone': contactMap['phone'] as String? ?? '',
            };
          }).toList();
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7F8),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF02579C),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF02579C).withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.shield, color: Colors.white, size: 20),
              ),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Stay Safe',
                  style: TextStyle(
                    color: Color(0xFF02579C),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  'Hello, $userName',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_none, color: Colors.grey),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("No new notifications")),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/profile'),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundImage: profileImageUrl != null
                        ? NetworkImage(profileImageUrl)
                        : null,
                    backgroundColor: Colors.grey[200],
                    child: profileImageUrl == null
                        ? const Icon(Icons.person, color: Colors.grey, size: 20)
                        : null,
                  ),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF02579C).withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF02579C).withValues(alpha: 0.1)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_person, size: 14, color: Color(0xFF02579C)),
                      SizedBox(width: 6),
                      Text(
                        '100% ON-DEVICE AI | PRIVACY FIRST',
                        style: TextStyle(
                          color: Color(0xFF02579C),
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onLongPress: () => Navigator.pushNamed(context, '/emergency'),
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withValues(alpha: 0.4),
                                blurRadius: 30,
                                spreadRadius: 5,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('SOS', style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
                              Text('HOLD FOR SOS', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, color: Colors.green, size: 14),
                            SizedBox(width: 8),
                            Text('AI Sound Detection: Active', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('MONITORING FOR DISTRESS SIGNALS', style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 1)),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                Row(
                  children: [
                    Expanded(child: _buildFeatureCard(
                      Icons.directions_walk,
                      "Walk Home Mode",
                      "Monitor your route and share with friends.",
                      () => Navigator.pushNamed(context, '/map'),
                    )),
                    const SizedBox(width: 16),
                    Expanded(child: _buildFeatureCard(
                      Icons.shield_outlined,
                      "Scream Detector",
                      "Get help if you can\'t trigger SOS.",
                      () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Scream detection is active in the background.")),
                        );
                      },
                    )),
                  ],
                ),
                const SizedBox(height: 32),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('QUICK CONTACTS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
                        TextButton(onPressed: () => Navigator.pushNamed(context, '/contacts'), child: const Text('Edit', style: TextStyle(fontSize: 12))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: contacts.length + 2,
                        itemBuilder: (context, index) {
                          if (index < contacts.length) {
                            return _buildContactItem(contacts[index]['name']!, Icons.person);
                          } else if (index == contacts.length) {
                            return _buildContactItem("Police", Icons.local_police, isEmergency: true);
                          } else {
                            return _buildAddContactItem();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            selectedItemColor: const Color(0xFF02579C),
            unselectedItemColor: Colors.grey,
            currentIndex: 0,
            onTap: (index) {
              if (index == 1) Navigator.pushReplacementNamed(context, '/map');
              if (index == 2) Navigator.pushReplacementNamed(context, '/contacts');
              if (index == 3) Navigator.pushReplacementNamed(context, '/profile');
            },
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'Safety Map'),
              BottomNavigationBarItem(icon: Icon(Icons.group_outlined), label: 'Circle'),
              BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Settings'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeatureCard(IconData icon, String title, String desc, VoidCallback onTap) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFF02579C).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: const Color(0xFF02579C), size: 20),
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF02579C),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: const Text('Start', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(String name, IconData icon, {bool isEmergency = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: Column(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(shape: BoxShape.circle, color: isEmergency ? Colors.red[50] : Colors.grey[100], border: Border.all(color: Colors.white, width: 2)),
            child: Icon(icon, color: isEmergency ? Colors.red : Colors.grey, size: 28),
          ),
          const SizedBox(height: 8),
          Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildAddContactItem() {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/contacts'),
            child: Container(
              width: 56, height: 56,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey[50], border: Border.all(color: Colors.grey[300]!, width: 2, style: BorderStyle.solid)),
              child: Icon(Icons.add, color: Colors.grey[400]),
            ),
          ),
          const SizedBox(height: 8),
          const Text('Add', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}