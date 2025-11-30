import 'package:clima_interativo/services/weather_service.dart';
import 'package:clima_interativo/services/notification_service.dart';
import 'package:clima_interativo/models/weather_notification_model.dart';

class WeatherNotificationManager {
  static final WeatherNotificationManager _instance =
      WeatherNotificationManager._internal();
  factory WeatherNotificationManager() => _instance;
  WeatherNotificationManager._internal();

  final NotificationService _notificationService = NotificationService();
  WeatherNotificationSettings _settings = WeatherNotificationSettings();
  bool _isMonitoring = false;

  // Inicializar o manager
  Future<void> initialize() async {
    await _notificationService.initialize();
    print('✅ WeatherNotificationManager inicializado');
  }

  // Configurar notificações
  Future<void> setupNotifications(
      WeatherNotificationSettings newSettings) async {
    _settings = newSettings;

    if (_settings.enabled) {
      await _scheduleDailyNotifications();
      await _startWeatherMonitoring();
    } else {
      await _stopWeatherMonitoring();
      await _notificationService.cancelScheduledNotifications();
    }
  }

  // Agendar notificações diárias
  Future<void> _scheduleDailyNotifications() async {
    if (!_settings.enabled) return;

    for (final city in _settings.monitoredCities) {
      try {
        final weatherData = await WeatherService.getCurrentWeather(city);
        if (weatherData['success'] == true) {
          final temp = weatherData['temperature'];
          final description = weatherData['description'];
          final cityName = weatherData['city'];

          final message = '${temp}°C - ${description}';

          await _notificationService.scheduleDailyWeatherNotification(
            title: 'Clima em $cityName',
            body: message,
            time: _settings.notificationTime,
          );
        }
      } catch (e) {
        print('❌ Erro ao agendar notificação para $city: $e');
      }
    }
  }

  // Iniciar monitoramento para alertas
  Future<void> _startWeatherMonitoring() async {
    if (_isMonitoring) return;

    _isMonitoring = true;
    print('🔍 Iniciando monitoramento climático...');

    // Monitorar a cada 30 minutos
    await _checkWeatherAlerts();
  }

  // Parar monitoramento
  Future<void> _stopWeatherMonitoring() async {
    _isMonitoring = false;
    print('⏹️ Monitoramento climático parado');
  }

  // Verificar alertas climáticos
  Future<void> _checkWeatherAlerts() async {
    if (!_isMonitoring || !_settings.enabled) return;

    for (final city in _settings.monitoredCities) {
      try {
        final weatherData = await WeatherService.getCurrentWeather(city);
        if (weatherData['success'] == true) {
          await _evaluateWeatherAlerts(weatherData, city);
        }
      } catch (e) {
        print('❌ Erro ao verificar alertas para $city: $e');
      }
    }

    // Agendar próxima verificação em 30 minutos
    if (_isMonitoring) {
      Future.delayed(const Duration(minutes: 30), _checkWeatherAlerts);
    }
  }

  // Avaliar condições para alertas
  Future<void> _evaluateWeatherAlerts(
      Map<String, dynamic> weatherData, String city) async {
    final temp = weatherData['temperature'];
    final mainCondition = weatherData['main'];
    final windSpeed = weatherData['wind_speed'];
    final cityName = weatherData['city'];

    // Alerta de temperatura extrema
    if (_settings.alertExtremeTemp &&
        (temp <= _settings.minTempThreshold ||
            temp >= _settings.maxTempThreshold)) {
      final type = temp <= _settings.minTempThreshold ? 'frio' : 'calor';
      await _notificationService.showWeatherAlert(
        title: '⚠️ Temperatura Extrema em $cityName',
        body: 'Temperatura de ${temp}°C. Muito $type! Tome cuidados.',
        alertType: 'extreme_temp',
      );
    }

    // Alerta de chuva
    if (_settings.alertRain &&
        (mainCondition.contains('Rain') ||
            mainCondition.contains('Thunderstorm'))) {
      await _notificationService.showWeatherAlert(
        title: '🌧️ Chuva em $cityName',
        body: 'Previsão de chuva. Leve um guarda-chuva!',
        alertType: 'rain',
      );
    }

    // Alerta de vento forte
    if (_settings.alertWind && windSpeed >= _settings.windSpeedThreshold) {
      await _notificationService.showWeatherAlert(
        title: '💨 Vento Forte em $cityName',
        body: 'Ventos de ${windSpeed.toStringAsFixed(1)} km/h. Tome cuidado!',
        alertType: 'wind',
      );
    }
  }

  // Getters
  WeatherNotificationSettings get settings => _settings;
  bool get isMonitoring => _isMonitoring;
}
