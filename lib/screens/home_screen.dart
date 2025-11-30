import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ← ADICIONADO
import '../services/auth_service.dart';
import '../services/ranking_service.dart';
import '../services/community_service.dart';
import '../services/weather_service.dart';
import '../utils/constants.dart';
import '../utils/widgets.dart';
import '../models/user_model.dart' as app_model;

class HomeScreen extends StatefulWidget {
  final String profileRoute;
  final String loginRoute;
  final double? initialLat;
  final double? initialLon;
  final String? initialCity;

  const HomeScreen({
    super.key,
    required this.profileRoute,
    required this.loginRoute,
    this.initialLat,
    this.initialLon,
    this.initialCity,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _cityController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  String _weatherResult = 'Pesquise o clima em uma cidade!';
  bool _isLoadingWeather = false;
  bool _isLoadingLocation = false;
  String? _feedback;
  String? _apiWeatherStatus;
  bool _showLocationDialog = true;
  app_model.User? _currentUser; // ✅ USUÁRIO TIPADO
  bool _isLoadingUser = true; // ✅ INDICA CARREGAMENTO DO USUÁRIO

  @override
  void initState() {
    super.initState();

    // ✅ CARREGA USUÁRIO LOGADO
    _loadUserData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      WeatherService.rastrearLocalizacao();
    });

    if (widget.initialLat != null && widget.initialLon != null) {
      _fetchWeatherByLocation(lat: widget.initialLat!, lon: widget.initialLon!);
    } else if (widget.initialCity != null) {
      _cityController.text = widget.initialCity!;
      _fetchWeather();
    }

    _checkLocationPermission();
  }

  // ✅ MÉTODO PARA CARREGAR USUÁRIO LOGADO
  Future<void> _loadUserData() async {
    try {
      final user = await AuthService.getCurrentUser(); // ✅ Adicione await
      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLoadingUser = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingUser = false;
        });
      }
    }
  }

  void _checkLocationPermission() async {
    final locationStatus = await Permission.location.status;
    if (mounted) {
      setState(() {
        _showLocationDialog = !locationStatus.isGranted;
      });
    }
    if (_showLocationDialog && mounted) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _showLocationPermissionDialog();
      });
    }
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  // MÉTODO PARA SALVAR LOCALIZAÇÃO NO SHAREDPREFERENCES
  Future<void> _savePreciseLocation(String locationName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('precise_location_name', locationName);
      print(' Localização salva: $locationName');
    } catch (e) {
      print(' Erro ao salvar localização: $e');
    }
  }

  // MÉTODO PARA CARREGAR LOCALIZAÇÃO SALVA
  Future<String?> _loadPreciseLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('precise_location_name');
    } catch (e) {
      print(' Erro ao carregar localização: $e');
      return null;
    }
  }

  // ATUALIZAR _fetchWeatherByLocation para salvar a localização
  void _fetchWeatherByLocation(
      {required double lat, required double lon}) async {
    setState(() {
      _isLoadingWeather = true;
      _weatherResult = 'Obtendo localização precisa...';
      _feedback = null;
    });
    final weatherData =
        await WeatherService.getCurrentWeatherByCoords(lat, lon);
    if (mounted) {
      setState(() {
        _isLoadingWeather = false;
        if (weatherData['success']) {
          final temperature = weatherData['temperature'];
          final description = weatherData['description'];
          final city = weatherData['city'];
          final neighborhood = weatherData['neighborhood'];
          final locationName = neighborhood ?? city;
          _cityController.text = locationName;
          // SALVAR LOCALIZAÇÃO NO SHAREDPREFERENCES
          _savePreciseLocation(locationName);
          _weatherResult = '''
 Clima em $locationName:
 $temperature°C - $description
 Umidade: ${weatherData['humidity']}% | Vento: ${weatherData['wind_speed']} km/h''';
          _apiWeatherStatus =
              WeatherService.mapToOurWeatherSystem(weatherData['main']);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(' Localização precisa: $locationName'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          _weatherResult =
              'Erro ao obter localização: ${weatherData['message']}';
          _apiWeatherStatus = null;
        }
      });
    }
  }

  // ATUALIZAR _fetchPreciseLocationWeather para salvar a localização
  void _fetchPreciseLocationWeather() async {
    setState(() {
      _isLoadingWeather = true;
      _isLoadingLocation = true;
      _weatherResult = 'Obtendo sua localização precisa...';
      _feedback = null;
    });
    final weatherData = await WeatherService.getPreciseLocationWeather();
    if (mounted) {
      setState(() {
        _isLoadingWeather = false;
        _isLoadingLocation = false;
        if (weatherData['success']) {
          final temperature = weatherData['temperature'];
          final description = weatherData['description'];
          final city = weatherData['city'];
          final neighborhood = weatherData['neighborhood'];
          final locationName = neighborhood ?? city;
          _cityController.text = locationName;
          // SALVAR LOCALIZAÇÃO NO SHAREDPREFERENCES
          _savePreciseLocation(locationName);
          _weatherResult = '''
 Clima em $locationName:
 $temperature°C - $description
 Umidade: ${weatherData['humidity']}% | Vento: ${weatherData['wind_speed']} km/h''';
          _apiWeatherStatus =
              WeatherService.mapToOurWeatherSystem(weatherData['main']);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(' Localização precisa: $locationName'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          _weatherResult = 'Erro: ${weatherData['message']}';
          _apiWeatherStatus = null;
          if (weatherData['message'].toString().contains('localização') ||
              weatherData['message'].toString().contains('location')) {
            _cityController.text = 'São Paulo';
            _fetchWeather();
          }
        }
      });
    }
  }

  // ATUALIZAR _fetchWeather para salvar quando busca manual
  void _fetchWeather() async {
    if (_cityController.text.isEmpty) {
      setState(() {
        _feedback = 'Por favor, digite o nome de uma cidade para pesquisar.';
      });
      return;
    }
    setState(() {
      _isLoadingWeather = true;
      _weatherResult = 'Buscando dados para ${_cityController.text}...';
      _feedback = null;
    });
    final weatherData =
        await WeatherService.getCurrentWeather(_cityController.text);
    if (mounted) {
      setState(() {
        _isLoadingWeather = false;
        if (weatherData['success']) {
          final temperature = weatherData['temperature'];
          final description = weatherData['description'];
          final city = weatherData['city'];
          // SALVAR LOCALIZAÇÃO NO SHAREDPREFERENCES (busca manual também)
          _savePreciseLocation(city);
          _weatherResult = '''
 Clima em $city:
 $temperature°C - $description
 Umidade: ${weatherData['humidity']}% | Vento: ${weatherData['wind_speed']} km/h''';
          _apiWeatherStatus =
              WeatherService.mapToOurWeatherSystem(weatherData['main']);
        } else {
          _weatherResult = 'Erro: ${weatherData['message']}';
          _apiWeatherStatus = null;
        }
      });
    }
  }

  void _showLocationPermissionDialog() {
    if (!_showLocationDialog) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.80,
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          color: kPrimaryColor, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Localização Precisa',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Melhore sua experiência',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ative sua localização para obter informações climáticas precisas da sua área atual automaticamente.',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ' Localização atual: ${_cityController.text.isNotEmpty ? _cityController.text : "Não detectada"}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: const LinearGradient(
                            colors: [kPrimaryColor, Color(0xFF1565C0)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: kPrimaryColor.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _requestLocationPermissionAndFetch();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.location_on, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Ativar Localização',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            setState(() {
                              _showLocationDialog = false;
                            });
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: kPrimaryColor, width: 1),
                            ),
                          ),
                          child: Text(
                            'Agora Não',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: kPrimaryColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _requestLocationPermissionAndFetch() async {
    setState(() {
      _isLoadingLocation = true;
    });
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _isLoadingLocation = false;
          });
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('GPS Desativado'),
              content: const Text(
                'Para detectar o clima automaticamente, ative a localização nas configurações do dispositivo.',
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await Geolocator.openLocationSettings();
                  },
                  child: const Text('Ativar Agora'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      _showLocationDialog = false;
                    });
                  },
                  child: const Text('Cancelar'),
                ),
              ],
            ),
          );
        }
        return;
      }
      final locationStatus = await Permission.location.status;
      if (!locationStatus.isGranted) {
        final permissionResult = await Permission.location.request();
        if (permissionResult.isGranted) {
          if (mounted) {
            setState(() {
              _showLocationDialog = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(' Localização ativada com sucesso!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
          _fetchPreciseLocationWeather();
        } else {
          if (mounted) {
            setState(() {
              _showLocationDialog = false;
              _isLoadingLocation = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Você pode ativar a localização depois pelo botão de GPS',
                ),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _showLocationDialog = false;
          });
        }
        _fetchPreciseLocationWeather();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao obter localização: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showPhotoSuggestionDialog(String weatherStatus) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.80,
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.photo_camera, color: kPrimaryColor, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Ajude a Comunidade!',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Você selecionou: $weatherStatus',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Compartilhe uma foto do céu e ganhe +4 pontos extras para o ranking!',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ' Local: ${_cityController.text.isNotEmpty ? _cityController.text : "Sua localização"}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: const LinearGradient(
                            colors: [kSecondaryColor, Color(0xFFFF8A00)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: kSecondaryColor.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _openCameraAndRegister(weatherStatus);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.photo_camera, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Tirar Foto +4pts',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _registerWeatherInteraction(weatherStatus);
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: kPrimaryColor, width: 1),
                            ),
                          ),
                          child: Text(
                            'Agora Não',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: kPrimaryColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openCameraAndRegister(String weatherStatus) async {
    try {
      final cameraStatus = await Permission.camera.status;
      if (!cameraStatus.isGranted) {
        final permissionResult = await Permission.camera.request();
        if (!permissionResult.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text('Permissão da câmera é necessária para tirar foto'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
              ),
            );
            _registerWeatherInteraction(weatherStatus);
          }
          return;
        }
      }
      try {
        final XFile? photo = await _imagePicker.pickImage(
          source: ImageSource.camera,
          preferredCameraDevice: CameraDevice.rear,
          maxWidth: 1200,
          maxHeight: 1200,
          imageQuality: 85,
        );
        if (photo != null) {
          if (mounted) {
            _showPhotoAnalysisMessage(weatherStatus, photo.path);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Câmera cancelada - registro normal'),
                backgroundColor: Colors.grey,
                duration: Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
            _registerWeatherInteraction(weatherStatus);
          }
        }
      } catch (e) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Câmera Indisponível'),
              content: const Text(
                'Não foi possível abrir a câmera. Deseja escolher uma foto da galeria?',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _registerWeatherInteraction(weatherStatus);
                  },
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _openGalleryAndRegister(weatherStatus);
                  },
                  child: const Text('Galeria'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Erro ao acessar câmera - registro normal'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      _registerWeatherInteraction(weatherStatus);
    }
  }

  void _openGalleryAndRegister(String weatherStatus) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (image != null && mounted) {
        _showPhotoAnalysisMessage(weatherStatus, image.path);
      } else {
        if (mounted) {
          _registerWeatherInteraction(weatherStatus);
        }
      }
    } catch (e) {
      if (mounted) {
        _registerWeatherInteraction(weatherStatus);
      }
    }
  }

  void _showPhotoAnalysisMessage(String weatherStatus, String photoPath) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(' Foto capturada! Em análise...'),
          backgroundColor: kPrimaryColor,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(' Foto aprovada! +4 pontos adicionados'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
        _registerWeatherInteractionWithBonus(weatherStatus, photoPath);
      }
    });
  }

  // MÉTODO CORRIGIDO: Registro com bônus após foto aprovada (4 PONTOS + 1 PONTO)
  Future<void> _registerWeatherInteractionWithBonus(
    String status,
    String photoPath,
  ) async {
    final buttonResult = await RankingService.registerWeatherButtonClick();
    final photoResult = await RankingService.registerPhotoUpload();
    final currentUser = _currentUser; // ✅ USUÁRIO TIPADO
    if (currentUser != null) {
      await CommunityService.addCommunityInteraction(
        userName: currentUser.name,
        username: currentUser.username,
        userType: currentUser.userType,
        weatherStatus: status,
        apiWeatherStatus: _apiWeatherStatus ?? "Dados não disponíveis",
        location: _cityController.text.isNotEmpty
            ? _cityController.text
            : 'Local não especificado',
        dateTime: DateTime.now(),
        isCurrentUser: true,
        hasPhoto: true,
      );
    }
    if (mounted) {
      if (buttonResult['success'] && photoResult['success']) {
        final totalPoints =
            (buttonResult['points'] ?? 0) + (photoResult['points'] ?? 0);
        final buttonBonus = buttonResult['bonusPoints'] ?? 0;
        final photoBonus = photoResult['bonusPoints'] ?? 0;
        final totalBonus = buttonBonus + photoBonus;

        // LÓGICA PLURAL/SINGULAR
        final pointsText = totalPoints == 1 ? 'ponto' : 'pontos';
        final bonusText = totalBonus == 1 ? 'bônus' : 'bônus';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ' +$totalPoints $pointsText! (1 clima + 4 foto + $totalBonus $bonusText)',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (buttonResult['success']) {
        final points = buttonResult['points'] ?? 0;
        final bonus = buttonResult['bonusPoints'] ?? 0;

        // LÓGICA PLURAL/SINGULAR
        final pointsText = points == 1 ? 'ponto' : 'pontos';
        final bonusText = bonus == 1 ? 'bônus' : 'bônus';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(' +$points $pointsText! (1 clima + $bonus $bonusText)'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(buttonResult['message'] ??
                photoResult['message'] ??
                'Erro desconhecido'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
    print(' Foto salva em: $photoPath');
  }

  // MÉTODO CORRIGIDO: Registro de interação com clima (1 PONTO)
  void _registerWeatherInteraction(String status) async {
    final result = await RankingService.registerWeatherButtonClick();
    final currentUser = _currentUser; // ✅ USUÁRIO TIPADO
    if (currentUser != null) {
      await CommunityService.addCommunityInteraction(
        userName: currentUser.name,
        username: currentUser.username,
        userType: currentUser.userType,
        weatherStatus: status,
        apiWeatherStatus: _apiWeatherStatus ?? "Dados não disponíveis",
        location: _cityController.text.isNotEmpty
            ? _cityController.text
            : 'Local não especificado',
        dateTime: DateTime.now(),
        isCurrentUser: true,
        hasPhoto: false,
      );
    }
    if (mounted) {
      if (result['success']) {
        final points = result['points'] ?? 0;
        final basePoints = result['basePoints'] ?? 0;
        final bonusPoints = result['bonusPoints'] ?? 0;

        // LÓGICA PLURAL/SINGULAR
        final pointsText = points == 1 ? 'ponto' : 'pontos';
        final baseText = basePoints == 1 ? 'base' : 'base';
        final bonusText = bonusPoints == 1 ? 'bônus' : 'bônus';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ' +$points $pointsText! ($basePoints $baseText + $bonusPoints $bonusText)',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildProfileIcon() {
    // ✅ USUÁRIO TIPADO
    final userType = _currentUser?.userType ?? 'Desconhecido';
    final isDriver = userType.contains('Motorista');
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 5,
          ),
        ],
      ),
      child: Icon(
        isDriver ? Icons.two_wheeler_outlined : Icons.directions_walk,
        color: kPrimaryColor,
        size: 18,
      ),
    );
  }

  void _setFeedback(String feedback) {
    setState(() {
      _feedback = feedback;
    });
  }

  String? _extractTemperature(String weatherResult) {
    try {
      final lines = weatherResult.split('\n');
      for (final line in lines) {
        if (line.contains('°C')) {
          final regex = RegExp(r'(-?\d+)°C');
          final match = regex.firstMatch(line);
          if (match != null) {
            return match.group(1);
          }
        }
      }
    } catch (e) {
      print(' Erro ao extrair temperatura: $e');
    }
    return null;
  }

  String? _extractDescription(String weatherResult) {
    try {
      final lines = weatherResult.split('\n');
      for (final line in lines) {
        if (line.contains('°C') && line.contains('-')) {
          final parts = line.split('-');
          if (parts.length > 1) {
            return parts[1].trim();
          }
        }
      }
    } catch (e) {
      print(' Erro ao extrair descrição: $e');
    }
    return null;
  }

  String? _extractLocation(String weatherResult) {
    try {
      // Tenta extrair do formato "Clima em [local]:"
      if (weatherResult.startsWith('Clima em ')) {
        final lines = weatherResult.split('\n');
        final locationLine = lines[0];
        return locationLine.replaceFirst('Clima em ', '').replaceFirst(':', '');
      }
      // Fallback: procura por padrões comuns
      final patterns = [
        RegExp(r'Clima em (.+?)\n'),
        RegExp(r'em (.+?)\n'),
        RegExp(r'📍 (.+?)\n'),
      ];
      for (final pattern in patterns) {
        final match = pattern.firstMatch(weatherResult);
        if (match != null) {
          return match.group(1);
        }
      }
      return null;
    } catch (e) {
      print('❌ Erro ao extrair localização: $e');
      return null;
    }
  }

  String _extractAdditionalDetails(String weatherResult) {
    try {
      final lines = weatherResult.split('\n');
      final details = <String>[];
      for (final line in lines) {
        if (line.contains('Umidade:') || line.contains('Vento:')) {
          details.add(line.trim());
        }
      }
      return details.join(' | ');
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final temperature = _extractTemperature(_weatherResult);
    final description = _extractDescription(_weatherResult);
    final location = _extractLocation(_weatherResult);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [kGradientStart, kGradientMiddle, kGradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(16.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 25,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Busca de Clima',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Pesquisar Temperatura e Local',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: kPrimaryColor.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _cityController,
                              decoration: InputDecoration(
                                hintText: 'Digite o nome do bairro ou cidade',
                                labelText: 'Localização',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide:
                                      const BorderSide(color: kPrimaryColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: kSecondaryColor,
                                    width: 2,
                                  ),
                                ),
                              ),
                              onSubmitted: _isLoadingWeather
                                  ? null
                                  : (_) => _fetchWeather(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _isLoadingLocation
                                ? null
                                : _requestLocationPermissionAndFetch,
                            icon: _isLoadingLocation
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: kPrimaryColor,
                                    ),
                                  )
                                : const Icon(Icons.my_location,
                                    color: kPrimaryColor),
                            tooltip: 'Usar minha localização atual precisa',
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: _isLoadingWeather
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: kPrimaryColor,
                                    ),
                                  )
                                : const Icon(Icons.search,
                                    color: kPrimaryColor),
                            onPressed: _isLoadingWeather ? null : _fetchWeather,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: kPrimaryColor.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: kPrimaryColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // NOME DO LOCAL - MESMA LÓGICA DO CÓDIGO ANTIGO
                            if (location != null)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                child: Text(
                                  '📍 $location',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF4B5563),
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            if (temperature != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    temperature,
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      fontFamily: 'Roboto',
                                      color: Color(0xff0445a0),
                                      letterSpacing: -1,
                                      height: 0.9,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    '°C',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xff0445a0),
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (description != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                description,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: kSecondaryColor,
                                  fontStyle: FontStyle.italic,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                            if (_weatherResult.contains('Umidade') ||
                                _weatherResult.contains('Vento'))
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  _extractAdditionalDetails(_weatherResult),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF6B7280),
                                    fontWeight: FontWeight.w400,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            if (temperature == null && description == null)
                              Text(
                                _weatherResult,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                              ),
                          ],
                        ),
                      ),
                      if (_apiWeatherStatus != null)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: kSecondaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            ' Status do clima',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: kSecondaryColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      const Divider(height: 30, color: Color(0xFFE5E7EB)),
                      const Text(
                        'Agora é a sua vez, diga como está o clima pra você e ganhe pontos!',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      if (_feedback != null)
                        Container(
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: kSecondaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: kSecondaryColor),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_outline,
                                  color: kSecondaryColor),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Status: $_feedback',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: kSecondaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      SizedBox(
                        height: 320,
                        child: GridView.count(
                          crossAxisCount: 3,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          childAspectRatio: 1.0,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          padding: const EdgeInsets.all(0),
                          children: [
                            _buildWeatherStatus(
                              Icons.wb_sunny,
                              'Ensolarado',
                              'Ensolarado',
                            ),
                            _buildWeatherStatus(
                              Icons.cloud,
                              'Nublado',
                              'Nublado',
                            ),
                            _buildWeatherStatus(
                              Icons.grain,
                              'Chuvoso',
                              'Chuvoso',
                            ),
                            _buildWeatherStatus(
                              Icons.thunderstorm,
                              'Tempestade',
                              'Tempestade',
                            ),
                            _buildWeatherStatus(
                              Icons.ac_unit,
                              'Frio Intenso',
                              'Frio Intenso',
                            ),
                            _buildWeatherStatus(
                              Icons.water_drop,
                              'Úmido',
                              'Úmido',
                            ),
                            _buildWeatherStatus(
                              Icons.air,
                              'Ventania',
                              'Ventania',
                            ),
                            _buildWeatherStatus(
                              Icons.foggy,
                              'Nevoeiro',
                              'Nevoeiro',
                            ),
                            _buildWeatherStatus(
                              Icons.nights_stay,
                              'Noite Clara',
                              'Noite Clara',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherStatus(IconData icon, String label, String status) {
    final isSelected = _feedback == status;
    return GestureDetector(
      onTap: () {
        _setFeedback(status);
        _showPhotoSuggestionDialog(status);
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? kSecondaryColor.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? kSecondaryColor : const Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? kSecondaryColor : const Color(0xFF4B5563),
              size: 32,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? kSecondaryColor : const Color(0xFF4B5563),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
