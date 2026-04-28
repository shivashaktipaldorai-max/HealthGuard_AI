import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';

void main() {
  runApp(HealthGuardApp());
}

class HealthGuardApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MainScreen(),
    );
  }
}

// 📱 MAIN NAVIGATION
class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int index = 0;

  final screens = [
    HomeScreen(),
    HistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) => setState(() => index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
        ],
      ),
    );
  }
}

// 🏠 HOME SCREEN
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int heartRate = 78;
  double temperature = 36.8;
  List<Map<String, dynamic>> history = [];

  String getGreeting() {
    var h = DateTime.now().hour;
    if (h < 12) return "Good Morning 👋";
    if (h < 18) return "Good Afternoon 👋";
    return "Good Evening 👋";
  }

  String getHealthStatus() {
    if (heartRate > 100) return "⚠ High Heart Rate!";
    if (temperature > 38) return "⚠ Fever Detected!";
    return "✅ Normal";
  }

  String getSuggestion() {
    if (heartRate > 100) return "Try to relax & avoid stress.";
    if (temperature > 38) return "Drink water & take rest.";
    return "You're doing great! Stay healthy 💪";
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('history', jsonEncode(history));
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('history');
    if (data != null) {
      setState(() {
        history = List<Map<String, dynamic>>.from(jsonDecode(data));
      });
    }
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  // 🚨 FIXED SOS FUNCTION
  Future<void> sendSOS() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Location permission permanently denied")),
        );
        return;
      }

      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      String link =
          "https://maps.google.com/?q=${pos.latitude},${pos.longitude}";

      final Uri phone = Uri(scheme: 'tel', path: '112');

      if (await canLaunchUrl(phone)) {
        await launchUrl(phone);
      }

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("Emergency 🚨"),
          content: Text("Live Location:\n$link"),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("SOS failed: $e")),
      );
    }
  }

  Widget glassCard(IconData icon, String title, String value, Color color) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: TextStyle(color: Colors.white)),
        subtitle: Text(value, style: TextStyle(color: Colors.white70)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue, Colors.purple],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text("HealthGuard AI",
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),

                  Text(getGreeting(),
                      style: TextStyle(color: Colors.white70)),

                  SizedBox(height: 20),

                  glassCard(Icons.favorite, "Heart Rate",
                      "$heartRate bpm", Colors.red),
                  glassCard(Icons.thermostat, "Temperature",
                      "$temperature °C", Colors.orange),

                  SizedBox(height: 10),

                  Text(getHealthStatus(),
                      style: TextStyle(color: Colors.white)),

                  Text(getSuggestion(),
                      style: TextStyle(color: Colors.white70)),

                  SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AddDataScreen()),
                      );

                      if (result != null) {
                        setState(() {
                          heartRate = result['heartRate'];
                          temperature = result['temperature'];
                          history.add(result);
                        });
                        await saveData();
                      }
                    },
                    child: Text("Add Data"),
                  ),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: sendSOS,
                    child: Text("SOS"),
                  ),

                  SizedBox(height: 20),

                  Container(
                    height: 200,
                    color: Colors.white,
                    child: LineChart(
                      LineChartData(
                        titlesData: FlTitlesData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            isCurved: true,
                            spots: history.asMap().entries.map((e) {
                              return FlSpot(
                                e.key.toDouble(),
                                (e.value['heartRate'] as int).toDouble(),
                              );
                            }).toList(),
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
    );
  }
}

// 📜 HISTORY
class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List history = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  load() async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('history');
    if (data != null) setState(() => history = jsonDecode(data));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("History")),
      body: ListView.builder(
        itemCount: history.length,
        itemBuilder: (_, i) => ListTile(
          title: Text(
              "${history[i]['heartRate']} bpm | ${history[i]['temperature']}°C"),
        ),
      ),
    );
  }
}

// ➕ ADD DATA
class AddDataScreen extends StatelessWidget {
  final heart = TextEditingController();
  final temp = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add Data")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: heart,
              decoration: InputDecoration(labelText: "Heart Rate"),
            ),
            TextField(
              controller: temp,
              decoration: InputDecoration(labelText: "Temperature"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (heart.text.isEmpty || temp.text.isEmpty) return;

                Navigator.pop(context, {
                  'heartRate': int.parse(heart.text),
                  'temperature': double.parse(temp.text),
                });
              },
              child: Text("Save"),
            )
          ],
        ),
      ),
    );
  }
}