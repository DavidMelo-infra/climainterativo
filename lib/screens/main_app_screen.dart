import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

import 'home_screen.dart';
import 'ranking_screen.dart';
import 'profile_screen.dart';
import 'community_screen.dart';
import 'forecast_screen.dart';
import '../utils/constants.dart';
import '../services/community_service.dart';
import '../services/fake_interaction_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

class MainAppScreen extends StatefulWidget {
  const MainAppScreen({super.key});

  @override
  State<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  int _currentIndex = 0;
  double? _initialLat;
  double? _initialLon;
  String? _initialCity;
  bool _isLoading = true;
  bool _locationError = false;

  // ✅ SISTEMA DE NOTIFICAÇÕES
  int _shownNotificationsCount = 0;
  List<Map<String, dynamic>> _shownNotifications =
      []; // ✅ CORRIGIDO: dynamic em vez de String

  // ✅ LISTA DE TIPOS DE NOTIFICAÇÕES
  final List<Map<String, String>> _allNotificationTypes = [
    {
      'title': '🌤️ Previsão Diária',
      'body':
          'Hoje: 25°C, parcialmente nublado. Ótimo dia para atividades externas!',
      'type': 'daily'
    },
    {
      'title': '⚠️ Alerta de Chuva Forte',
      'body':
          'Chuva intensa prevista para as próximas 2 horas. Leve guarda-chuva!',
      'type': 'rain'
    },
    {
      'title': '🔥 Temperatura Extrema',
      'body': 'ALERTA: 38°C esperados hoje. Mantenha-se hidratado e evite sol!',
      'type': 'extreme_temp'
    },
    {
      'title': '💨 Vento Forte',
      'body':
          'Ventos de 25 km/h detectados. Cuidado com objetos soltos na rua!',
      'type': 'wind'
    },
    {
      'title': '🌧️ Chuva Chegando',
      'body': 'Precipitação em 30 minutos. Prepare-se e leve capa de chuva!',
      'type': 'rain'
    },
  ];

  // ✅ TÍTULOS PARA O HEADER
  final List<String> _titles = [
    'Clima Interativo',
    'Comunidade',
    'Previsão do Tempo',
    'Ranking de Clima',
    'Meu Perfil',
  ];

  // ✅ ÍCONES PARA O HEADER
  final List<IconData> _headerIcons = [
    Icons.cloud,
    Icons.people,
    Icons.calendar_today,
    Icons.emoji_events,
    Icons.person,
  ];

  final List<Widget> _screens = []; // ✅ DECLARADO CORRETAMENTE

  @override
  void initState() {
    super.initState();
    _initializeApp();
    _initializeNotifications();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleNotificationPermissions();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _initializeApp() async {
    try {
      await AuthService.initializeUserSession();
      await _loadAndFetchWeather();
      _startFakeUsers();
    } catch (e) {
      print('❌ Erro na inicialização do app: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _initializeNotifications() async {
    try {
      await NotificationService().initialize();
      print('✅ Sistema de notificações inicializado');
    } catch (e) {
      print('❌ Erro ao inicializar notificações: $e');
    }
  }

  void _startFakeUsers() {
    Future.delayed(const Duration(minutes: 2), () {
      CommunityService.startFakeUsers();
      FakeInteractionService.startFakeRankingInteractions();
      print('⏰ Sistemas fake iniciados (2 minutos após login)');
    });
  }

  Future<void> _handleNotificationPermissions() async {
    try {
      final notificationService = NotificationService();
      final status =
          await notificationService.getNotificationPermissionStatus();

      print('🔔 Status da permissão: $status');

      if (status == PermissionStatus.permanentlyDenied && mounted) {
        _showPermissionDialog();
      } else if (status == PermissionStatus.denied) {
        final granted = await notificationService.requestPermissions();
        if (granted) {
          print('✅ Permissão concedida após solicitação');
        }
      }
    } catch (e) {
      print('❌ Erro ao verificar permissões: $e');
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('🔔 Permissão de Notificações Necessária'),
          content: const Text(
            'Para receber alertas climáticos e previsões do tempo, '
            'você precisa ativar as notificações nas configurações do app.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Depois'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                NotificationService().openAppSettings();
              },
              child: const Text('Abrir Configurações'),
            ),
          ],
        );
      },
    );
  }

  // ✅ TRIÂNGULO: ENVIAR NOTIFICAÇÃO REAL DO SISTEMA
  void _showNextNotification() async {
    if (_allNotificationTypes.isEmpty) return;

    final nextIndex = _shownNotificationsCount % _allNotificationTypes.length;
    final notification = _allNotificationTypes[nextIndex];

    setState(() {
      _shownNotifications.add({
        'title': notification['title']!,
        'body': notification['body']!,
        'type': notification['type']!,
        'order': (_shownNotificationsCount + 1)
            .toString(), // ✅ CORRIGIDO: .toString()
      });
      _shownNotificationsCount++;
    });

    // ✅ NOTIFICAÇÃO REAL DO SISTEMA
    final notificationService = NotificationService();
    await notificationService.showSystemNotification(
      title: notification['title']!,
      body: notification['body']!,
      type: notification['type']!,
      id: _shownNotificationsCount, // ID único
    );

    print('🔔 Notificação #$_shownNotificationsCount enviada para o sistema');
  }

  // ✅ BOLINHA: MOSTRAR LISTA DAS NOTIFICAÇÕES QUE JÁ APARECERAM
  void _showShownNotificationsList() {
    if (_shownNotifications.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhuma notificação foi mostrada ainda'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('📋 Notificações Mostradas ($_shownNotificationsCount)'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _shownNotifications.length,
            itemBuilder: (context, index) {
              final notification = _shownNotifications[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: kPrimaryColor,
                  child: Text(
                    '${notification['order']}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(notification['title']!),
                subtitle: Text(
                  'Ordem: ${notification['order']} • ${notification['body']!}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _shownNotifications.clear();
                _shownNotificationsCount = 0;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Histórico de notificações limpo'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Limpar Histórico'),
          ),
        ],
      ),
    );
  }

  // ✅ ÍCONE BASEADO NO TIPO DE NOTIFICAÇÃO
  Widget _getNotificationIcon(String type) {
    switch (type) {
      case 'rain':
        return const Icon(Icons.beach_access, color: Colors.blue);
      case 'extreme_temp':
        return const Icon(Icons.thermostat, color: Colors.red);
      case 'wind':
        return const Icon(Icons.air, color: Colors.green);
      case 'alert':
        return const Icon(Icons.warning, color: Colors.orange);
      default:
        return const Icon(Icons.cloud, color: Colors.blue);
    }
  }

  // ✅ TRIÂNGULO - BOTÃO "PRÓXIMA NOTIFICAÇÃO"
  Widget _buildTriangleButton() {
    return Positioned(
      right: 28,
      bottom: MediaQuery.of(context).size.height * 0.4 + 70,
      child: GestureDetector(
        onTap: _showNextNotification,
        child: Container(
          width: 36,
          height: 28,
          child: CustomPaint(
            painter: TrianglePainter(),
          ),
        ),
      ),
    );
  }

  // ✅ BOLINHA - CONTADOR E HISTÓRICO
  Widget _buildNotificationButton() {
    return Positioned(
      right: 16,
      bottom: MediaQuery.of(context).size.height * 0.4,
      child: GestureDetector(
        onLongPress: _handleNotificationPermissions,
        onTap: _showShownNotificationsList,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: kPrimaryColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.notifications,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(height: 2),
                Text(
                  '$_shownNotificationsCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<Position?> getCurrentLocation() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      print('📍 Iniciando busca por localização...');

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('❌ Serviços de localização desabilitados.');
        if (mounted) {
          setState(() {
            _locationError = true;
          });
        }
        return null;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        print('📋 Solicitando permissão de localização...');
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('❌ Permissão de localização negada.');
          if (mounted) {
            setState(() {
              _locationError = true;
            });
          }
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('❌ Permissão negada permanentemente.');
        if (mounted) {
          setState(() {
            _locationError = true;
          });
        }
        return null;
      }

      print('✅ Permissão concedida, obtendo localização...');

      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      print('📍 Localização obtida com SUCESSO:');
      print(' → Latitude: ${position.latitude}');
      print(' → Longitude: ${position.longitude}');
      print(' → Precisão: ${position.accuracy} metros');

      if (position.accuracy != null && position.accuracy! > 100) {
        print('⚠️ Localização com baixa precisão: ${position.accuracy} metros');
      }

      return position;
    } catch (e) {
      print('❌ ERRO na obtenção da localização: $e');
      if (mounted) {
        setState(() {
          _locationError = true;
        });
      }
      return null;
    }
  }

  Future<void> _loadAndFetchWeather() async {
    String? cityFromStorage;

    try {
      cityFromStorage = await loadLocalData('last_location_name');
      print('🏙️ Cidade do storage: $cityFromStorage');

      Position? position = await getCurrentLocation();

      if (mounted) {
        setState(() {
          if (position != null) {
            _initialLat = position.latitude;
            _initialLon = position.longitude;
            _initialCity = null;
            print('✅ Usando localização por GPS');
          } else if (cityFromStorage != null && cityFromStorage.isNotEmpty) {
            _initialCity = cityFromStorage;
            _initialLat = null;
            _initialLon = null;
            print('✅ Usando cidade do storage: $cityFromStorage');
          } else {
            _initialCity = 'São Paulo';
            _initialLat = null;
            _initialLon = null;
            print('⚠️ Usando fallback: São Paulo');
          }

          _screens.addAll([
            HomeScreen(
              profileRoute: profileRoute,
              loginRoute: loginRoute,
              initialLat: _initialLat,
              initialLon: _initialLon,
              initialCity: _initialCity,
            ),
            const CommunityScreen(),
            ForecastScreen(
              initialLat: _initialLat,
              initialLon: _initialLon,
              initialCity: _initialCity,
            ),
            const RankingScreen(),
            const ProfileScreen(),
          ]);

          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Erro no _loadAndFetchWeather: $e');
      if (mounted) {
        setState(() {
          _initialCity = 'São Paulo';
          _screens.addAll([
            HomeScreen(
              profileRoute: profileRoute,
              loginRoute: loginRoute,
              initialLat: null,
              initialLon: null,
              initialCity: _initialCity,
            ),
            const CommunityScreen(),
            ForecastScreen(
              initialLat: null,
              initialLon: null,
              initialCity: _initialCity,
            ),
            const RankingScreen(),
            const ProfileScreen(),
          ]);
          _isLoading = false;
        });
      }
    }
  }

  Future<void> saveLocalData(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
      print('💾 Dados salvos: $key = $value');
    } catch (e) {
      print('❌ Erro ao salvar dados locais: $e');
    }
  }

  Future<String?> loadLocalData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getString(key);
      print('📂 Dados carregados: $key = $value');
      return value;
    } catch (e) {
      print('❌ Erro ao carregar dados locais: $e');
      return null;
    }
  }

  // ✅ WIDGET DO HEADER PERSONALIZADO
  Widget _buildCustomHeader() {
    return Container(
      height: kToolbarHeight + MediaQuery.of(context).padding.top,
      width: double.infinity,
      decoration: BoxDecoration(
        color: kPrimaryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _headerIcons[_currentIndex],
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                _titles[_currentIndex],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [kGradientStart, kGradientMiddle, kGradientEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: Colors.white),
                const SizedBox(height: 20),
                const Text(
                  'Inicializando aplicativo...',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 10),
                if (_locationError)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      '⚠️ Problema com localização. Usando localização padrão.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 14,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              _buildCustomHeader(),
              Expanded(
                child: _screens[_currentIndex],
              ),
            ],
          ),
          // ✅ SISTEMA: TRIÂNGULO + BOLINHA
          _buildNotificationButton(),
          _buildTriangleButton(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: Colors.white,
          selectedItemColor: kPrimaryColor,
          unselectedItemColor: const Color(0xFF9CA3AF),
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.cloud, size: 24),
              activeIcon: Icon(Icons.cloud, size: 24, color: kPrimaryColor),
              label: 'Clima',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people, size: 24),
              activeIcon: Icon(Icons.people, size: 24, color: kPrimaryColor),
              label: 'Comunidade',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today, size: 24),
              activeIcon:
                  Icon(Icons.calendar_today, size: 24, color: kPrimaryColor),
              label: 'Previsão',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events, size: 24),
              activeIcon:
                  Icon(Icons.emoji_events, size: 24, color: kPrimaryColor),
              label: 'Ranking',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person, size: 24),
              activeIcon: Icon(Icons.person, size: 24, color: kPrimaryColor),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}

// ✅ TRIÂNGULO NORMAL
class TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = kPrimaryColor
      ..style = PaintingStyle.fill;

    final Path path = Path();

    path.moveTo(size.width / 2, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);

    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
