import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'weather_models.dart';

/// Live weather via Open-Meteo (no API key required). Supports UI preview overrides.
class WeatherService extends ChangeNotifier {
  WeatherSnapshot? live = WeatherSnapshot(
    kind: WeatherKind.sunny,
    temperatureC: 28.5,
    humidityPercent: 55.0,
    weatherCode: 0,
    isDay: true,
    fetchedAt: DateTime.now(),
  );
  WeatherKind? previewOverride;
  bool loading = false;
  String lastError = '';
  String locationLabel = 'Dhaka, BD';

  WeatherKind get displayKind =>
      previewOverride ?? live?.kind ?? WeatherKind.sunny;

  bool get isPreviewing => previewOverride != null;

  void setPreview(WeatherKind? kind) {
    previewOverride = kind;
    notifyListeners();
  }

  Future<void> refresh() async {
    loading = true;
    lastError = '';
    notifyListeners();
    try {
      const lat = 23.8103;
      const lon = 90.4125;
      locationLabel = '23.81, 90.41';

      final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': lat.toString(),
        'longitude': lon.toString(),
        'current': 'temperature_2m,relative_humidity_2m,weather_code,is_day',
        'timezone': 'auto',
      });
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final current = json['current'] as Map<String, dynamic>;
        final code = (current['weather_code'] as num).toInt();
        final isDay = (current['is_day'] as num).toInt() == 1;
        final temp = (current['temperature_2m'] as num).toDouble();
        final humidity =
            (current['relative_humidity_2m'] as num?)?.toDouble() ?? 55.0;

        live = WeatherSnapshot(
          kind: WeatherSnapshot.kindFromCode(code, isDay: isDay),
          temperatureC: temp,
          humidityPercent: humidity,
          weatherCode: code,
          isDay: isDay,
          latitude: lat,
          longitude: lon,
          fetchedAt: DateTime.now(),
        );
      }
    } catch (e) {
      lastError = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
