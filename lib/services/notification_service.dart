import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  bool _isInitialized = false;

  // ✅ CONTEXT GLOBAL PARA TIME OF DAY
  static BuildContext? _context;

  // ✅ SETAR CONTEXT (chamar no main.dart ou na primeira tela)
  static void setContext(BuildContext context) {
    _context = context;
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    // Initialize timezone
    tz.initializeTimeZones();

    // Configuração Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configuração iOS
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        print('🔔 Notificação clicada: ${response.payload}');
      },
    );

    // ✅ CONFIGURAR CANAIS DE NOTIFICAÇÃO
    await setupNotificationChannels();

    _isInitialized = true;
    print('✅ NotificationService inicializado');
  }

  // ✅ MÉTODO MELHORADO: Solicitar permissões
  Future<bool> requestPermissions() async {
    try {
      if (await Permission.notification.isGranted) {
        print('🔔 Permissão de notificação já concedida');
        return true;
      }

      print('📋 Solicitando permissão de notificação...');
      final status = await Permission.notification.request();

      if (status.isGranted) {
        print('✅ Permissão de notificação concedida');
        return true;
      } else {
        print('❌ Permissão de notificação negada: $status');
        return false;
      }
    } catch (e) {
      print('❌ Erro ao solicitar permissões: $e');
      return false;
    }
  }

  // ✅ MÉTODO MELHORADO: Agendar notificação diária do clima
  Future<void> scheduleDailyWeatherNotification({
    required String title,
    required String body,
    required TimeOfDay time,
    int id = 0,
  }) async {
    try {
      if (!_isInitialized) await initialize();

      final permissionGranted = await requestPermissions();
      if (!permissionGranted) {
        print('❌ Permissão de notificação negada - não foi possível agendar');
        return;
      }

      final now = tz.TZDateTime.now(tz.local);
      final scheduledTime = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );

      // Se o horário já passou hoje, agenda para amanhã
      final when = scheduledTime.isBefore(now)
          ? scheduledTime.add(const Duration(days: 1))
          : scheduledTime;

      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        when,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_weather_channel',
            'Previsão Diária do Tempo',
            channelDescription:
                'Notificações diárias sobre as condições climáticas',
            importance: Importance.high,
            priority: Priority.high,
            colorized: true,
            color: const Color(0xFF2196F3),
            styleInformation: BigTextStyleInformation(body),
            enableVibration: true,
            playSound: true,
          ),
          iOS: DarwinNotificationDetails(
            sound: 'default',
            badgeNumber: 1,
            subtitle: 'Previsão do tempo',
          ),
        ),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'weather_daily_$id',
      );

      // ✅ CORREÇÃO: Usar context de forma segura
      String timeString;
      if (_context != null) {
        timeString = time.format(_context!);
      } else {
        timeString =
            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      }

      print('✅ Notificação diária agendada para $timeString');
      print('   📝 Título: $title');
      print('   📅 Próxima execução: $when');
    } catch (e) {
      print('❌ Erro ao agendar notificação diária: $e');
    }
  }

  // ✅ MÉTODO MELHORADO: Notificação instantânea de alerta climático
  Future<void> showWeatherAlert({
    required String title,
    required String body,
    required String alertType, // 'rain', 'extreme_temp', 'wind', 'daily'
  }) async {
    try {
      if (!_isInitialized) await initialize();

      final permissionGranted = await requestPermissions();
      if (!permissionGranted) {
        print(
            '❌ Permissão de notificação negada - não foi possível enviar alerta');
        return;
      }

      // ✅ CONFIGURAÇÕES DETALHADAS POR TIPO DE ALERTA
      AndroidNotificationDetails androidDetails;
      DarwinNotificationDetails? iosDetails;

      switch (alertType) {
        case 'extreme_temp':
          androidDetails = AndroidNotificationDetails(
            'weather_alert_channel',
            'Alertas de Temperatura',
            channelDescription: 'Alertas de temperaturas extremas',
            importance: Importance.max,
            priority: Priority.high,
            color: const Color(0xFFFF5252),
            enableVibration: true,
            playSound: true,
            styleInformation: BigTextStyleInformation(body),
            timeoutAfter: 60000, // 1 minuto
          );
          iosDetails = DarwinNotificationDetails(
            sound: 'default',
            badgeNumber: 1,
            threadIdentifier: 'temperature_alerts',
            subtitle: 'Alerta de Temperatura',
          );
          break;

        case 'rain':
          androidDetails = AndroidNotificationDetails(
            'weather_alert_channel',
            'Alertas de Chuva',
            channelDescription: 'Alertas de condições chuvosas',
            importance: Importance.high,
            priority: Priority.high,
            color: const Color(0xFF2196F3),
            enableVibration: true,
            playSound: true,
            styleInformation: BigTextStyleInformation(body),
          );
          iosDetails = DarwinNotificationDetails(
            sound: 'default',
            badgeNumber: 1,
            threadIdentifier: 'rain_alerts',
            subtitle: 'Alerta de Chuva',
          );
          break;

        case 'wind':
          androidDetails = AndroidNotificationDetails(
            'weather_alert_channel',
            'Alertas de Vento',
            channelDescription: 'Alertas de ventos fortes',
            importance: Importance.high,
            priority: Priority.high,
            color: const Color(0xFF4CAF50),
            enableVibration: true,
            playSound: true,
            styleInformation: BigTextStyleInformation(body),
          );
          iosDetails = DarwinNotificationDetails(
            sound: 'default',
            badgeNumber: 1,
            threadIdentifier: 'wind_alerts',
            subtitle: 'Alerta de Vento',
          );
          break;

        case 'daily':
          androidDetails = AndroidNotificationDetails(
            'daily_weather_channel',
            'Previsão Diária',
            channelDescription: 'Previsões climáticas diárias',
            importance: Importance.high,
            priority: Priority.defaultPriority,
            color: const Color(0xFFFF9800),
            enableVibration: false,
            playSound: true,
            styleInformation: BigTextStyleInformation(body),
          );
          iosDetails = DarwinNotificationDetails(
            sound: 'default',
            badgeNumber: 1,
            threadIdentifier: 'daily_forecast',
            subtitle: 'Previsão Diária',
          );
          break;

        default:
          androidDetails = AndroidNotificationDetails(
            'weather_alert_channel',
            'Alertas Climáticos',
            channelDescription: 'Alertas de condições climáticas',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            color: const Color(0xFFFF9800),
            enableVibration: true,
            styleInformation: BigTextStyleInformation(body),
          );
          iosDetails = DarwinNotificationDetails(
            sound: 'default',
            badgeNumber: 1,
            threadIdentifier: 'weather_alerts',
          );
      }

      // ✅ GERAR ID ÚNICO PARA CADA NOTIFICAÇÃO
      final notificationId =
          DateTime.now().millisecondsSinceEpoch.remainder(1000000);

      await flutterLocalNotificationsPlugin.show(
        notificationId,
        title,
        body,
        NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        ),
        payload: 'weather_${alertType}_$notificationId',
      );

      print('🚨 Alerta climático enviado:');
      print('   📝 Título: $title');
      print('   🔔 Tipo: $alertType');
      print('   🆔 ID: $notificationId');
    } catch (e) {
      print('❌ Erro ao enviar alerta climático: $e');
      rethrow; // ✅ RELANÇAR ERRO PARA TRATAMENTO NO CALLER
    }
  }

  // ✅ NOVO MÉTODO: NOTIFICAÇÃO REAL DO SISTEMA (ESTILO WHATSAPP)
  Future<void> showSystemNotification({
    required String title,
    required String body,
    required String type,
    int id = 0,
  }) async {
    try {
      if (!_isInitialized) await initialize();

      final permissionGranted = await requestPermissions();
      if (!permissionGranted) {
        print(
            '❌ Permissão de notificação negada - não foi possível enviar notificação do sistema');
        return;
      }

      // ✅ CONFIGURAÇÕES PARA NOTIFICAÇÃO DO SISTEMA
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'weather_system_channel', // ✅ NOVO CANAL PARA SISTEMA
        'Alertas Climáticos do Sistema',
        channelDescription:
            'Notificações climáticas que aparecem na barra do sistema',
        importance: Importance.high,
        priority: Priority.high,
        ticker: 'Clima Interativo - Nova notificação',
        playSound: true,
        enableVibration: true,
        sound: RawResourceAndroidNotificationSound('notification'),
        colorized: true,
        color: Color(0xFF2196F3),
        styleInformation: BigTextStyleInformation(''),
        autoCancel: true,
        ongoing: false,
        visibility: NotificationVisibility.public,
        timeoutAfter: 30000, // 30 segundos
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        sound: 'default',
        badgeNumber: 1,
        threadIdentifier: 'weather_system_alerts',
        subtitle: 'Clima Interativo',
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      // ✅ MOSTRAR NOTIFICAÇÃO DO SISTEMA
      await flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        const NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        ),
        payload: 'system_weather_$type',
      );

      print('📱 NOTIFICAÇÃO REAL DO SISTEMA ENVIADA: $title');
      print('   📝 Mensagem: $body');
      print('   🔔 Tipo: $type');
      print('   🆔 ID: $id');
      print('   📲 Aparecerá na BARRA DO SISTEMA mesmo com app fechado');
    } catch (e) {
      print('❌ Erro ao enviar notificação do sistema: $e');
      rethrow;
    }
  }

  // ✅ NOVO MÉTODO: Notificação simples para demonstração
  Future<void> showDemoNotification({
    required String title,
    required String body,
    String type = 'demo',
  }) async {
    try {
      if (!_isInitialized) await initialize();

      final permissionGranted = await requestPermissions();
      if (!permissionGranted) {
        print(
            '❌ Permissão negada - não foi possível mostrar notificação de demo');
        return;
      }

      const androidDetails = AndroidNotificationDetails(
        'demo_channel',
        'Notificações de Demonstração',
        channelDescription: 'Notificações para teste e demonstração',
        importance: Importance.high,
        priority: Priority.high,
        color: Color(0xFF9C27B0),
        enableVibration: true,
        playSound: true,
        styleInformation: BigTextStyleInformation(''),
      );

      const iosDetails = DarwinNotificationDetails(
        sound: 'default',
        badgeNumber: 1,
        subtitle: 'Demonstração',
      );

      final notificationId =
          DateTime.now().millisecondsSinceEpoch.remainder(100000);

      await flutterLocalNotificationsPlugin.show(
        notificationId,
        title,
        body,
        const NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        ),
        payload:
            'demo_${type}_$notificationId', // ✅ CORREÇÃO: usar $type em vez de $type_
      );

      print('🎭 Notificação de demonstração enviada: $title');
    } catch (e) {
      print('❌ Erro na notificação de demonstração: $e');
    }
  }

  // ✅ MÉTODO MELHORADO: Cancelar notificações agendadas
  Future<void> cancelScheduledNotifications() async {
    try {
      final pending =
          await flutterLocalNotificationsPlugin.pendingNotificationRequests();
      print('📋 Notificações pendentes encontradas: ${pending.length}');

      await flutterLocalNotificationsPlugin.cancelAll();
      print('✅ Todas as notificações agendadas foram canceladas');
    } catch (e) {
      print('❌ Erro ao cancelar notificações: $e');
    }
  }

  // ✅ MÉTODO MELHORADO: Verificar se notificações estão agendadas
  Future<bool> hasScheduledNotifications() async {
    try {
      final pendingNotifications =
          await flutterLocalNotificationsPlugin.pendingNotificationRequests();
      final hasNotifications = pendingNotifications.isNotEmpty;

      print(
          '🔍 Verificação de notificações agendadas: $hasNotifications (${pendingNotifications.length} encontradas)');

      return hasNotifications;
    } catch (e) {
      print('❌ Erro ao verificar notificações agendadas: $e');
      return false;
    }
  }

  // ✅ NOVO MÉTODO: Obter notificações pendentes
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await flutterLocalNotificationsPlugin
          .pendingNotificationRequests();
    } catch (e) {
      print('❌ Erro ao obter notificações pendentes: $e');
      return [];
    }
  }

  // ✅ NOVO MÉTODO: Cancelar notificação específica
  Future<void> cancelNotification(int id) async {
    try {
      await flutterLocalNotificationsPlugin.cancel(id);
      print('✅ Notificação cancelada: ID $id');
    } catch (e) {
      print('❌ Erro ao cancelar notificação $id: $e');
    }
  }

  // ✅ MÉTODO ATUALIZADO: Configurar canais (Android) - COM CANAL DO SISTEMA
  Future<void> setupNotificationChannels() async {
    try {
      // ✅ CANAL PRINCIPAL PARA NOTIFICAÇÕES DO SISTEMA
      const AndroidNotificationChannel systemChannel =
          AndroidNotificationChannel(
        'weather_system_channel', // ✅ NOVO CANAL
        'Alertas Climáticos do Sistema',
        description: 'Notificações climáticas que aparecem na barra do sistema',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        sound: const RawResourceAndroidNotificationSound('notification'),
        showBadge: true,
        enableLights: true,
        ledColor: Color(0xFF2196F3),
      );

      // Canal para alertas climáticos
      const AndroidNotificationChannel alertChannel =
          AndroidNotificationChannel(
        'weather_alert_channel',
        'Alertas Climáticos',
        description: 'Alertas de condições climáticas extremas',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      // Canal para previsões diárias
      const AndroidNotificationChannel dailyChannel =
          AndroidNotificationChannel(
        'daily_weather_channel',
        'Previsão Diária',
        description: 'Notificações diárias do clima',
        importance: Importance.high,
        playSound: true,
        enableVibration: false,
      );

      // Canal para demonstrações
      const AndroidNotificationChannel demoChannel = AndroidNotificationChannel(
        'demo_channel',
        'Demonstrações',
        description: 'Notificações de teste e demonstração',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      // ✅ CRIAR TODOS OS CANAIS
      final androidPlugin =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(systemChannel);
        await androidPlugin.createNotificationChannel(alertChannel);
        await androidPlugin.createNotificationChannel(dailyChannel);
        await androidPlugin.createNotificationChannel(demoChannel);
      }

      print(
          '✅ Canais de notificação configurados (incluindo canal do sistema)');
    } catch (e) {
      print('❌ Erro ao configurar canais: $e');
    }
  }

  // ✅ NOVO MÉTODO: Verificar status das permissões
  Future<PermissionStatus> getNotificationPermissionStatus() async {
    try {
      return await Permission.notification.status;
    } catch (e) {
      print('❌ Erro ao verificar status da permissão: $e');
      return PermissionStatus.denied;
    }
  }

  // ✅ NOVO MÉTODO: Abrir configurações do app
  Future<void> openAppSettings() async {
    try {
      await openAppSettings();
      print('⚙️ Configurações do app abertas');
    } catch (e) {
      print('❌ Erro ao abrir configurações: $e');
    }
  }

  // ✅ NOVO MÉTODO: Verificar se notificações estão habilitadas no sistema
  Future<bool> areNotificationsEnabled() async {
    try {
      final status = await Permission.notification.status;
      return status.isGranted;
    } catch (e) {
      print('❌ Erro ao verificar se notificações estão habilitadas: $e');
      return false;
    }
  }

  // ✅ NOVO MÉTODO: Obter configurações atuais de notificação
  Future<Map<String, dynamic>> getNotificationSettings() async {
    try {
      final permissionStatus = await Permission.notification.status;
      final hasScheduled = await hasScheduledNotifications();
      final pending = await getPendingNotifications();

      return {
        'permission_granted': permissionStatus.isGranted,
        'has_scheduled_notifications': hasScheduled,
        'pending_notifications_count': pending.length,
        'service_initialized': _isInitialized,
      };
    } catch (e) {
      print('❌ Erro ao obter configurações de notificação: $e');
      return {
        'permission_granted': false,
        'has_scheduled_notifications': false,
        'pending_notifications_count': 0,
        'service_initialized': _isInitialized,
        'error': e.toString(),
      };
    }
  }
}
