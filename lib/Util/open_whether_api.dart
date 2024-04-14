import 'dart:convert';
import 'package:http/http.dart' as http;

class AirQualityData {
  final int aqi;
  final Map<String, double> gases;

  AirQualityData({required this.aqi, required this.gases});

  factory AirQualityData.fromJson(Map<String, dynamic> json) {
    Map<String, double> gases = {
      'CO': json["list"][0]['components']['co'].toDouble(),
      'NO': json["list"][0]['components']['no'].toDouble(),
      'NO2': json["list"][0]['components']['no2'].toDouble(),
      'O3': json["list"][0]['components']['o3'].toDouble(),
      'SO2': json["list"][0]['components']['so2'].toDouble(),
      'PM2.5': json["list"][0]['components']['pm2_5'].toDouble(),
      'PM10': json["list"][0]['components']['pm10'].toDouble(),
      'NH3': json["list"][0]['components']['nh3'].toDouble(),
    };

    return AirQualityData(
      aqi: json['list'][0]['main']['aqi'],
      gases: gases,
    );
  }
}

class OpenWeatherMapApi {
  final String apiKey = "b08e114614237588ee72b8a7cbb0c3c9";
  final String baseUrl = 'http://api.openweathermap.org/data/2.5/air_pollution';

  Future<AirQualityData?> fetchAirQuality(double lat, double lon) async {
    final url = '$baseUrl?lat=$lat&lon=$lon&appid=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return AirQualityData.fromJson(jsonData);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}
