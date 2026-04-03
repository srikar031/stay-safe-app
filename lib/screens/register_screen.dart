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
  String name = '';
  String email = '';
  String password = '';
  String error = '';

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
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 30.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                const SizedBox(height: 20.0),
                // Name Field
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'Enter your name',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) => val == null || val.isEmpty ? 'Enter your name' : null,
                  onChanged: (val) => setState(() => name = val),
                ),
                const SizedBox(height: 20.0),
                // Email Field
                TextFormField(
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter your email',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Enter an email';
                    if (!_isValidEmail(val.trim())) return 'Enter a valid email address';
                    return null;
                  },
                  onChanged: (val) => setState(() => email = val),
                ),
                const SizedBox(height: 20.0),
                // Password Field
                TextFormField(
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (val) => val!.length < 6 ? 'Enter a password 6+ chars long' : null,
                  onChanged: (val) => setState(() => password = val),
                ),
                const SizedBox(height: 30.0),
                loading 
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('Register', style: TextStyle(color: Colors.white, fontSize: 16)),
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          setState(() {
                            loading = true;
                            error = '';
                          });
                          // Pass the name to the registration service
                          dynamic result = await _auth.registerWithEmailAndPassword(
                            email.trim(), 
                            password,
                            name: name.trim()
                          );
                          
                          if (result is String) {
                            setState(() {
                              error = result;
                              loading = false;
                            });
                          }
                        }
                      },
                    ),
                const SizedBox(height: 12.0),
                Text(error, style: const TextStyle(color: Colors.red, fontSize: 14.0)),
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
