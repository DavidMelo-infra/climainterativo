import 'package:flutter/material.dart';
import 'package:clima_interativo/models/weather_notification_model.dart';
import 'package:clima_interativo/services/weather_notification_manager.dart';
import 'package:clima_interativo/services/local_storage_service.dart';

class WeatherNotificationsScreen extends StatefulWidget {
  @override
  _WeatherNotificationsScreenState createState() =>
      _WeatherNotificationsScreenState();
}

class _WeatherNotificationsScreenState
    extends State<WeatherNotificationsScreen> {
  final WeatherNotificationManager _notificationManager =
      WeatherNotificationManager();
  late WeatherNotificationSettings _settings;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _settings = await LocalStorageService.getNotificationSettings();
    setState(() => _isLoading = false);
  }

  Future<void> _saveSettings() async {
    await LocalStorageService.saveNotificationSettings(_settings);
    await _notificationManager.setupNotifications(_settings);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Configurações salvas!')),
    );
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _settings.notificationTime,
    );

    if (picked != null) {
      setState(() {
        _settings = _settings.copyWith(notificationTime: picked);
      });
      await _saveSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Notificações')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Notificações do Clima'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveSettings,
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Ativar/Desativar notificações
          Card(
            child: SwitchListTile(
              title: Text('Ativar Notificações',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Receba alertas sobre as condições climáticas'),
              value: _settings.enabled,
              onChanged: (value) {
                setState(() {
                  _settings = _settings.copyWith(enabled: value);
                });
                _saveSettings();
              },
            ),
          ),

          SizedBox(height: 16),

          // Horário da notificação diária
          Card(
            child: ListTile(
              title: Text('Horário da Notificação Diária'),
              subtitle: Text(_settings.notificationTime.format(context)),
              leading: Icon(Icons.access_time),
              onTap: _selectTime,
            ),
          ),

          SizedBox(height: 16),

          // Alertas
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tipos de Alertas',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  SwitchListTile(
                    title: Text('Alertas de Chuva'),
                    subtitle:
                        Text('Receba alertas quando houver previsão de chuva'),
                    value: _settings.alertRain,
                    onChanged: _settings.enabled
                        ? (value) {
                            setState(() {
                              _settings = _settings.copyWith(alertRain: value);
                            });
                            _saveSettings();
                          }
                        : null,
                  ),
                  SwitchListTile(
                    title: Text('Temperaturas Extremas'),
                    subtitle:
                        Text('Alertas para temperaturas muito altas ou baixas'),
                    value: _settings.alertExtremeTemp,
                    onChanged: _settings.enabled
                        ? (value) {
                            setState(() {
                              _settings =
                                  _settings.copyWith(alertExtremeTemp: value);
                            });
                            _saveSettings();
                          }
                        : null,
                  ),
                  SwitchListTile(
                    title: Text('Vento Forte'),
                    subtitle: Text(
                        'Alertas para ventos acima de ${_settings.windSpeedThreshold} km/h'),
                    value: _settings.alertWind,
                    onChanged: _settings.enabled
                        ? (value) {
                            setState(() {
                              _settings = _settings.copyWith(alertWind: value);
                            });
                            _saveSettings();
                          }
                        : null,
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 16),

          // Limiares de temperatura
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Configurações de Temperatura',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                'Temp. Mínima: ${_settings.minTempThreshold}°C'),
                            Slider(
                              value: _settings.minTempThreshold.toDouble(),
                              min: -10,
                              max: 15,
                              divisions: 25,
                              label: '${_settings.minTempThreshold}°C',
                              onChanged: _settings.enabled
                                  ? (value) {
                                      setState(() {
                                        _settings = _settings.copyWith(
                                            minTempThreshold: value.round());
                                      });
                                      _saveSettings();
                                    }
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                'Temp. Máxima: ${_settings.maxTempThreshold}°C'),
                            Slider(
                              value: _settings.maxTempThreshold.toDouble(),
                              min: 30,
                              max: 45,
                              divisions: 15,
                              label: '${_settings.maxTempThreshold}°C',
                              onChanged: _settings.enabled
                                  ? (value) {
                                      setState(() {
                                        _settings = _settings.copyWith(
                                            maxTempThreshold: value.round());
                                      });
                                      _saveSettings();
                                    }
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
