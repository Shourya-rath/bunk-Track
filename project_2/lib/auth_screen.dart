import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Import Supabase package
import 'location_screen.dart'; // Import the location screen

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _rollNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkIfLoggedIn(); // Check if the user is already logged in when the screen is opened
  }

  // Check if the user is already logged in
  Future<void> _checkIfLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (isLoggedIn) {
      // If the user is logged in, navigate to LocationScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LocationScreen()),
      );
    }
  }

  // Sign up user and save details
  Future<void> _signUp(BuildContext context) async {
    final String rollNumber = _rollNumberController.text;
    final String email = _emailController.text;
    final String password = _passwordController.text;

    if (rollNumber.isEmpty || email.isEmpty || password.isEmpty) {
      _showError('Please fill all fields.');
      return;
    }

    try {
      // Sign up the user with Supabase
      final response = await Supabase.instance.client.auth.signUp(
        email,
        password,
        userMetadata: {
          'display_name': rollNumber, // Store the roll number as display name in metadata
        },
      );

      if (response.error != null) {
        _showError('Error signing up: ${response.error!.message}');
        return;
      }

      final userId = response.data!.user!.id;

      // Insert roll number and other initial details into the student database
      final insertResponse = await Supabase.instance.client.from('student_database').insert([
        {
          'student_roll_number': rollNumber,
          'coordinates': '',
          'is_on_campus': false,  // Default values
          'user_id': userId,
        },
      ]).execute();

      if (insertResponse.error != null) {
        _showError('Error inserting roll number: ${insertResponse.error!.message}');
        return;
      }

      // Save the login state in SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('rollNumber', rollNumber); // Save roll number here
      await prefs.setString('email', email); // Save email here

      // Navigate to the location screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LocationScreen()),
      );
    } catch (e) {
      _showError('Sign-up error: $e');
    }
  }

  // Log in existing user
  Future<void> _login(BuildContext context) async {
    final String email = _emailController.text;
    final String password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showError('Please fill all fields.');
      return;
    }

    try {
      // Log in the user with Supabase
      final response = await Supabase.instance.client.auth.signIn(
        email: email,
        password: password,
      );
      if (response.error != null) {
        _showError('Error logging in: ${response.error!.message}');
        return;
      }

      // Fetch the display name (roll number) from Supabase Auth
      final user = Supabase.instance.client.auth.currentUser ;
      final String rollNumber = user?.userMetadata['display_name'] ?? '';

      // Save the login state in SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('email', email); // Save email after login
      await prefs.setString('rollNumber', rollNumber); // Save roll number (display name)

      // Navigate to the location screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LocationScreen()),
      );
    } catch (e) {
      _showError('Login error: $e');
    }
  }

  // Show error messages
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up / Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('Roll Number:'),
            TextField(
              controller: _rollNumberController,
              decoration: const InputDecoration(hintText: 'Enter Roll Number'),
            ),
            const SizedBox(height: 16),
            const Text('Email:'),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(hintText: 'Enter Email'),
            ),
            const SizedBox(height: 16),
            const Text('Password:'),
            TextField(
              controller: _passwordController,
              obscureText: true, // Hide password input
              decoration: const InputDecoration(hintText: 'Enter Password'),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => _signUp(context),
              child: const Text('Sign Up'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _login(context),
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}