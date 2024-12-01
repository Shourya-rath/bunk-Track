import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart'; // Import the geocoding package
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Import Supabase package
import 'auth_screen.dart'; // Import the login screen for logout functionality
import 'profile.dart'; // Import the profile screen

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
  int _interval = 10; // Default interval of 10 seconds
  int _countdownSeconds = 0; // Countdown seconds for the user to see

  // Dropdown values for timer interval
  final List<int> _intervalOptions = [10, 30, 60]; // 10 sec, 30 sec, 1 min

  // Define the campus polygon (coordinates you provided)
  final List<List<double>> _campusPolygon = [
    [73.8518061, 24.6209523],
    [73.8520743, 24.6182701],
    [73.8569237, 24.6186603],
    [73.8565375, 24.6215278],
    [73.8518061, 24.6209523], // Closing the polygon
  ];

  @override
  void initState() {
    super.initState();
    _loadTimerSettings(); // Load saved timer settings on init
  }

  // Function to check if the user is inside the campus polygon
  bool _isInsideCampus(double lat, double lon) {
    int intersections = 0;
    for (int i = 0; i < _campusPolygon.length - 1; i++) {
      double x1 = _campusPolygon[i][0], y1 = _campusPolygon[i][1];
      double x2 = _campusPolygon[i + 1][0], y2 = _campusPolygon[i + 1][1];

      // Check if the point (lat, lon) is inside the polygon
      if (((lat > y1) != (lat > y2)) &&
          (lon < (x2 - x1) * (lat - y1) / (y2 - y1) + x1)) {
        intersections++;
      }
    }

    return intersections % 2 != 0; // Odd number of intersections means inside the polygon
  }

  // Function to get the current location
  Future<void> _getLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _locationMessage =
        "Location permissions are permanently denied. Please enable them in your settings.";
      });
      return;
    } else if (permission == LocationPermission.denied) {
      setState(() {
        _locationMessage =
        "Location permissions are denied. Please enable them.";
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

    // Send location data to backend
    _sendLocationToDatabase(position.latitude, position.longitude);
  }

  // Function to send location to the database (Supabase)
  Future<void> _sendLocationToDatabase(double latitude, double longitude) async {
    // Get the roll number and email from SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String rollNumber = prefs.getString('rollNumber') ?? '';
    String email = prefs.getString('email') ?? '';

    final isOnCampus = _isInsideCampus(latitude, longitude);

    // Insert the location data into Supabase (including the email)
    final response = await Supabase.instance.client.from('student_database').upsert({
      'student_roll_number': rollNumber,
      'coordinates': '$latitude, $longitude',
      'is_on_campus': isOnCampus,
      'email': email, // Include email to associate with the record
    }).execute();

    if (response.error != null) {
      print("Error sending location data: ${response.error?.message}");
    } else {
      print("Successfully sent location data for Roll Number: $rollNumber");
    }
  }

  // Start the timer based on the selected interval
  void _startTimer() {
    if (_isSendingData) {
      _timer?.cancel();
      _countdownSeconds = _interval; // Reset countdown seconds to the selected interval
      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        setState(() {
          if (_countdownSeconds > 0) {
            _countdownSeconds--; // Decrease countdown every second
          } else {
            _getLocation(); // Fetch location when countdown reaches zero
            _countdownSeconds = _interval; // Reset countdown after location fetch
          }
        });
      });
    }
  }

  // Stop the timer
  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _countdownSeconds = 0; // Reset countdown when timer is stopped
    });
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
    _saveTimerSettings(); // Save the updated sending data state
  }

  // Handle interval change from dropdown
  void _handleIntervalChange(int? newInterval) {
    if (newInterval != null) {
      setState(() {
        _interval = newInterval;
        _countdownSeconds = _interval; // Reset the countdown when interval changes
        _saveTimerSettings(); // Save the updated timer settings
      });
    }
  }

  // Save interval, countdown, and sending data state to SharedPreferences
  Future<void> _saveTimerSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('interval', _interval);
    prefs.setInt('countdownSeconds', _countdownSeconds);
    prefs.setBool('isSendingData', _isSendingData); // Save sending data state
  }

  // Load interval, countdown, and sending data state from SharedPreferences
  Future<void> _loadTimerSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _interval = prefs.getInt('interval') ?? 10; // Default to 10 seconds
      _countdownSeconds = prefs.getInt('countdownSeconds') ?? _interval; // Default to interval
      _isSendingData = prefs.getBool('isSendingData') ?? false; // Load sending data state
    });

    // Start the timer if sending data was previously enabled
    if (_isSendingData) {
      _startTimer();
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
            const SizedBox(height: 20),
            // Timer Interval Dropdown
            DropdownButton<int>(
              value: _interval,
              onChanged: _handleIntervalChange,
              items: _intervalOptions.map((int interval) {
                return DropdownMenuItem<int>(
                  value: interval,
                  child: Text('$interval ${interval == 60 ? 'second' : 'seconds'}'),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            // Show countdown timer
            Text(
              'Time until next send: $_countdownSeconds seconds',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}