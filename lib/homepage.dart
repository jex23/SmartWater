import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';


class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.reference().child('Water/Reading');
  final DatabaseReference _databse2 = FirebaseDatabase.instance.reference().child('Water/Flowrate');
  final DatabaseReference _databse3 = FirebaseDatabase.instance.reference().child('Water/WaterReading');
  final String apiUrl = 'https://script.google.com/macros/s/AKfycbzv44RSA-eJGEspgF9g78wSWcJt4Au9b2tsEmg0qf1_Ma67EkKPt6xmN1HzPg6A1lSZbw/exec';
  List<List<String>> _data = [];

  Future<void> _fetchData() async {
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      setState(() {
        _data = List<List<String>>.from(json.decode(response.body).map((row) => List<String>.from(row)));
        _saveDataToLocal();
      });
    } else {
      throw Exception('Failed to load data');
    }
  }

  String formatDateString(String dateString) {
    try {
      // Split the date string into parts
      List<String> parts = dateString.split(' ');

      // Ensure that there are enough parts to extract the date
      if (parts.length >= 4) {
        // Extract the relevant parts for formatting
        String day = parts[2];
        String month = parts[1];
        String year = parts[3];

        // Combine the parts in the desired format
        String formattedDate = '$month $day $year';

        return formattedDate;
      } else {
        // Return the original string if the format is not as expected
        return dateString;
      }
    } catch (e) {
      // Handle the exception, you can log it or return a default value
      print('Error parsing date: $e');
      return dateString; // Return the original string as a fallback
    }
  }

  Future<void> _refreshData() async {
    await _fetchData();
  }

  double flowRate = 0.00; // default value
  double waterConsumption = 0.0;
  double cubicCompsumption = 0.0;

  @override
  void initState() {
    super.initState();
    _loadDataFromLocal();
    _fetchData();
    Timer.periodic(Duration(seconds: 30), (Timer t) => _fetchData());
    // Set up a listener for changes in the database
    _database.onValue.listen((event) {
      setState(() {
        waterConsumption = (event.snapshot.value as double?) ?? 0.0;
        waterConsumption = waterConsumption / 1000;
      });
    });
    _databse2.onValue.listen((event) {
      setState(() {
        flowRate = (event.snapshot.value as double?) ?? 0.0;
      });
    });
    _databse3.onValue.listen((event) {
      setState(() {
        cubicCompsumption = (event.snapshot.value as double?) ?? 0.0;
      });
    });
  }

  Future<void> _loadDataFromLocal() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? dataString = prefs.getString('data');
    if (dataString != null) {
      final List<dynamic> jsonData = json.decode(dataString);
      setState(() {
        _data = jsonData.map((row) => List<String>.from(row)).toList();
      });
    }
  }

  Future<void> _saveDataToLocal() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('data', json.encode(_data));
  }

  @override
  Widget build(BuildContext context) {
    User? user = _auth.currentUser;
    String emailPrefix = user?.email?.split('@').first.replaceAll(RegExp(r'[0-9]'), '') ?? '';
    String capitalizedPrefix = emailPrefix.isNotEmpty ? emailPrefix[0].toUpperCase() + emailPrefix.substring(1) : '';


    return Scaffold(
      appBar: AppBar(
        title: Text('Water Meter IOT'),
      ),
      body: Column(
        children: [
          Card(
            elevation: 5,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Welcome, $capitalizedPrefix',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () async {
                          await _auth.signOut();
                          Navigator.pushReplacementNamed(context, '/signin');
                        },
                        child: Text('Sign Out'),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        "Water Consumption",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    ],
                  ),
                  Text(
                    "Cubic Meter: $cubicCompsumption m³",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Padding(padding: EdgeInsets.only(top:10,),
                    child: Text("Liter: $waterConsumption ml",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),),
                  ),
                  Padding(padding: EdgeInsets.only(top:10,),
                    child: Text("Flowrte: $flowRate L/min",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),),
                  )
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.blueGrey[50],
              child: RefreshIndicator(
                onRefresh: _refreshData,
                child: _data.isEmpty
                    ? Center(child: CircularProgressIndicator())
                    : ListView.builder(
                  itemCount: _data.length - 1, // Exclude the first row
                  itemBuilder: (context, index) {
                    final reversedIndex = _data.length - index - 2; // Reverse the index and exclude the first row
                    final rawDate = _data[reversedIndex + 1][1];
                    final formattedDate = formatDateString(rawDate);

                    return Card(
                      child: ListTile(
                        title: Text('$formattedDate'), // Adjust index accordingly
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total Consumption: ${_data[reversedIndex + 1][0]} m³'), // Adjust index accordingly
                            //Text('Column B: $formattedDate'), // Adjust index accordingly with formatted date
                            Text('Daily Consumption: ${_data[reversedIndex + 1][2]} m³'), // Adjust index accordingly
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
