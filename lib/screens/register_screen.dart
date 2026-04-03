import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:stay_safe_app/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  bool loading = false;
  bool _obscurePassword = true;
  
  // Text field state
  String email = '';
  String password = '';
  String error = '';

  // Email validation regex
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.red,
        elevation: 0.0,
        title: const Text('Register for Stay Safe'),
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 50.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                const SizedBox(height: 20.0),
                TextFormField(
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter your email',
                    fillColor: Colors.white,
                    filled: true,
                    prefixIcon: Icon(Icons.email_outlined),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey, width: 1.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red, width: 2.0),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Enter an email';
                    if (!_isValidEmail(val.trim())) return 'Enter a valid email address';
                    return null;
                  },
                  onChanged: (val) {
                    setState(() => email = val);
                  },
                ),
                const SizedBox(height: 20.0),
                TextFormField(
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    fillColor: Colors.white,
                    filled: true,
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey, width: 1.0),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red, width: 2.0),
                    ),
                  ),
                  validator: (val) => val!.length < 6 ? 'Enter a password 6+ chars long' : null,
                  onChanged: (val) {
                    setState(() => password = val);
                  },
                ),
                const SizedBox(height: 20.0),
                loading 
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text(
                        'Register',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          setState(() {
                            loading = true;
                            error = '';
                          });
                          dynamic result = await _auth.registerWithEmailAndPassword(email.trim(), password);
                          if (result is String) {
                            setState(() {
                              error = result;
                              loading = false;
                            });
                          } else if (result == null) {
                            setState(() {
                              error = 'Registration failed. Please try again.';
                              loading = false;
                            });
                          }
                        }
                      },
                    ),
                const SizedBox(height: 12.0),
                Text(
                  error,
                  style: const TextStyle(color: Colors.red, fontSize: 14.0),
                  textAlign: TextAlign.center,
                ),
                TextButton(
                  child: const Text('Already have an account? Sign in here'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}