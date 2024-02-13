import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // Import the intl package
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // ... Existing code ...

  String formatDateString(String dateString) {
    try {
      DateTime dateTime = DateTime.parse(dateString);
      return DateFormat('yyyy/MM/dd').format(dateTime);
    } catch (e) {
      // Handle the exception, you can log it or return a default value
      print('Error parsing date: $e');
      return dateString; // Return the original string as a fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... Existing code ...

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
                  // ... Existing code ...

                  // Adjust the date formatting below
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
                    "Cubic Meter: $cubicCompsumption m3",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Text(
                      "Liter: $waterConsumption ml",
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
                  itemCount: _data.length - 1, // Exclude the first row
                  itemBuilder: (context, index) {
                    final reversedIndex = _data.length - index - 2; // Reverse the index and exclude the first row
                    final rawDate = _data[reversedIndex + 1][1];
                    final formattedDate = formatDateString(rawDate);

                    return Card(
                      child: ListTile(
                        title: Text('Day ${reversedIndex + 1}'), // Adjust index accordingly
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Column A: ${_data[reversedIndex + 1][0]}'), // Adjust index accordingly
                            Text('Column B: $formattedDate'), // Adjust index accordingly with formatted date
                            Text('Column C: ${_data[reversedIndex + 1][2]}'), // Adjust index accordingly
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
