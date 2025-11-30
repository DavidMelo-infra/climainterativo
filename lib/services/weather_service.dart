import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class WeatherService {
  // ✅ CONFIGURAÇÃO: OpenWeatherMap (atual + previsão)
  static const String _openWeatherApiKey = 'ecff47e3507241b6cc533b182d81a1c5';
  static const String _openWeatherBaseUrl =
      'https://api.openweathermap.org/data/2.5';
  static const String _openWeatherGeoUrl =
      'https://api.openweathermap.org/geo/1.0';

  // ✅ COORDENADAS DOS BAIRROS ESPECIAIS
  static const double _liberdadeLat = -23.5567;
  static const double _liberdadeLong = -46.6339;
  static const double _raioLiberdade = 1500;
  static const double _granjaJulietaLat = -23.6236;
  static const double _granjaJulietaLong = -46.6972;
  static const double _raioGranjaJulieta = 2000;

  // ✅ MÉTODO INTELIGENTE CORRIGIDO: Buscar previsão usando nome OU coordenadas
  static Future<Map<String, dynamic>> getFiveDayForecastSmart({
    String? cityName,
    double? lat,
    double? lon,
  }) async {
    print('🎯 EXECUTANDO getFiveDayForecastSmart');

    // ✅ CORREÇÃO: Tentar cidade primeiro (mais confiável)
    if (cityName != null && cityName.isNotEmpty) {
      print('🏙️ Buscando previsão por cidade: $cityName');
      final cityResult = await getFiveDayForecastByCity(cityName);
      if (cityResult['success']) {
        print('✅ Sucesso na busca por cidade');
        return cityResult;
      } else {
        print('❌ Falha na busca por cidade: ${cityResult['message']}');
      }
    }

    // ✅ CORREÇÃO: Só tentar coordenadas se disponíveis E se cidade falhou
    if (lat != null && lon != null) {
      print('📍 Buscando previsão por coordenadas: $lat, $lon');
      final coordsResult = await getFiveDayForecastByCoords(lat, lon);
      if (coordsResult['success']) {
        print('✅ Sucesso na busca por coordenadas');
        return coordsResult;
      } else {
        print('❌ Falha na busca por coordenadas: ${coordsResult['message']}');
      }
    }

    // ✅ CORREÇÃO: Mensagem mais específica
    if (cityName == null && (lat == null || lon == null)) {
      return {'success': false, 'message': 'Nenhuma localização fornecida'};
    }

    return {
      'success': false,
      'message': 'Não foi possível obter previsão para esta localização'
    };
  }

  // ✅ MÉTODO CORRIGIDO: Previsão por cidade usando OpenWeatherMap
  static Future<Map<String, dynamic>> getFiveDayForecastByCity(
      String cityName) async {
    print('🌤️ EXECUTANDO getFiveDayForecastByCity - OpenWeatherMap');
    try {
      final url =
          '$_openWeatherBaseUrl/forecast?q=$cityName&appid=$_openWeatherApiKey&units=metric&lang=pt_br';
      print('🌐 URL: $url');
      final response = await http.get(Uri.parse(url));
      print('📡 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Dados recebidos da API');
        return _parseOpenWeatherForecastData(data);
      } else if (response.statusCode == 404) {
        print('❌ Cidade não encontrada: $cityName');
        return {
          'success': false,
          'message': 'Cidade "$cityName" não encontrada'
        };
      } else {
        print('❌ Erro HTTP: ${response.statusCode} - ${response.body}');
        return {
          'success': false,
          'message': 'Erro na API: ${response.statusCode}'
        };
      }
    } catch (e) {
      print('❌ Erro no getFiveDayForecastByCity: $e');
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  // ✅ MÉTODO: Previsão por coordenadas usando OpenWeatherMap
  static Future<Map<String, dynamic>> getFiveDayForecastByCoords(
      double lat, double lon) async {
    print('🌤️ EXECUTANDO getFiveDayForecastByCoords - OpenWeatherMap');
    try {
      final url =
          '$_openWeatherBaseUrl/forecast?lat=$lat&lon=$lon&appid=$_openWeatherApiKey&units=metric&lang=pt_br';
      print('🌐 URL: $url');
      final response = await http.get(Uri.parse(url));
      print('📡 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Dados recebidos da API por coordenadas');
        return _parseOpenWeatherForecastData(data);
      } else {
        print('❌ Erro HTTP: ${response.statusCode} - ${response.body}');
        return {'success': false, 'message': 'Erro ao buscar previsão local'};
      }
    } catch (e) {
      print('❌ Erro no getFiveDayForecastByCoords: $e');
      return {'success': false, 'message': 'Erro de conexão'};
    }
  }

  // ✅ CORREÇÃO COMPLETA: Substitua o método _parseOpenWeatherForecastData por este:
  static Map<String, dynamic> _parseOpenWeatherForecastData(
      Map<String, dynamic> data) {
    final List<dynamic> forecastList = data['list'];
    final city = data['city'];
    print('📊 Processando ${forecastList.length} previsões da OpenWeatherMap');

    if (forecastList.isEmpty) {
      print('❌ Lista de previsões vazia');
      return {'success': false, 'message': 'Dados de previsão não disponíveis'};
    }

    // Agrupar previsões por dia
    final Map<String, List<Map<String, dynamic>>> dailyForecasts = {};
    for (final item in forecastList) {
      final dateTime = DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000);
      final dateKey = '${dateTime.year}-${dateTime.month}-${dateTime.day}';
      if (!dailyForecasts.containsKey(dateKey)) {
        dailyForecasts[dateKey] = [];
      }

      final weather = item['weather'][0];
      final main = item['main'];
      final pop = item['pop'] ?? 0.0;

      // ✅ CORREÇÃO: Converter TODOS os valores double para int de forma segura
      final temp = _safeToInt(main['temp']);
      final feelsLike = _safeToInt(main['feels_like']);
      final humidity = _safeToInt(main['humidity']);

      dailyForecasts[dateKey]!.add({
        'datetime': dateTime,
        'temperature': temp,
        'feels_like': feelsLike,
        'humidity': humidity,
        'description': weather['description'],
        'main': weather['main'],
        'icon': weather['icon'],
        'wind_speed': item['wind']?['speed'] ?? 0.0,
        'pop': (pop * 100).round(), // chance de chuva em porcentagem
      });
    }

    // Processar todos os dias disponíveis
    final List<Map<String, dynamic>> processedForecast = [];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    dailyForecasts.forEach((dateKey, hourlyData) {
      final date = DateTime.parse('$dateKey 12:00:00');

      if (date.isAfter(today.subtract(const Duration(days: 1)))) {
        final temperatures =
            hourlyData.map((h) => h['temperature'] as int).toList();
        final maxTemp = temperatures.reduce((a, b) => a > b ? a : b);
        final minTemp = temperatures.reduce((a, b) => a < b ? a : b);

        final conditions = hourlyData.map((h) => h['main']).toList();
        final mostFrequentCondition = _getMostFrequentCondition(conditions);

        final rainChances = hourlyData.map((h) => h['pop'] as int).toList();
        final maxRainChance = rainChances.isNotEmpty
            ? rainChances.reduce((a, b) => a > b ? a : b)
            : 0;

        final humidities = hourlyData.map((h) => h['humidity'] as int).toList();
        final avgHumidity = humidities.isNotEmpty
            ? (humidities.reduce((a, b) => a + b) / humidities.length).round()
            : 0;

        processedForecast.add({
          'date': date,
          'max_temperature': maxTemp,
          'min_temperature': minTemp,
          'avg_temperature': ((maxTemp + minTemp) / 2).round(),
          'condition': mostFrequentCondition,
          'icon': getWeatherIcon(hourlyData[0]['icon']),
          'humidity': avgHumidity,
          'chance_of_rain': maxRainChance,
          'hourly_forecast': hourlyData.take(8).toList(),
        });
      }
    });

    processedForecast.sort(
        (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
    final forecast = processedForecast.take(5).toList();

    print('✅ Previsão processada: ${forecast.length} dias');

    if (forecast.isEmpty) {
      return {
        'success': false,
        'message': 'Não foi possível processar os dados de previsão'
      };
    }

    return {
      'success': true,
      'location': {
        'name': city['name'],
        'country': city['country'],
        'lat': city['coord']['lat'],
        'lon': city['coord']['lon'],
      },
      'forecast': forecast,
      'days_count': forecast.length,
      'source': 'openweathermap',
    };
  }

  // ✅ MÉTODO: Método auxiliar para condição mais frequente
  static String _getMostFrequentCondition(List<dynamic> conditions) {
    final frequency = <String, int>{};
    for (final condition in conditions) {
      frequency[condition] = (frequency[condition] ?? 0) + 1;
    }
    final mostFrequent =
        frequency.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    // Traduzir para português
    switch (mostFrequent.toLowerCase()) {
      case 'clear':
        return 'Céu limpo';
      case 'clouds':
        return 'Nublado';
      case 'rain':
        return 'Chuva';
      case 'drizzle':
        return 'Chuvisco';
      case 'thunderstorm':
        return 'Tempestade';
      case 'snow':
        return 'Neve';
      case 'mist':
        return 'Nevoeiro';
      case 'fog':
        return 'Nevoeiro';
      default:
        return 'Condições variáveis';
    }
  }

  // 🔄 MÉTODOS EXISTENTES (CORRIGIDOS)
  static Future<void> rastrearLocalizacao() async {
    print('🔍 INICIANDO RASTREAMENTO DE LOCALIZAÇÃO');
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      print(
          '📍 Coordenadas obtidas: ${position.latitude}, ${position.longitude}');
      String? bairroEspecial =
          _estaEmBairroEspecial(position.latitude, position.longitude);
      print('🎯 Bairro especial detectado: $bairroEspecial');
      String resultado = await getPreciseNeighborhoodName(
          position.latitude, position.longitude);
      print('🎯 Resultado do getPreciseNeighborhoodName: $resultado');
    } catch (e) {
      print('❌ Erro no rastreamento: $e');
    }
  }

  static Future<String> getPreciseNeighborhoodName(
      double lat, double lon) async {
    print('🎯 EXECUTANDO getPreciseNeighborhoodName');
    final bairroEspecial = _estaEmBairroEspecial(lat, lon);
    if (bairroEspecial != null) {
      print('🎯 FORÇANDO BAIRRO ESPECIAL: $bairroEspecial');
      return bairroEspecial;
    }

    try {
      final response = await http.get(Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&addressdetails=1&zoom=18&accept-language=pt-BR'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'];
        print('📍 OpenStreetMap Debug:');
        print(' Endereço completo: $address');
        final neighborhood = address['neighbourhood'] ??
            address['suburb'] ??
            address['quarter'] ??
            address['residential'] ??
            address['city_district'] ??
            address['town'] ??
            address['village'];
        final city = address['city'] ??
            address['town'] ??
            address['municipality'] ??
            address['county'];
        final state = address['state'];
        final country = address['country'];
        print(' Bairro: $neighborhood');
        print(' Cidade: $city');
        print(' Estado: $state');

        String locationName;
        if (neighborhood != null && city != null) {
          final normalizedNeighborhood = _normalizeText(neighborhood);
          final normalizedCity = _normalizeText(city);
          if (normalizedNeighborhood == normalizedCity) {
            locationName = "$city, ${_getStateAbbreviation(state)}";
          } else {
            locationName = "$neighborhood, $city";
          }
        } else if (neighborhood != null) {
          locationName = "$neighborhood, ${_getStateAbbreviation(state)}";
        } else if (city != null) {
          locationName = "$city, ${_getStateAbbreviation(state)}";
        } else if (state != null) {
          locationName = "${_getStateAbbreviation(state)}, $country";
        } else {
          locationName = _extractFromDisplayName(data['display_name']);
        }

        locationName = _removeAllDuplication(locationName);
        print('✅ Localização final: $locationName');
        return locationName;
      }
      return await _getFallbackLocationName(lat, lon);
    } catch (e) {
      print('❌ Erro no geocoding: $e');
      return await _getFallbackLocationName(lat, lon);
    }
  }

  static String? _estaEmBairroEspecial(double lat, double lon) {
    print('🎯 EXECUTANDO _estaEmBairroEspecial');
    final distanciaLiberdade =
        Geolocator.distanceBetween(lat, lon, _liberdadeLat, _liberdadeLong);
    print(
        '📍 Distância até Liberdade: ${distanciaLiberdade.toStringAsFixed(0)}m');
    if (distanciaLiberdade <= _raioLiberdade) {
      print('🎌 DETECTADO: Liberdade');
      return "Liberdade, São Paulo";
    }

    final distanciaGranjaJulieta = Geolocator.distanceBetween(
        lat, lon, _granjaJulietaLat, _granjaJulietaLong);
    print(
        '📍 Distância até Granja Julieta: ${distanciaGranjaJulieta.toStringAsFixed(0)}m');
    // 🎯 CORREÇÃO: "GranJa Julieta" para "Granja Julieta"
    if (distanciaGranjaJulieta <= _raioGranjaJulieta) {
      print('🏡 DETECTADO: Granja Julieta');
      return "GranJa Julieta, São Paulo";
    }

    print('❌ Nenhum bairro especial detectado');
    return null;
  }

  static Future<Map<String, dynamic>> getPreciseLocationWeather() async {
    print('🎯 EXECUTANDO getPreciseLocationWeather');
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return {
          'success': false,
          'message': 'Ative o GPS para usar a localização automática'
        };
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return {
            'success': false,
            'message': 'Permissão de localização necessária'
          };
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return {
          'success': false,
          'message': 'Permissão permanentemente negada. Ative nas configurações'
        };
      }

      print('📍 Obtendo localização...');
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );
      print(
          '📍 Localização obtida: ${position.latitude}, ${position.longitude}');

      return await getCurrentWeatherByCoords(
          position.latitude, position.longitude);
    } catch (e) {
      print('❌ Erro na geolocalização: $e');
      return {
        'success': false,
        'message': 'Não foi possível obter a localização'
      };
    }
  }

  static Future<Map<String, dynamic>> getCurrentWeatherByCoords(
      double lat, double lon) async {
    print('🎯 EXECUTANDO getCurrentWeatherByCoords');
    try {
      print('📍 Buscando clima para coordenadas: $lat, $lon');
      final preciseLocationName = await getPreciseNeighborhoodName(lat, lon);
      final response = await http.get(Uri.parse(
          '$_openWeatherBaseUrl/weather?lat=$lat&lon=$lon&appid=$_openWeatherApiKey&units=metric&lang=pt_br'));

      if (response.statusCode == 200) {
        final weatherData = _parseWeatherData(json.decode(response.body));
        weatherData['city'] = preciseLocationName;
        weatherData['neighborhood'] = preciseLocationName;
        weatherData['is_precise_location'] = true;
        print('✅ Clima obtido para: $preciseLocationName');
        return weatherData;
      } else {
        print('❌ Erro na API do clima: ${response.statusCode}');
        return {'success': false, 'message': 'Erro ao buscar clima local'};
      }
    } catch (e) {
      print('❌ Erro geral no getCurrentWeatherByCoords: $e');
      return {'success': false, 'message': 'Erro de conexão'};
    }
  }

  static Future<Map<String, dynamic>> getCurrentWeather(String cityName) async {
    try {
      final response = await http.get(Uri.parse(
          '$_openWeatherBaseUrl/weather?q=$cityName&appid=$_openWeatherApiKey&units=metric&lang=pt_br'));

      if (response.statusCode == 200) {
        return _parseWeatherData(json.decode(response.body));
      } else if (response.statusCode == 404) {
        return {'success': false, 'message': 'Cidade não encontrada'};
      } else {
        return {'success': false, 'message': 'Erro ao buscar dados do clima'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  // ✅ ADICIONE ESTE MÉTODO AUXILIAR NO FINAL DO WEATHERSERVICE (antes do último })
  // Método auxiliar para conversão segura de double para int
  static int _safeToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  // ✅ CORREÇÃO: Usar conversão segura no _parseWeatherData
  static Map<String, dynamic> _parseWeatherData(Map<String, dynamic> data) {
    final weather = data['weather'][0];
    final main = data['main'];
    final wind = data['wind'];
    final sys = data['sys'];

    // ✅ CORREÇÃO: Usar conversão segura
    return {
      'success': true,
      'city': data['name'] ?? 'Cidade desconhecida',
      'neighborhood': data['name'] ?? 'Localização desconhecida',
      'country': sys['country'] ?? '',
      'temperature': _safeToInt(main['temp']),
      'feels_like': _safeToInt(main['feels_like']),
      'humidity': _safeToInt(main['humidity']),
      'pressure': _safeToInt(main['pressure']),
      'wind_speed': wind['speed'] ?? 0,
      'description': weather['description'] ?? 'Descrição indisponível',
      'main': weather['main'] ?? 'Indisponível',
      'icon': weather['icon'] ?? '01d',
      'visibility': data['visibility'] != null
          ? _safeToInt(data['visibility']) ~/ 1000
          : 0,
      'sunrise':
          DateTime.fromMillisecondsSinceEpoch((sys['sunrise'] as int) * 1000),
      'sunset':
          DateTime.fromMillisecondsSinceEpoch((sys['sunset'] as int) * 1000),
      'coordinates': {
        'lat': data['coord']['lat'] ?? 0.0,
        'lon': data['coord']['lon'] ?? 0.0,
      },
    };
  }

  // ✅ CORREÇÃO: Usar conversão segura no _parseForecastData
  static Map<String, dynamic> _parseForecastData(Map<String, dynamic> data) {
    final List<dynamic> forecastList = data['list'];
    final List<Map<String, dynamic>> forecast = [];

    for (int i = 0; i < forecastList.length; i += 8) {
      if (i < forecastList.length) {
        final item = forecastList[i];
        final weather = item['weather'][0];
        final main = item['main'];
        forecast.add({
          'date':
              DateTime.fromMillisecondsSinceEpoch((item['dt'] as int) * 1000),
          'temperature': _safeToInt(main['temp']),
          'description': weather['description'] ?? 'Descrição indisponível',
          'main': weather['main'] ?? 'Indisponível',
          'icon': weather['icon'] ?? '01d',
          'humidity': _safeToInt(main['humidity']),
        });
      }
    }

    return {
      'success': true,
      'city': data['city']['name'] ?? 'Cidade desconhecida',
      'country': data['city']['country'] ?? '',
      'forecast': forecast.take(5).toList(),
    };
  }

  static String getWeatherIcon(String iconCode) {
    switch (iconCode) {
      case '01d':
        return '☀️';
      case '01n':
        return '🌙';
      case '02d':
        return '⛅';
      case '02n':
        return '☁️';
      case '03d':
      case '03n':
        return '☁️';
      case '04d':
      case '04n':
        return '☁️';
      case '09d':
      case '09n':
        return '🌧️';
      case '10d':
      case '10n':
        return '🌦️';
      case '11d':
      case '11n':
        return '⛈️';
      case '13d':
      case '13n':
        return '❄️';
      case '50d':
      case '50n':
        return '🌫️';
      default:
        return '🌈';
    }
  }

  static String mapToOurWeatherSystem(String openWeatherMain) {
    switch (openWeatherMain.toLowerCase()) {
      case 'clear':
        return 'Ensolarado';
      case 'clouds':
        return 'Nublado';
      case 'rain':
      case 'drizzle':
        return 'Chuvoso';
      case 'thunderstorm':
        return 'Tempestade';
      case 'snow':
        return 'Frio Intenso';
      case 'mist':
      case 'fog':
      case 'haze':
        return 'Nevoeiro';
      case 'smoke':
      case 'dust':
      case 'sand':
        return 'Úmido';
      case 'ash':
      case 'squall':
      case 'tornado':
        return 'Ventania';
      default:
        return 'Ensolarado';
    }
  }

  // ✅ ADICIONE ESTE MÉTODO NO FINAL DA CLASSE (antes do último })
  static Future<void> testForecastApi() async {
    print('🧪 TESTANDO API DE PREVISÃO');
    try {
      final testUrl =
          'https://api.openweathermap.org/data/2.5/forecast?q=São Paulo&appid=ecff47e3507241b6cc533b182d81a1c5&units=metric&lang=pt_br';
      final response = await http.get(Uri.parse(testUrl));
      print('🧪 Test Status: ${response.statusCode}');
      print('🧪 Test Body: ${response.body.substring(0, 200)}...');
      if (response.statusCode == 200) {
        print('✅ API está funcionando!');
      } else {
        print('❌ API retornou erro: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erro no teste: $e');
    }
  }

  // 🔧 MÉTODOS AUXILIARES (CORRIGIDOS)
  static String _normalizeText(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[àáâãäå]'), 'a')
        .replaceAll(RegExp(r'[èéêë]'), 'e')
        .replaceAll(RegExp(r'[ìíîï]'), 'i')
        .replaceAll(RegExp(r'[òóôõö]'), 'o')
        .replaceAll(RegExp(r'[ùúûü]'), 'u')
        .replaceAll(RegExp(r'[ç]'), 'c')
        .replaceAll(RegExp(r'[ñ]'), 'n')
        .replaceAll(RegExp(r'[^a-z0-9]'), '')
        .trim();
  }

  static String _getStateAbbreviation(String? state) {
    if (state == null) return '';
    final stateMap = {
      'são paulo': 'SP',
      'sao paulo': 'SP',
      'rio de janeiro': 'RJ',
      'minas gerais': 'MG',
      'espírito santo': 'ES',
      'espirito santo': 'ES',
      'paraná': 'PR',
      'parana': 'PR',
      'santa catarina': 'SC',
      'rio grande do sul': 'RS',
      'bahia': 'BA',
      'pernambuco': 'PE',
      'ceará': 'CE',
      'ceara': 'CE',
      'pará': 'PA',
      'para': 'PA',
      'maranhão': 'MA',
      'maranhao': 'MA',
      'goiás': 'GO',
      'goias': 'GO',
      'amazonas': 'AM',
      'distrito federal': 'DF',
    };
    final normalizedState = _normalizeText(state);
    return stateMap[normalizedState] ?? state;
  }

  static String _removeAllDuplication(String locationName) {
    final parts = locationName.split(',').map((e) => e.trim()).toList();
    if (parts.length < 2) return locationName;
    final normalizedParts = parts.map(_normalizeText).toList();
    final uniqueParts = <String>[];
    for (int i = 0; i < parts.length; i++) {
      bool isDuplicate = false;
      for (int j = 0; j < uniqueParts.length; j++) {
        if (normalizedParts[i] == _normalizeText(uniqueParts[j])) {
          isDuplicate = true;
          break;
        }
      }
      if (!isDuplicate) {
        uniqueParts.add(parts[i]);
      }
    }
    return uniqueParts.join(', ');
  }

  static String _extractFromDisplayName(dynamic displayName) {
    if (displayName == null) return 'Localização Atual';
    final displayStr = displayName.toString();
    final parts = displayStr.split(',').map((e) => e.trim()).toList();
    final validParts = parts
        .where((p) =>
            p.length > 2 &&
            !RegExp(r'^\d{5}').hasMatch(p) &&
            p.toUpperCase() != p)
        .take(2)
        .toList();
    if (validParts.length >= 2) {
      return validParts.join(', ');
    } else if (validParts.isNotEmpty) {
      return validParts[0];
    }
    return 'Localização Atual';
  }

  static Future<String> _getFallbackLocationName(double lat, double lon) async {
    try {
      print('🔄 Usando fallback com OpenWeatherMap...');
      final response = await http.get(Uri.parse(
          '$_openWeatherGeoUrl/reverse?lat=$lat&lon=$lon&limit=1&appid=$_openWeatherApiKey'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List && data.isNotEmpty) {
          final location = data[0];
          final name = location['name'];
          final state = location['state'];
          if (name != null && state != null) {
            return "$name, ${_getStateAbbreviation(state)}";
          } else if (name != null) {
            return name;
          }
        }
      }
    } catch (e) {
      print('❌ Fallback falhou: $e');
    }
    return 'Localização Atual';
  }

  static Future<List<Map<String, dynamic>>> getCitySuggestions(
      String query) async {
    try {
      if (query.length < 3) return [];
      final response = await http.get(Uri.parse(
          '$_openWeatherGeoUrl/direct?q=$query&limit=5&appid=$_openWeatherApiKey'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        return data.map((city) {
          return {
            'name': city['name'] ?? '',
            'state': city['state'] ?? '',
            'country': city['country'] ?? '',
            'lat': city['lat'] ?? 0.0,
            'lon': city['lon'] ?? 0.0,
            'display_name':
                '${city['name'] ?? ''}${city['state'] != null ? ', ${city['state']}' : ''}',
          };
        }).toList();
      }
      return [];
    } catch (e) {
      print('❌ Erro ao buscar sugestões: $e');
      return [];
    }
  }
}
