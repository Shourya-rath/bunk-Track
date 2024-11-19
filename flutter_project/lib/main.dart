import 'dart:async'; // To use Timer
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart'; // Import the geocoding package

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Location Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LocationScreen(),
    );
  }
}

class LocationScreen extends StatefulWidget {
  const LocationScreen({Key? key}) : super(key: key);

  @override
  LocationScreenState createState() => LocationScreenState();
}

class LocationScreenState extends State<LocationScreen> {
  String _locationMessage = "Getting your location...";
  String _address = "Waiting for address..."; // New variable to hold address
  bool _isSendingData = false; // To toggle sending data
  Timer? _timer; // Timer to periodically send data
  int _interval = 10; // Default interval in seconds

  // Function to get the current location
  Future<void> _getLocation() async {
    // Check for location permissions
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _locationMessage = "Location permissions are permanently denied. Please enable them in your settings.";
      });
      return;
    } else if (permission == LocationPermission.denied) {
      setState(() {
        _locationMessage = "Location permissions are denied. Please enable them.";
      });
      return;
    }

    // Get the current location
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      _locationMessage = "Latitude: ${position.latitude}, Longitude: ${position.longitude}";
    });

    // Get the address from the latitude and longitude (reverse geocoding)
    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    // Get the first placemark (address)
    Placemark place = placemarks[0];
    setState(() {
      _address = "${place.street}, ${place.locality}, ${place.country}";
    });

    // Here you would send the location to Supabase or your backend.
    _sendLocationToDatabase(position.latitude, position.longitude);
  }

  // Function to send location to the database (supabase or backend)
  Future<void> _sendLocationToDatabase(double latitude, double longitude) async {
    // Here, you would write the code to send the data to your Supabase or backend
    print("Sending to database: RollNumber: A123, Coordinates: $latitude, $longitude");
    // Example:
    // supabase.from('student_database').insert({
    //   'student_roll_number': 'A123',
    //   'coordinates': '$latitude $longitude',
    //   'is_on_campus': true,
    // }).execute();
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

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Location App with Address'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              'Current Location:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              _locationMessage,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Text(
              'Address:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              _address,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _getLocation, // Get location on button press
              child: Text('Get Current Location'),
            ),
            SizedBox(height: 20),
            // Dropdown for setting the interval
            DropdownButton<int>(
              value: _interval,
              items: [10, 30, 180, 900, 1800]
                  .map((value) => DropdownMenuItem<int>(
                        value: value,
                        child: Text('Every ${value ~/ 60} minutes'),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _interval = value!;
                });
                if (_isSendingData) {
                  _startTimer(); // Restart the timer with the new interval
                }
              },
            ),
            SizedBox(height: 20),
            // Switch to toggle the sending of data
            SwitchListTile(
              title: Text('Send Location Data'),
              value: _isSendingData,
              onChanged: _toggleSendingData,
            ),
          ],
        ),
      ),
    );
  }
}
