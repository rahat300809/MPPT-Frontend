/// Visual presets matching HelioGlass home hero (house + sky only).
enum WeatherKind {
  sunny,
  afternoon,
  cloudy,
  rainy,
  dusk,
  night,
}

extension WeatherKindX on WeatherKind {
  String get label {
    switch (this) {
      case WeatherKind.sunny:
        return 'Sunny';
      case WeatherKind.afternoon:
        return 'Afternoon';
      case WeatherKind.cloudy:
        return 'Cloudy';
      case WeatherKind.rainy:
        return 'Rainy';
      case WeatherKind.dusk:
        return 'Dusk';
      case WeatherKind.night:
        return 'Night';
    }
  }

  String get emoji {
    switch (this) {
      case WeatherKind.sunny:
        return '☀️';
      case WeatherKind.afternoon:
        return '🌤️';
      case WeatherKind.cloudy:
        return '☁️';
      case WeatherKind.rainy:
        return '🌧️';
      case WeatherKind.dusk:
        return '🌆';
      case WeatherKind.night:
        return '🌙';
    }
  }

  bool get isNight => this == WeatherKind.night;

  bool get showsCuteSun =>
      this == WeatherKind.sunny ||
      this == WeatherKind.afternoon ||
      this == WeatherKind.dusk;
}

class WeatherSnapshot {
  final WeatherKind kind;
  final double temperatureC;
  final double humidityPercent;
  final int weatherCode;
  final bool isDay;
  final double? latitude;
  final double? longitude;
  final DateTime fetchedAt;

  const WeatherSnapshot({
    required this.kind,
    required this.temperatureC,
    required this.humidityPercent,
    required this.weatherCode,
    required this.isDay,
    this.latitude,
    this.longitude,
    required this.fetchedAt,
  });

  /// Map Open-Meteo WMO weather codes → HelioGlass-style visual kind.
  static WeatherKind kindFromCode(int code, {required bool isDay}) {
    if (!isDay) return WeatherKind.night;
    if (code == 0) return WeatherKind.sunny;
    if (code == 1 || code == 2) return WeatherKind.afternoon;
    if (code == 3 || code == 45 || code == 48) return WeatherKind.cloudy;
    if (code >= 51 && code <= 67) return WeatherKind.rainy;
    if (code >= 80 && code <= 82) return WeatherKind.rainy;
    if (code >= 95) return WeatherKind.rainy;
    if (code >= 71 && code <= 86) return WeatherKind.cloudy;
    return WeatherKind.cloudy;
  }
}
