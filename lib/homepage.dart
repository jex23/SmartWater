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
  late PageController _pageController;
  int _currentIndex = 0;

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
      List<String> parts = dateString.split(' ');

      if (parts.length >= 4) {
        String day = parts[2];
        String month = parts[1];
        String year = parts[3];

        String formattedDate = '$month $day $year';

        return formattedDate;
      } else {
        return dateString;
      }
    } catch (e) {
      print('Error parsing date: $e');
      return dateString;
    }
  }

  Future<void> _refreshData() async {
    await _fetchData();
  }

  double flowRate = 0.00;
  double waterConsumption = 0.0;
  double cubicCompsumption = 0.0;

  @override
  void initState() {
    super.initState();
    _loadDataFromLocal();
    _fetchData();
    Timer.periodic(Duration(seconds: 30), (Timer t) => _fetchData());

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

    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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

  Widget buildHomePage() {
    User? user = _auth.currentUser;
    String emailPrefix = user?.email?.split('@').first.replaceAll(RegExp(r'[0-9]'), '') ?? '';
    String capitalizedPrefix = emailPrefix.isNotEmpty ? emailPrefix[0].toUpperCase() + emailPrefix.substring(1) : '';

    return Column(
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
                Padding(padding: EdgeInsets.only(top: 10),
                  child: Text("Liter: $waterConsumption ml",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),),
                ),
                Padding(padding: EdgeInsets.only(top: 10),
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
                itemCount: _data.length - 1,
                itemBuilder: (context, index) {
                  final reversedIndex = _data.length - index - 2;
                  final rawDate = _data[reversedIndex + 1][1];
                  final formattedDate = formatDateString(rawDate);

                  return Card(
                    child: ListTile(
                      title: Text('$formattedDate'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Consumption: ${_data[reversedIndex + 1][0]} m³'),
                          Text('Daily Consumption: ${_data[reversedIndex + 1][2]} m³'),
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
    );
  }

  Widget buildDataScreen() {
    return Center(
      child: Text(
        'Hello',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Water Meter IOT'),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: [
          // Home Page
          buildHomePage(),

          // Data Screen Page
          buildDataScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.blue, // Set background color
        selectedItemColor: Colors.white, // Set selected item color
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            _pageController.animateToPage(
              index,
              duration: Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Homepage',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.data_usage),
            label: 'DataScreen',
          ),
        ],
      ),
    );
  }
}
