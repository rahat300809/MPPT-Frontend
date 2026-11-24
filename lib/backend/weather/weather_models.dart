enum WeatherKind {
  sunny,
  afternoon,
  cloudy,
  rainy,
  dusk,
  night,
}

extension WeatherKindX on WeatherKind {
  bool get isNight => this == WeatherKind.night || this == WeatherKind.dusk;

  bool get showsCuteSun =>
      this == WeatherKind.sunny || this == WeatherKind.afternoon;

  String get label {
    switch (this) {
      case WeatherKind.sunny:
        return 'Sunny';
      case WeatherKind.afternoon:
        return 'Afternoon Sun';
      case WeatherKind.cloudy:
        return 'Partly Cloudy';
      case WeatherKind.rainy:
        return 'Rainy';
      case WeatherKind.dusk:
        return 'Golden Hour';
      case WeatherKind.night:
        return 'Clear Night';
    }
  }
}

class WeatherLive {
  final double temperatureC;
  final double humidityPercent;
  final WeatherKind? kind;

  const WeatherLive({
    this.temperatureC = 28.5,
    this.humidityPercent = 65.0,
    this.kind = WeatherKind.sunny,
  });
}
