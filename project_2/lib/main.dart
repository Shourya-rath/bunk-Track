import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_screen.dart'; // Import the auth screen (login screen)
import 'location_screen.dart'; // Import the location screen
import 'package:supabase_flutter/supabase_flutter.dart'; // Import the Supabase package
import 'profile.dart'; // Import the ProfileScreen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://owrfjcjkpkugfzfpnzyp.supabase.co',  // Replace with your Supabase URL
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im93cmZqY2prcGt1Z2Z6ZnBuenlwIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTcyNjM5ODkxNywiZXhwIjoyMDQxOTc0OTE3fQ.0WzDl3zPy1lGy8gy_StmRvGH5Rqe1A7PtPX7qsOCZcs',            // Replace with your Supabase anon key
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Location Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FutureBuilder<bool>(
        future: _isLoggedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }
          if (snapshot.data == true) {
            return const LocationScreen();
          } else {
            return const LoginScreen();
          }
        },
      ),
    );
  }

  // Check if the user is logged in
  Future<bool> _isLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? email = prefs.getString('email');
    final String? rollNumber = prefs.getString('rollNumber');

    if (email == null || rollNumber == null) {
      return false;
    }

    // Check if there is an active session
    final session = Supabase.instance.client.auth.currentSession;

    if (session == null) {
      return false;  // No active session, so the user is not logged in.
    }

    return true;  // User is logged in.
  }
}

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  LocationScreenState createState() => LocationScreenState();
}

class LocationScreenState extends State<LocationScreen> {
  String _locationMessage = "Getting your location...";
  String _address = "Waiting for address...";
  bool _isSendingData = false;
  Timer? _timer;
  final int _interval = 10;

  // Function to check if the user is inside the campus polygon
  bool _isInsideCampus(double lat, double lon) {
    // You can add your polygon logic here if necessary
    return true; // Placeholder for checking if inside the campus
  }

  // Function to get the current location
  Future<void> _getLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _locationMessage = "Location permissions are permanently denied.";
      });
      return;
    } else if (permission == LocationPermission.denied) {
      setState(() {
        _locationMessage = "Location permissions are denied.";
      });
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      _locationMessage =
      "Latitude: ${position.latitude}, Longitude: ${position.longitude}";
    });

    // Get the address from the latitude and longitude
    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    Placemark place = placemarks[0];
    setState(() {
      _address = "${place.street}, ${place.locality}, ${place.country}";
    });
  }

  // Start the timer based on the selected interval
  void _startTimer() {
    if (_isSendingData) {
      _timer?.cancel();
      _timer = Timer.periodic(Duration(seconds: _interval), (timer) {
        _getLocation(); // Call to get location at the set interval
      });
    }
  }

  // Stop the timer
  void _stopTimer() {
    _timer?.cancel();
  }

  // Toggle the sending of data
  void _toggleSendingData(bool value) {
    setState(() {
      _isSendingData = value;
    });
    if (_isSendingData) {
      _startTimer(); // Start sending data at the selected interval
    } else {
      _stopTimer(); // Stop sending data
    }
  }

  // Logout function
  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear the login data

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location App with Address'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(child: Text('Student Info')),
            ListTile(
              title: const Text('Logout'),
              onTap: _logout,
            ),
            ListTile(
              title: const Text('Profile'),
              onTap: () {
                // Navigate to Profile Screen
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Current Location:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              _locationMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            const Text(
              'Address:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              _address,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _getLocation,
              child: const Text('Get Current Location'),
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text('Send Location Data'),
              value: _isSendingData,
              onChanged: _toggleSendingData,
            ),
          ],
        ),
      ),
    );
  }
}
