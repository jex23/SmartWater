import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:fancy_bottom_navigation_2/fancy_bottom_navigation.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database =
      FirebaseDatabase.instance.reference().child('Water/Reading');
  final DatabaseReference _databse2 =
      FirebaseDatabase.instance.reference().child('Water/Flowrate');
  final DatabaseReference _databse3 =
      FirebaseDatabase.instance.reference().child('Water/WaterReading');
  final String apiUrl =
      'https://script.google.com/macros/s/AKfycbzv44RSA-eJGEspgF9g78wSWcJt4Au9b2tsEmg0qf1_Ma67EkKPt6xmN1HzPg6A1lSZbw/exec';
  List<List<String>> _data = [];
  List<String> _timestamps = [];
  List<double> _literReadings = [];


  late PageController _pageController;
  int _currentIndex = 0;
  bool _darkMode = false;

  Future<void> _fetchData() async {
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      setState(() {
        _data = List<List<String>>.from(
            json.decode(response.body).map((row) => List<String>.from(row)));
        _saveDataToLocal();
        extractChartData(); // Populate _timestamps and _literReadings lists
      });
    } else {
      throw Exception('Failed to load data');
    }
    // Print the _timestamps list
    //print(_timestamps);
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
    _saveCapitalizedPrefix();

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
    final List<String>? timestampsJson = prefs.getStringList('timestamps');
    final List<String>? literReadingsJson =
        prefs.getStringList('literReadings');
    final String? dataString = prefs.getString('data');

    if (dataString != null) {
      final List<dynamic> jsonData = json.decode(dataString);
      setState(() {
        _data = jsonData.map((row) => List<String>.from(row)).toList();
      });
    }

    if (timestampsJson != null && literReadingsJson != null) {
      _timestamps = timestampsJson
          .map((timestamp) => json.decode(timestamp))
          .toList()
          .cast<String>();
      _literReadings = literReadingsJson
          .map((reading) => json.decode(reading))
          .toList()
          .cast<double>();
    }
  }

  /*Future<void> _loadDataFromLocal() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String>? timestampsJson = prefs.getStringList('timestamps');
    final List<String>? literReadingsJson = prefs.getStringList('literReadings');

    if (timestampsJson != null && literReadingsJson != null) {
      _timestamps = timestampsJson.map((timestamp) => json.decode(timestamp)).toList().cast<String>();
      _literReadings = literReadingsJson.map((reading) => json.decode(reading)).toList().cast<double>();
    }
  }*/

  Future<void> _saveCapitalizedPrefix() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final User? user = _auth.currentUser;
    final String emailPrefix =
        user?.email?.split('@').first.replaceAll(RegExp(r'[0-9]'), '') ?? '';
    final String capitalizedPrefix = emailPrefix.isNotEmpty
        ? emailPrefix[0].toUpperCase() + emailPrefix.substring(1)
        : '';
    prefs.setString('capitalizedPrefix', capitalizedPrefix);
  }

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 10,
    );
    Widget text;

    if (_timestamps.isNotEmpty) {
      final String dateString = _timestamps[value.toInt()];
      List<String> parts = dateString.split(' ');

      if (parts.length >= 4) {
        String day = parts[2];
        String month = parts[1];

        String formattedDate = '$month $day';

        text = RotatedBox(
          quarterTurns: 3, // Rotate text by 90 degrees (counter-clockwise)
          child: Text(formattedDate, style: style),
        );
      } else {
        text = const Text('', style: style);
      }
    } else {
      text = const Text('', style: style);
    }

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: text,
    );
  }

  /*Future<void> _saveDataToLocal() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('data', json.encode(_data));
  }*/

  Future<void> _saveDataToLocal() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> timestampsJson =
        _timestamps.map((timestamp) => json.encode(timestamp)).toList();
    final List<String> literReadingsJson =
        _literReadings.map((reading) => json.encode(reading)).toList();

    prefs.setStringList('timestamps', timestampsJson);
    prefs.setStringList('literReadings', literReadingsJson);
    prefs.setString('data', json.encode(_data));
  }

  void extractChartData() {
    _timestamps.clear();
    _literReadings.clear();

    for (int i = 1; i < _data.length; i++) {
      String timestamp = _data[i][1];
      double literReading = double.tryParse(_data[i][2]) ?? 0.0;

      _timestamps.add(timestamp);
      _literReadings.add(literReading);
    }
  }

  Widget buildHomePage() {
    User? user = _auth.currentUser;
    String emailPrefix =
        user?.email?.split('@').first.replaceAll(RegExp(r'[0-9]'), '') ?? '';
    String capitalizedPrefix = emailPrefix.isNotEmpty
        ? emailPrefix[0].toUpperCase() + emailPrefix.substring(1)
        : '';

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
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text(
                    "Liter: $waterConsumption L",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text(
                    "Flowrte: $flowRate L/min",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
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
                                Text(
                                    'Total Consumption: ${_data[reversedIndex + 1][0]} m³'),
                                Text(
                                    'Daily Consumption: ${_data[reversedIndex + 1][2]} m³'),
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
    double predictNextDayConsumption(List<double> yValues, int n) {
      double sumX = 0;
      double sumY = 0;
      for (int i = 0; i < n; i++) {
        sumX += (i + 1);
        sumY += yValues[i];
      }
      double meanX = sumX / n;
      double meanY = sumY / n;

      double numerator = 0;
      double denominator = 0;
      for (int i = 0; i < n; i++) {
        numerator += (i + 1 - meanX) * (yValues[i] - meanY);
        denominator += pow((i + 1 - meanX), 2);
      }
      double slope = numerator / denominator;
      double intercept = meanY - slope * meanX;

      return slope * (n + 1) + intercept;
    }

    double predictNextWeekConsumption(List<double> yValues, int n) {
      // Calculate the slope and intercept for linear regression
      double slope;
      double intercept;
      double sumX = 0;
      double sumY = 0;
      for (int i = 0; i < n; i++) {
        sumX += (i + 1);
        sumY += yValues[i];
      }
      double meanX = sumX / n;
      double meanY = sumY / n;

      double numerator = 0;
      double denominator = 0;
      for (int i = 0; i < n; i++) {
        numerator += (i + 1 - meanX) * (yValues[i] - meanY);
        denominator += pow((i + 1 - meanX), 2);
      }
      slope = numerator / denominator;
      intercept = meanY - slope * meanX;

      // Predict the consumption for the next week
      double nextWeek = slope * (n + 7) + intercept;
      return nextWeek;
    }



    double predictNextMonthConsumption(List<double> yValues, int n) {
      // Calculate the slope and intercept for linear regression
      double slope;
      double intercept;
      double sumX = 0;
      double sumY = 0;
      for (int i = 0; i < n; i++) {
        sumX += (i + 1);
        sumY += yValues[i];
      }
      double meanX = sumX / n;
      double meanY = sumY / n;

      double numerator = 0;
      double denominator = 0;
      for (int i = 0; i < n; i++) {
        numerator += (i + 1 - meanX) * (yValues[i] - meanY);
        denominator += pow((i + 1 - meanX), 2);
      }
      slope = numerator / denominator;
      intercept = meanY - slope * meanX;

      // Predict the consumption for the next month
      double nextMonth = slope * (n + 30) + intercept;
      return nextMonth;
    }




    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top:5.0, bottom: 5.0, right:16.0, left:16.0),
              child: Card(
                color: Colors.transparent,
                // Set to transparent to apply gradient directly
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16.0),
                    gradient: LinearGradient(
                      colors: [Colors.green, Colors.blue],
                      // Adjust colors as needed
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Water Consumption',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black, // Adjust text color as needed
                          ),
                        ),
                        SizedBox(height: 20),
                        Container(
                          height: 300, // Set the desired height for your chart
                          child: LineChart(
                            LineChartData(
                              // Customize your line chart data here
                              gridData: FlGridData(
                                  show: true,
                                  drawHorizontalLine: true,
                                  drawVerticalLine: true),
                              titlesData: FlTitlesData(
                                show: true,
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 50,
                                    interval: 1,
                                    getTitlesWidget: bottomTitleWidgets,
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    interval: 0.2,
                                    reservedSize: 40,
                                  ),
                                ),
                              ),
                              backgroundColor: Colors.transparent,
                              //minX: 0,
                              // maxX: 6, // Adjust based on your data
                              minY: 0,
                              maxY: 0.5,
                              // Adjust based on your data
                              lineBarsData: [
                                LineChartBarData(
                                  spots: List.generate(
                                    _timestamps.length,
                                        (index) => FlSpot(
                                        index.toDouble(), _literReadings[index]),
                                  ),
                                  isCurved: true,
                                  color: Colors.black,
                                  dotData: FlDotData(show: false),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.deepOrange.withOpacity(0.7),
                                        Colors.purple
                                      ],
                                      stops: [0.0, 0.5],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: 20),
              child: Text(
                "Consumption Predictions",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 25,
                ),
              ),
            ),
            Card(
              margin: EdgeInsets.only(top:5.0, bottom: 5.0, right:16.0, left:16.0), // Set edge insets
              elevation: 5.0, // Add elevation (shadow)
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0), // Rounded corners
              ),
              child: Container(
                padding: EdgeInsets.all(10.0), // Padding inside the container
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                    colors: [Colors.blue, Colors.green], // Gradient colors
                  ),
                  borderRadius: BorderRadius.circular(10.0), // Rounded corners
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Next Day Consumption Prediction',
                          style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),

                    Text(
                      'Cubic Meters: ${predictNextDayConsumption(_literReadings, _timestamps.length).toStringAsFixed(5)} m3',
                      style: TextStyle(fontSize: 16.0),
                    ),
                  ],
                ),
              ),
            ),
            Card(
              margin: EdgeInsets.only(top:5.0, bottom: 5.0, right:16.0, left:16.0), // Set edge insets
              elevation: 5.0, // Add elevation (shadow)
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0), // Rounded corners
              ),
              child: Container(
                padding: EdgeInsets.all(10.0), // Padding inside the container
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                    colors: [Colors.blue, Colors.green], // Gradient colors
                  ),
                  borderRadius: BorderRadius.circular(10.0), // Rounded corners
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Next Week Consumption Prediction',
                          style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),

                    Text(
                      'Cubic Meters: ${predictNextWeekConsumption(_literReadings, _timestamps.length).toStringAsFixed(5)} m3',
                      style: TextStyle(fontSize: 16.0),
                    ),
                  ],
                ),
              ),
            ),
            Card(
              margin: EdgeInsets.only(top:5.0, bottom: 5.0, right:16.0, left:16.0), // Set edge insets
              elevation: 5.0, // Add elevation (shadow)
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0), // Rounded corners
              ),
              child: Container(
                padding: EdgeInsets.all(10.0), // Padding inside the container
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                    colors: [Colors.blue, Colors.green], // Gradient colors
                  ),
                  borderRadius: BorderRadius.circular(10.0), // Rounded corners
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Next Month Consumption Prediction',
                          style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),

                    Text(
                      'Cubic Meters: ${predictNextMonthConsumption(_literReadings, _timestamps.length).toStringAsFixed(5)} m3',
                      style: TextStyle(fontSize: 16.0),
                    ),
                  ],
                ),
              ),
            ),




          ],
        ),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Water Meter IOT'),
        // Add hamburger menu button
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
      ),
      // Add Drawer for hamburger menu
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              child: Text('Menu'),
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
            ),
            ListTile(
              title: Text('Sign Out'),
              onTap: () async {
                await _auth.signOut();
                Navigator.pushReplacementNamed(context, '/signin');
              },
            ),
            ListTile(
              title: Text('Dark Mode'),
              trailing: Switch(
                value: _darkMode,
                onChanged: (value) {
                  setState(() {
                    _darkMode = value;
                    // Apply dark mode changes here
                  });
                },
              ),
            ),
          ],
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: NeverScrollableScrollPhysics(),
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
      bottomNavigationBar: FancyBottomNavigation(
        circleColor: Colors.blue,
        // Set color for the unselected item circle
        activeIconColor: Colors.white,
        // Set color for the selected item icon
        inactiveIconColor: Colors.blue,
        // Set color for the unselected item icon
        textColor: Colors.blue,
        // Set color for the text
        barBackgroundColor: Colors.white,
        // Set color for the bottom bar background
        tabs: [
          TabData(
            iconData: Icons.home,
            title: "Homepage",
          ),
          TabData(
            iconData: Icons.data_usage,
            title: "DataScreen",
          ),
        ],

        initialSelection: _currentIndex,
        onTabChangedListener: (position) {
          setState(() {
            _currentIndex = position;
            _pageController.animateToPage(
              position,
              duration: Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          });
        },
      ),
    );
  }
}
