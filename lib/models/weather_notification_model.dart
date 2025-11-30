class WeatherNotificationSettings {
  final bool enabled;
  final TimeOfDay notificationTime;
  final List<String> monitoredCities;
  final bool alertRain;
  final bool alertExtremeTemp;
  final bool alertWind;
  final int minTempThreshold;
  final int maxTempThreshold;
  final int windSpeedThreshold;

  WeatherNotificationSettings({
    this.enabled = false,
    this.notificationTime = const TimeOfDay(hour: 8, minute: 0),
    this.monitoredCities = const [],
    this.alertRain = true,
    this.alertExtremeTemp = true,
    this.alertWind = false,
    this.minTempThreshold = 5,
    this.maxTempThreshold = 35,
    this.windSpeedThreshold = 15,
  });

  WeatherNotificationSettings copyWith({
    bool? enabled,
    TimeOfDay? notificationTime,
    List<String>? monitoredCities,
    bool? alertRain,
    bool? alertExtremeTemp,
    bool? alertWind,
    int? minTempThreshold,
    int? maxTempThreshold,
    int? windSpeedThreshold,
  }) {
    return WeatherNotificationSettings(
      enabled: enabled ?? this.enabled,
      notificationTime: notificationTime ?? this.notificationTime,
      monitoredCities: monitoredCities ?? this.monitoredCities,
      alertRain: alertRain ?? this.alertRain,
      alertExtremeTemp: alertExtremeTemp ?? this.alertExtremeTemp,
      alertWind: alertWind ?? this.alertWind,
      minTempThreshold: minTempThreshold ?? this.minTempThreshold,
      maxTempThreshold: maxTempThreshold ?? this.maxTempThreshold,
      windSpeedThreshold: windSpeedThreshold ?? this.windSpeedThreshold,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'notificationTime': {
        'hour': notificationTime.hour,
        'minute': notificationTime.minute,
      },
      'monitoredCities': monitoredCities,
      'alertRain': alertRain,
      'alertExtremeTemp': alertExtremeTemp,
      'alertWind': alertWind,
      'minTempThreshold': minTempThreshold,
      'maxTempThreshold': maxTempThreshold,
      'windSpeedThreshold': windSpeedThreshold,
    };
  }

  factory WeatherNotificationSettings.fromJson(Map<String, dynamic> json) {
    return WeatherNotificationSettings(
      enabled: json['enabled'] ?? false,
      notificationTime: TimeOfDay(
        hour: json['notificationTime']?['hour'] ?? 8,
        minute: json['notificationTime']?['minute'] ?? 0,
      ),
      monitoredCities: List<String>.from(json['monitoredCities'] ?? []),
      alertRain: json['alertRain'] ?? true,
      alertExtremeTemp: json['alertExtremeTemp'] ?? true,
      alertWind: json['alertWind'] ?? false,
      minTempThreshold: json['minTempThreshold'] ?? 5,
      maxTempThreshold: json['maxTempThreshold'] ?? 35,
      windSpeedThreshold: json['windSpeedThreshold'] ?? 15,
    );
  }
}
