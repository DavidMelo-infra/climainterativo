// ARQUIVO: lib/services/local_storage_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  // ✅ MÉTODO MELHORADO: Obter instância do SharedPreferences
  static Future<SharedPreferences> getPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      print('✅ SharedPreferences inicializado com sucesso');
      return prefs;
    } catch (e) {
      print('❌ ERRO ao inicializar SharedPreferences: $e');
      throw Exception('Falha ao inicializar armazenamento local: $e');
    }
  }

  // ✅ MÉTODO MELHORADO: Salvar credenciais do usuário
  static Future<void> saveUserCredentials(String email, String password) async {
    try {
      final prefs = await getPrefs();
      await prefs.setString('user_email', email);
      await prefs.setString('user_password', password);
      await prefs.setBool('is_logged_in', true);
      await prefs.setString('last_login', DateTime.now().toIso8601String());

      print('✅ Credenciais salvas localmente para: ${_maskEmail(email)}');
      print('📱 Status de login: ATIVO');
    } catch (e) {
      print('❌ ERRO ao salvar credenciais: $e');
      throw Exception('Falha ao salvar credenciais: $e');
    }
  }

  // ✅ MÉTODO MELHORADO: Recuperar credenciais salvas
  static Future<Map<String, String>> getSavedCredentials() async {
    try {
      final prefs = await getPrefs();
      final email = prefs.getString('user_email') ?? '';
      final password = prefs.getString('user_password') ?? '';
      final lastLogin = prefs.getString('last_login') ?? '';

      if (email.isNotEmpty && password.isNotEmpty) {
        print('✅ Credenciais recuperadas do armazenamento local');
        print('📧 Email: ${_maskEmail(email)}');
        print('🕒 Último login: ${lastLogin.isNotEmpty ? lastLogin : "N/A"}');

        return {'email': email, 'password': password, 'last_login': lastLogin};
      }

      print('⚠️ Credenciais não encontradas ou vazias');
      return {'email': '', 'password': '', 'last_login': ''};
    } catch (e) {
      print('❌ ERRO ao recuperar credenciais: $e');
      return {'email': '', 'password': '', 'last_login': ''};
    }
  }

  // ✅ MÉTODO MELHORADO: Verificar se usuário está logado
  static Future<bool> isUserLoggedIn() async {
    try {
      final prefs = await getPrefs();
      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      final lastLogin = prefs.getString('last_login') ?? '';

      print('🔍 Status de login verificado: $isLoggedIn');
      if (lastLogin.isNotEmpty) {
        print('🕒 Último login: $lastLogin');
      }

      return isLoggedIn;
    } catch (e) {
      print('❌ ERRO ao verificar login: $e');
      return false;
    }
  }

  // ✅ MÉTODO MELHORADO: Limpar credenciais do usuário
  static Future<void> clearUserCredentials() async {
    try {
      final prefs = await getPrefs();
      final email = prefs.getString('user_email') ?? '';

      await prefs.remove('user_email');
      await prefs.remove('user_password');
      await prefs.remove('user_data');
      await prefs.setBool('is_logged_in', false);
      await prefs.remove('last_login');

      print('✅ Credenciais locais removidas com sucesso');
      if (email.isNotEmpty) {
        print('🗑️ Dados removidos para: ${_maskEmail(email)}');
      }
    } catch (e) {
      print('❌ ERRO ao limpar credenciais: $e');
      throw Exception('Falha ao limpar credenciais: $e');
    }
  }

  // ✅ NOVO MÉTODO: Salvar dados completos do usuário
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await getPrefs();
      final userJson = jsonEncode(userData);
      await prefs.setString('user_data', userJson);

      print('✅ Dados completos do usuário salvos localmente');
      print('👤 Usuário: ${userData['name'] ?? "N/A"}');
      print('📧 Email: ${_maskEmail(userData['email'] ?? "")}');
    } catch (e) {
      print('❌ ERRO ao salvar dados do usuário: $e');
      throw Exception('Falha ao salvar dados do usuário: $e');
    }
  }

  // ✅ NOVO MÉTODO: Recuperar dados completos do usuário
  static Future<Map<String, dynamic>> getUserData() async {
    try {
      final prefs = await getPrefs();
      final userJson = prefs.getString('user_data') ?? '';

      if (userJson.isNotEmpty) {
        final userData = jsonDecode(userJson);
        print('✅ Dados do usuário recuperados do cache local');
        print('👤 Usuário: ${userData['name'] ?? "N/A"}');
        return userData;
      }

      print('⚠️ Nenhum dado de usuário encontrado no cache');
      return {};
    } catch (e) {
      print('❌ ERRO ao recuperar dados do usuário: $e');
      return {};
    }
  }

  // ✅ NOVO MÉTODO: Salvar localização do usuário
  static Future<void> saveUserLocation(String locationName,
      {double? lat, double? lon}) async {
    try {
      final prefs = await getPrefs();
      await prefs.setString('last_location_name', locationName);

      if (lat != null && lon != null) {
        await prefs.setDouble('last_location_lat', lat);
        await prefs.setDouble('last_location_lon', lon);
      }

      await prefs.setString(
          'last_location_update', DateTime.now().toIso8601String());

      print('📍 Localização salva: $locationName');
      if (lat != null && lon != null) {
        print('🗺️ Coordenadas: $lat, $lon');
      }
    } catch (e) {
      print('❌ ERRO ao salvar localização: $e');
    }
  }

  // ✅ NOVO MÉTODO: Recuperar localização salva
  static Future<Map<String, dynamic>> getUserLocation() async {
    try {
      final prefs = await getPrefs();
      final locationName = prefs.getString('last_location_name') ?? '';
      final lat = prefs.getDouble('last_location_lat');
      final lon = prefs.getDouble('last_location_lon');
      final lastUpdate = prefs.getString('last_location_update') ?? '';

      if (locationName.isNotEmpty) {
        print('📍 Localização recuperada: $locationName');
        if (lat != null && lon != null) {
          print('🗺️ Coordenadas: $lat, $lon');
        }
        if (lastUpdate.isNotEmpty) {
          print('🕒 Última atualização: $lastUpdate');
        }
      }

      return {
        'location_name': locationName,
        'latitude': lat,
        'longitude': lon,
        'last_update': lastUpdate
      };
    } catch (e) {
      print('❌ ERRO ao recuperar localização: $e');
      return {
        'location_name': '',
        'latitude': null,
        'longitude': null,
        'last_update': ''
      };
    }
  }

  // ✅ NOVO MÉTODO: Salvar configurações do app
  static Future<void> saveAppSettings(Map<String, dynamic> settings) async {
    try {
      final prefs = await getPrefs();
      final settingsJson = jsonEncode(settings);
      await prefs.setString('app_settings', settingsJson);

      print('✅ Configurações do app salvas');
      print('⚙️ Configurações: ${settings.keys.join(', ')}');
    } catch (e) {
      print('❌ ERRO ao salvar configurações: $e');
    }
  }

  // ✅ NOVO MÉTODO: Recuperar configurações do app
  static Future<Map<String, dynamic>> getAppSettings() async {
    try {
      final prefs = await getPrefs();
      final settingsJson = prefs.getString('app_settings') ?? '';

      if (settingsJson.isNotEmpty) {
        final settings = jsonDecode(settingsJson);
        print('✅ Configurações do app recuperadas');
        return settings;
      }

      print('⚠️ Nenhuma configuração encontrada, usando padrões');
      return {
        'notifications': true,
        'dark_mode': false,
        'auto_location': true,
        'temperature_unit': 'celsius'
      };
    } catch (e) {
      print('❌ ERRO ao recuperar configurações: $e');
      return {
        'notifications': true,
        'dark_mode': false,
        'auto_location': true,
        'temperature_unit': 'celsius'
      };
    }
  }

  // ✅ NOVO MÉTODO: Salvar dados do ranking
  static Future<void> saveRankingData(Map<String, dynamic> rankingData) async {
    try {
      final prefs = await getPrefs();
      final rankingJson = jsonEncode(rankingData);
      await prefs.setString('ranking_data', rankingJson);
      await prefs.setString(
          'ranking_last_update', DateTime.now().toIso8601String());

      print('✅ Dados do ranking salvos localmente');
    } catch (e) {
      print('❌ ERRO ao salvar dados do ranking: $e');
    }
  }

  // ✅ NOVO MÉTODO: Recuperar dados do ranking
  static Future<Map<String, dynamic>> getRankingData() async {
    try {
      final prefs = await getPrefs();
      final rankingJson = prefs.getString('ranking_data') ?? '';
      final lastUpdate = prefs.getString('ranking_last_update') ?? '';

      if (rankingJson.isNotEmpty) {
        final rankingData = jsonDecode(rankingJson);
        print('✅ Dados do ranking recuperados do cache');
        if (lastUpdate.isNotEmpty) {
          print('🕒 Última atualização do ranking: $lastUpdate');
        }
        return rankingData;
      }

      print('⚠️ Nenhum dado de ranking encontrado no cache');
      return {};
    } catch (e) {
      print('❌ ERRO ao recuperar dados do ranking: $e');
      return {};
    }
  }

  // ✅ NOVO MÉTODO: Salvar configurações de notificações climáticas
  static Future<void> saveNotificationSettings(
      Map<String, dynamic> settings) async {
    try {
      final prefs = await getPrefs();
      final settingsJson = jsonEncode(settings);
      await prefs.setString('weather_notification_settings', settingsJson);
      await prefs.setString(
          'notification_settings_updated', DateTime.now().toIso8601String());

      print('✅ Configurações de notificações climáticas salvas');
      print('🔔 Notificações ativas: ${settings['enabled'] ?? false}');
      print(
          '⏰ Horário: ${settings['notificationTime']?['hour'] ?? 8}:${settings['notificationTime']?['minute'] ?? 0}');
    } catch (e) {
      print('❌ ERRO ao salvar configurações de notificações: $e');
      throw Exception('Falha ao salvar configurações de notificações: $e');
    }
  }

  // ✅ NOVO MÉTODO: Recuperar configurações de notificações climáticas
  static Future<Map<String, dynamic>> getNotificationSettings() async {
    try {
      final prefs = await getPrefs();
      final settingsJson =
          prefs.getString('weather_notification_settings') ?? '';
      final lastUpdate = prefs.getString('notification_settings_updated') ?? '';

      if (settingsJson.isNotEmpty) {
        final settings = jsonDecode(settingsJson);
        print('✅ Configurações de notificações recuperadas do cache');
        if (lastUpdate.isNotEmpty) {
          print('🕒 Última atualização: $lastUpdate');
        }
        return settings;
      }

      print(
          '⚠️ Nenhuma configuração de notificação encontrada, usando padrões');
      // Configurações padrão
      return {
        'enabled': false,
        'notificationTime': {'hour': 8, 'minute': 0},
        'monitoredCities': [],
        'alertRain': true,
        'alertExtremeTemp': true,
        'alertWind': false,
        'minTempThreshold': 5,
        'maxTempThreshold': 35,
        'windSpeedThreshold': 15,
      };
    } catch (e) {
      print('❌ ERRO ao recuperar configurações de notificações: $e');
      return {
        'enabled': false,
        'notificationTime': {'hour': 8, 'minute': 0},
        'monitoredCities': [],
        'alertRain': true,
        'alertExtremeTemp': true,
        'alertWind': false,
        'minTempThreshold': 5,
        'maxTempThreshold': 35,
        'windSpeedThreshold': 15,
      };
    }
  }

  // ✅ NOVO MÉTODO: Salvar histórico de notificações enviadas
  static Future<void> saveNotificationHistory(
      List<Map<String, dynamic>> history) async {
    try {
      final prefs = await getPrefs();
      final historyJson = jsonEncode(history);
      await prefs.setString('notification_history', historyJson);
      await prefs.setString(
          'notification_history_updated', DateTime.now().toIso8601String());

      print('✅ Histórico de notificações salvo');
      print('📋 Total de notificações no histórico: ${history.length}');
    } catch (e) {
      print('❌ ERRO ao salvar histórico de notificações: $e');
    }
  }

  // ✅ NOVO MÉTODO: Recuperar histórico de notificações
  static Future<List<Map<String, dynamic>>> getNotificationHistory() async {
    try {
      final prefs = await getPrefs();
      final historyJson = prefs.getString('notification_history') ?? '';
      final lastUpdate = prefs.getString('notification_history_updated') ?? '';

      if (historyJson.isNotEmpty) {
        final history =
            List<Map<String, dynamic>>.from(jsonDecode(historyJson));
        print('✅ Histórico de notificações recuperado');
        if (lastUpdate.isNotEmpty) {
          print('🕒 Última atualização do histórico: $lastUpdate');
        }
        return history;
      }

      print('⚠️ Nenhum histórico de notificações encontrado');
      return [];
    } catch (e) {
      print('❌ ERRO ao recuperar histórico de notificações: $e');
      return [];
    }
  }

  // ✅ NOVO MÉTODO: Adicionar entrada ao histórico de notificações
  static Future<void> addToNotificationHistory(
      Map<String, dynamic> notification) async {
    try {
      final currentHistory = await getNotificationHistory();

      // Limitar histórico aos últimos 50 itens
      final newHistory = [
        {
          ...notification,
          'timestamp': DateTime.now().toIso8601String(),
          'id': DateTime.now().millisecondsSinceEpoch,
        },
        ...currentHistory,
      ].take(50).toList();

      await saveNotificationHistory(newHistory);
      print('✅ Notificação adicionada ao histórico: ${notification['title']}');
    } catch (e) {
      print('❌ ERRO ao adicionar ao histórico: $e');
    }
  }

  // ✅ NOVO MÉTODO: Salvar cidades monitoradas para notificações
  static Future<void> saveMonitoredCities(List<String> cities) async {
    try {
      final prefs = await getPrefs();
      final citiesJson = jsonEncode(cities);
      await prefs.setString('monitored_cities', citiesJson);
      await prefs.setString(
          'monitored_cities_updated', DateTime.now().toIso8601String());

      print('✅ Cidades monitoradas salvas');
      print('🏙️ Cidades: ${cities.join(', ')}');
    } catch (e) {
      print('❌ ERRO ao salvar cidades monitoradas: $e');
    }
  }

  // ✅ NOVO MÉTODO: Recuperar cidades monitoradas
  static Future<List<String>> getMonitoredCities() async {
    try {
      final prefs = await getPrefs();
      final citiesJson = prefs.getString('monitored_cities') ?? '';
      final lastUpdate = prefs.getString('monitored_cities_updated') ?? '';

      if (citiesJson.isNotEmpty) {
        final cities = List<String>.from(jsonDecode(citiesJson));
        print('✅ Cidades monitoradas recuperadas: ${cities.length} cidades');
        if (lastUpdate.isNotEmpty) {
          print('🕒 Última atualização: $lastUpdate');
        }
        return cities;
      }

      print('⚠️ Nenhuma cidade monitorada encontrada');
      return [];
    } catch (e) {
      print('❌ ERRO ao recuperar cidades monitoradas: $e');
      return [];
    }
  }

  // ✅ NOVO MÉTODO: Salvar estatísticas de uso de notificações
  static Future<void> saveNotificationStats(Map<String, dynamic> stats) async {
    try {
      final prefs = await getPrefs();
      final statsJson = jsonEncode(stats);
      await prefs.setString('notification_stats', statsJson);
      await prefs.setString(
          'notification_stats_updated', DateTime.now().toIso8601String());

      print('✅ Estatísticas de notificações salvas');
    } catch (e) {
      print('❌ ERRO ao salvar estatísticas: $e');
    }
  }

  // ✅ NOVO MÉTODO: Recuperar estatísticas de uso de notificações
  static Future<Map<String, dynamic>> getNotificationStats() async {
    try {
      final prefs = await getPrefs();
      final statsJson = prefs.getString('notification_stats') ?? '';
      final lastUpdate = prefs.getString('notification_stats_updated') ?? '';

      if (statsJson.isNotEmpty) {
        final stats = jsonDecode(statsJson);
        print('✅ Estatísticas de notificações recuperadas');
        return stats;
      }

      print('⚠️ Nenhuma estatística de notificação encontrada');
      return {
        'total_sent': 0,
        'alerts_sent': 0,
        'daily_notifications_sent': 0,
        'last_notification_sent': null,
        'user_preferences_updated': null,
      };
    } catch (e) {
      print('❌ ERRO ao recuperar estatísticas: $e');
      return {
        'total_sent': 0,
        'alerts_sent': 0,
        'daily_notifications_sent': 0,
        'last_notification_sent': null,
        'user_preferences_updated': null,
      };
    }
  }

  // ✅ NOVO MÉTODO: Atualizar estatísticas de notificações
  static Future<void> updateNotificationStats({String? type}) async {
    try {
      final currentStats = await getNotificationStats();

      final updatedStats = {
        'total_sent': (currentStats['total_sent'] ?? 0) + 1,
        'alerts_sent': type == 'alert'
            ? (currentStats['alerts_sent'] ?? 0) + 1
            : (currentStats['alerts_sent'] ?? 0),
        'daily_notifications_sent': type == 'daily'
            ? (currentStats['daily_notifications_sent'] ?? 0) + 1
            : (currentStats['daily_notifications_sent'] ?? 0),
        'last_notification_sent': DateTime.now().toIso8601String(),
        'user_preferences_updated': currentStats['user_preferences_updated'],
      };

      await saveNotificationStats(updatedStats);
      print(
          '📊 Estatísticas atualizadas - Total: ${updatedStats['total_sent']}');
    } catch (e) {
      print('❌ ERRO ao atualizar estatísticas: $e');
    }
  }

  // ✅ MÉTODO MELHORADO: Limpar TODOS os dados (logout completo)
  static Future<void> clearAllData() async {
    try {
      final prefs = await getPrefs();
      final email = prefs.getString('user_email') ?? '';

      // Limpa todos os dados do usuário
      await prefs.remove('user_email');
      await prefs.remove('user_password');
      await prefs.remove('user_data');
      await prefs.remove('is_logged_in');
      await prefs.remove('last_login');

      // Limpa dados da sessão atual
      await prefs.remove('last_location_name');
      await prefs.remove('last_location_lat');
      await prefs.remove('last_location_lon');
      await prefs.remove('last_location_update');

      // Limpa dados temporários
      await prefs.remove('ranking_data');
      await prefs.remove('ranking_last_update');
      await prefs.remove('app_settings');

      // Limpa dados de notificações (OPCIONAL - manter preferências do usuário)
      // await prefs.remove('weather_notification_settings');
      // await prefs.remove('notification_history');
      // await prefs.remove('monitored_cities');
      // await prefs.remove('notification_stats');

      print('✅ TODOS os dados locais foram limpos');
      if (email.isNotEmpty) {
        print('🗑️ Sessão finalizada para: ${_maskEmail(email)}');
      }
    } catch (e) {
      print('❌ ERRO ao limpar todos os dados: $e');
      throw Exception('Falha ao limpar dados: $e');
    }
  }

  // ✅ NOVO MÉTODO: Limpar apenas dados de notificações
  static Future<void> clearNotificationData() async {
    try {
      final prefs = await getPrefs();

      await prefs.remove('weather_notification_settings');
      await prefs.remove('notification_history');
      await prefs.remove('monitored_cities');
      await prefs.remove('notification_stats');
      await prefs.remove('notification_settings_updated');
      await prefs.remove('notification_history_updated');
      await prefs.remove('monitored_cities_updated');
      await prefs.remove('notification_stats_updated');

      print('✅ Todos os dados de notificações foram limpos');
    } catch (e) {
      print('❌ ERRO ao limpar dados de notificações: $e');
    }
  }

  // ✅ MÉTODO MELHORADO: Verificar saúde do armazenamento
  static Future<void> checkStorageHealth() async {
    try {
      final prefs = await getPrefs();
      final keys = prefs.getKeys();

      print('🔍 VERIFICAÇÃO DE ARMAZENAMENTO LOCAL:');
      print('📊 Total de chaves salvas: ${keys.length}');

      // Categorias para organização
      final categories = {
        'Autenticação': [
          'user_email',
          'user_password',
          'is_logged_in',
          'last_login'
        ],
        'Dados do Usuário': ['user_data'],
        'Localização': [
          'last_location_name',
          'last_location_lat',
          'last_location_lon',
          'last_location_update'
        ],
        'Configurações': ['app_settings'],
        'Ranking': ['ranking_data', 'ranking_last_update'],
        'Notificações': [
          'weather_notification_settings',
          'notification_history',
          'monitored_cities',
          'notification_stats'
        ],
      };

      for (final category in categories.entries) {
        final categoryKeys =
            category.value.where((key) => keys.contains(key)).toList();
        if (categoryKeys.isNotEmpty) {
          print('\n📁 ${category.key}:');
          for (final key in categoryKeys) {
            final value = prefs.get(key);
            if (key.contains('password') || key.contains('email')) {
              print('   🔐 $key: [DADO PROTEGIDO]');
            } else if (key == 'user_data' ||
                key == 'weather_notification_settings') {
              print('   📄 $key: [DADO COMPLEXO - VERIFICADO]');
            } else {
              print('   📁 $key: $value');
            }
          }
        }
      }

      // Chaves não categorizadas
      final uncategorized = keys
          .where((key) =>
              !categories.values.any((category) => category.contains(key)))
          .toList();
      if (uncategorized.isNotEmpty) {
        print('\n❓ Chaves não categorizadas:');
        for (final key in uncategorized) {
          print('   📁 $key: ${prefs.get(key)}');
        }
      }
    } catch (e) {
      print('❌ ERRO na verificação do armazenamento: $e');
    }
  }

  // ✅ MÉTODO AUXILIAR: Mascarar email para logs
  static String _maskEmail(String email) {
    if (email.isEmpty || !email.contains('@')) return '***';

    final parts = email.split('@');
    if (parts.length != 2) return '***';

    final username = parts[0];
    final domain = parts[1];

    if (username.length <= 2) {
      return '***@$domain';
    }

    final maskedUsername =
        username.substring(0, 2) + '*' * (username.length - 2);
    return '$maskedUsername@$domain';
  }

  // ✅ MÉTODO MELHORADO: Backup de dados importantes
  static Future<Map<String, dynamic>> createBackup() async {
    try {
      final prefs = await getPrefs();
      final backupData = <String, dynamic>{};

      // Coleta dados importantes para backup
      final credentials = await getSavedCredentials();
      final userData = await getUserData();
      final location = await getUserLocation();
      final settings = await getAppSettings();
      final notificationSettings = await getNotificationSettings();
      final monitoredCities = await getMonitoredCities();

      backupData['credentials'] = {
        'email': _maskEmail(credentials['email'] ?? ''),
        'has_password': credentials['password']?.isNotEmpty ?? false,
        'last_login': credentials['last_login']
      };

      backupData['user_data'] = userData.isNotEmpty
          ? {
              'name': userData['name'],
              'username': userData['username'],
              'user_type': userData['user_type']
            }
          : {};

      backupData['location'] = location;
      backupData['settings'] = settings;
      backupData['notification_settings'] = notificationSettings;
      backupData['monitored_cities'] = monitoredCities;
      backupData['backup_timestamp'] = DateTime.now().toIso8601String();

      print('✅ Backup criado com sucesso');
      print('📦 Dados no backup: ${backupData.keys.join(', ')}');

      return backupData;
    } catch (e) {
      print('❌ ERRO ao criar backup: $e');
      return {'error': 'Falha ao criar backup: $e'};
    }
  }

  // ✅ MÉTODO MELHORADO: Verificar se há dados salvos
  static Future<bool> hasSavedData() async {
    try {
      final prefs = await getPrefs();
      final hasCredentials =
          prefs.containsKey('user_email') && prefs.containsKey('user_password');
      final hasUserData = prefs.containsKey('user_data');
      final hasLocation = prefs.containsKey('last_location_name');
      final hasNotificationSettings =
          prefs.containsKey('weather_notification_settings');

      print('📊 Verificação de dados salvos:');
      print('   🔐 Credenciais: $hasCredentials');
      print('   👤 Dados usuário: $hasUserData');
      print('   📍 Localização: $hasLocation');
      print('   🔔 Configurações de notificação: $hasNotificationSettings');

      return hasCredentials ||
          hasUserData ||
          hasLocation ||
          hasNotificationSettings;
    } catch (e) {
      print('❌ ERRO ao verificar dados salvos: $e');
      return false;
    }
  }

  // ✅ MÉTODO MELHORADO: Obter estatísticas de armazenamento
  static Future<Map<String, dynamic>> getStorageStats() async {
    try {
      final prefs = await getPrefs();
      final keys = prefs.getKeys();

      final notificationSettings = await getNotificationSettings();
      final monitoredCities = await getMonitoredCities();
      final notificationHistory = await getNotificationHistory();

      final stats = {
        'total_keys': keys.length,
        'has_credentials': prefs.containsKey('user_email'),
        'has_user_data': prefs.containsKey('user_data'),
        'has_location': prefs.containsKey('last_location_name'),
        'has_settings': prefs.containsKey('app_settings'),
        'has_notification_settings':
            prefs.containsKey('weather_notification_settings'),
        'is_logged_in': prefs.getBool('is_logged_in') ?? false,
        'last_login': prefs.getString('last_login') ?? 'Nunca',
        'notifications_enabled': notificationSettings['enabled'] ?? false,
        'monitored_cities_count': monitoredCities.length,
        'notification_history_count': notificationHistory.length,
      };

      print('📈 ESTATÍSTICAS DE ARMAZENAMENTO:');
      for (final key in stats.keys) {
        print('   $key: ${stats[key]}');
      }

      return stats;
    } catch (e) {
      print('❌ ERRO ao obter estatísticas: $e');
      return {'error': 'Falha ao obter estatísticas: $e'};
    }
  }
}
