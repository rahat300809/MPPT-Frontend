import 'package:flutter/foundation.dart';
import 'weather_models.dart';

class WeatherService extends ChangeNotifier {
  final WeatherKind _currentKind = WeatherKind.sunny;
  WeatherKind? _previewKind;
  WeatherLive? _live = const WeatherLive(temperatureC: 29.0, humidityPercent: 62.0);
  bool _loading = false;
  String _lastError = '';

  WeatherKind get displayKind => _previewKind ?? _currentKind;
  WeatherLive? get live => _live;
  bool get isPreviewing => _previewKind != null;
  bool get loading => _loading;
  String get lastError => _lastError;

  void setPreview(WeatherKind? kind) {
    _previewKind = kind;
    notifyListeners();
  }

  Future<void> refresh() async {
    _loading = true;
    _lastError = '';
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 600));
    _live = const WeatherLive(temperatureC: 30.2, humidityPercent: 58.0);
    _loading = false;
    notifyListeners();
  }
}
