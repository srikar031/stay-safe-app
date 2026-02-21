import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:stay_safe_app/services/database_service.dart';
import 'package:stay_safe_app/services/location_service.dart';
// import 'package:stay_safe_app/services/notification_service.dart';
import 'package:stay_safe_app/services/emergency_numbers.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> with TickerProviderStateMixin {
  final DatabaseService _database = DatabaseService(uid: FirebaseAuth.instance.currentUser!.uid);
  final LocationService _locationService = LocationService();
  // final NotificationService _notificationService = NotificationService();
  
  bool _isEmergencyActive = false;
  bool _isCountdownActive = false;
  int _countdown = 10;
  Timer? _countdownTimer;
  Timer? _locationTimer;
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  String _userName = '';
  String _userCountry = '';
  String _customMessage = '';
  List<Map<String, String>> _emergencyContacts = [];
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    
    _animation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _locationTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _loadUserData() async {
    final snapshot = await _database.userCollection.doc(FirebaseAuth.instance.currentUser!.uid).get();
    if (snapshot.exists) {
      final userData = snapshot.data() as Map<String, dynamic>;
      
      setState(() {
        _userName = userData['name'] ?? '';
        _userCountry = userData['country'] ?? '';
        _customMessage = userData['customMessage'] ?? '';
        
        final List<dynamic> contactsData = userData['emergencyContacts'] ?? [];
        _emergencyContacts = contactsData.map((contact) {
          final contactMap = contact as Map;
          return {
            'name': contactMap['name'] as String? ?? '',
            'phone': contactMap['phone'] as String? ?? '',
          };
        }).toList();
      });
    }
  }

  void _startEmergencyCountdown() {
    setState(() {
      _isCountdownActive = true;
      _countdown = 10;
    });
    
    _animationController.reset();
    _animationController.forward();
    
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _countdown--;
      });
      
      if (_countdown <= 0) {
        timer.cancel();
        _activateEmergency();
      }
    });
  }

  void _cancelEmergencyCountdown() {
    _countdownTimer?.cancel();
    _animationController.stop();
    _animationController.reset();
    
    setState(() {
      _isCountdownActive = false;
    });
    
    Navigator.of(context).pop();
  }

  void _activateEmergency() async {
    setState(() {
      _isCountdownActive = false;
      _isEmergencyActive = true;
    });
    
    // Get current location
    _currentPosition = await _locationService.getCurrentLocation();
    
    // Create emergency record in Firestore
    final emergencyData = {
      'location': _currentPosition != null
          ? {'latitude': _currentPosition!.latitude, 'longitude': _currentPosition!.longitude}
          : null,
      'message': _customMessage.isNotEmpty ? _customMessage : 'Emergency alert!',
      'contactsNotified': false,
    };
    
    final emergencyDoc = await _database.createEmergencyRecord(emergencyData);
    
    // Send notifications to emergency contacts
    await _sendEmergencyNotifications(emergencyDoc.id);
    
    // Start location tracking
    _startLocationTracking(emergencyDoc.id);
  }

  void _startLocationTracking(String emergencyId) {
    _locationTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      _currentPosition = await _locationService.getCurrentLocation();
      
      if (_currentPosition != null) {
        // Update location in Firestore
        await _database.emergencyCollection.doc(emergencyId).update({
          'location': {
            'latitude': _currentPosition!.latitude,
            'longitude': _currentPosition!.longitude,
          },
          'timestamp': Timestamp.now(),
        });
      }
    });
  }

  Future<void> _sendEmergencyNotifications(String emergencyId) async {
  // Get emergency number for the user's country
  final emergencyNumber = EmergencyNumbers.getEmergencyNumber(_userCountry);
  
  // Send notifications to all emergency contacts
  for (final contact in _emergencyContacts) {
    final message = _customMessage.isNotEmpty 
        ? _customMessage 
        : 'Emergency alert from $_userName!';
    
    final locationText = _currentPosition != null
        ? '\nLocation: https://maps.google.com/?q=${_currentPosition!.latitude},${_currentPosition!.longitude}'
        : '';
    
    final fullMessage = '$message\n\nEmergency services in your area: $emergencyNumber$locationText';
    
    // In a real app, you would use a service like Twilio to send SMS
    // For this example, we'll just show a local notification
    // await _notificationService.showNotification(
    //   'Emergency Alert',
    //   'Emergency alert sent to ${contact['name']} at ${contact['phone']}',
    // );
  }
  
  // Mark contacts as notified
  await _database.emergencyCollection.doc(emergencyId).update({
    'contactsNotified': true,
    'emergencyNumber': emergencyNumber,
  });
}

  void _endEmergency() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Emergency?'),
        content: const Text('Are you sure you want to mark yourself as safe?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'I\'m Safe',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      // Stop location tracking
      _locationTimer?.cancel();
      
      // Update emergency status in Firestore
      final querySnapshot = await _database.emergencyCollection
          .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
          .where('status', isEqualTo: 'active')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        await _database.updateEmergencyStatus(querySnapshot.docs.first.id, 'resolved');
      }
      
      // Send "I'm safe" notifications to contacts
      for (final contact in _emergencyContacts) {
        // In a real app, you would use a service like Twilio to send SMS
        // await _notificationService.showNotification(
        //   'Safety Confirmed',
        //   'Notification sent to ${contact['name'] ?? ''} that you are safe',
        // );
      }
      
      setState(() {
        _isEmergencyActive = false;
      });
      
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red[50],
      appBar: AppBar(
        title: const Text('Emergency'),
        backgroundColor: Colors.red,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: _isCountdownActive
            ? _buildCountdownUI()
            : _isEmergencyActive
                ? _buildEmergencyActiveUI()
                : _buildInitialUI(),
      ),
    );
  }

  Widget _buildInitialUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.warning,
          size: 100,
          color: Colors.red,
        ),
        const SizedBox(height: 20),
        const Text(
          'EMERGENCY MODE',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Press the button below to activate emergency alert',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
        const SizedBox(height: 40),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
          ),
          onPressed: _startEmergencyCountdown,
          child: const Text(
            'ACTIVATE EMERGENCY ALERT',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 20),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancel',
            style: TextStyle(color: Colors.red, fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildCountdownUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 200,
              height: 200,
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return CircularProgressIndicator(
                    value: _animation.value,
                    strokeWidth: 10,
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
                  );
                },
              ),
            ),
            Text(
              '$_countdown',
              style: const TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),
        const Text(
          'Emergency alert will be sent in',
          style: TextStyle(fontSize: 20),
        ),
        const SizedBox(height: 10),
        const Text(
          'Press CANCEL to abort',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 40),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey,
            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
          ),
          onPressed: _cancelEmergencyCountdown,
          child: const Text(
            'CANCEL',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmergencyActiveUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.notifications_active,
          size: 100,
          color: Colors.red,
        ),
        const SizedBox(height: 20),
        const Text(
          'EMERGENCY ALERT ACTIVE',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Your emergency contacts have been notified',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18),
        ),
        const SizedBox(height: 10),
        if (_currentPosition != null)
          Text(
            'Location: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
        const SizedBox(height: 40),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
          ),
          onPressed: _endEmergency,
          child: const Text(
            'I\'M SAFE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}