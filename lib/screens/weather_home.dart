import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'history_page.dart'; // Import the HistoryPage file

class WeatherHomePage extends StatefulWidget {
  const WeatherHomePage({Key? key}) : super(key: key);

  @override
  _WeatherHomePageState createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends State<WeatherHomePage> {
  final TextEditingController _cityController = TextEditingController();
  Map<String, dynamic>? weatherData;

  final String apiKey = 'your_key';

  Future<void> fetchWeather() async {
    final city = _cityController.text.trim();
    if (city.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a city name!')));
      return;
    }

    final url =
        'https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('City not found');
      }

      final data = jsonDecode(response.body);
      setState(() {
        weatherData = data;
      });

      await saveToFirestore(data);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> saveToFirestore(Map<String, dynamic> data) async {
    try {
      final rainStatus =
          data['weather'][0]['description'] ?? 'No rain'; // Description
      final rainVolume =
      data['rain'] != null ? '${data['rain']['1h'] ?? 0} mm' : 'No data';

      final weatherDetails = {
        'city': data['name'],
        'temperature': data['main']['temp'],
        'real_feel': data['main']['feels_like'],
        'humidity': data['main']['humidity'],
        'visibility': data['visibility'] / 1000,
        'wind_speed': data['wind']['speed'],
        'pressure': data['main']['pressure'],
        'cloud_cover': data['clouds']['all'],
        'rain_status': '$rainStatus ($rainVolume)',
        'timestamp': Timestamp.now(),

      };

      await FirebaseFirestore.instance
          .collection('weatherData')
          .add(weatherDetails);

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Weather data saved to Firestore!')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error saving data: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[400],
        title: const Text('FindWeather',style: TextStyle(color: Colors.white),),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),color: Colors.white,
            onPressed: () {
              // Navigate to the HistoryPage
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryPage()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            const SizedBox(height: 20),
            TextField(
              controller: _cityController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter City Name',
                fillColor: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              autofocus: true,
              onPressed: fetchWeather,
              child: const Text('Get Weather'),
             style: ElevatedButton.styleFrom(backgroundColor: Colors.blue,foregroundColor: Colors.white),

            ),
            const SizedBox(height: 20),
            if (weatherData != null) ...[
              const Text(
                'Weather Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: SingleChildScrollView(
                  child: Table(
                    border: TableBorder.all(color: Colors.black26),
                    columnWidths: const {
                      0: FlexColumnWidth(1),
                      1: FlexColumnWidth(2),
                    },
                    children: [
                      _buildTableRow('City', weatherData!['name']),
                      _buildTableRow('Temperature',
                          '${weatherData!['main']['temp']}°C'),
                      _buildTableRow('Real Feel',
                          '${weatherData!['main']['feels_like']}°C'),
                      _buildTableRow('Humidity',
                          '${weatherData!['main']['humidity']}%'),
                      _buildTableRow('Visibility',
                          '${weatherData!['visibility'] / 1000} km'),
                      _buildTableRow('Wind Speed',
                          '${weatherData!['wind']['speed']} m/s'),
                      _buildTableRow(
                          'Pressure', '${weatherData!['main']['pressure']} hPa'),
                      _buildTableRow('Cloud Cover',
                          '${weatherData!['clouds']['all']}%'),
                      _buildTableRow('Rain Status',
                          weatherData!['weather'][0]['description']),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  TableRow _buildTableRow(String attribute, String value) {
    return TableRow(children: [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(attribute, style: const TextStyle(fontWeight: FontWeight.bold)),

      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(value),
      ),
    ]);
  }
}
