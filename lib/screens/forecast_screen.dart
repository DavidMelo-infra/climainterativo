import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/weather_service.dart';
import '../utils/constants.dart';

class ForecastScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLon;
  final String? initialCity;

  const ForecastScreen({
    super.key,
    this.initialLat,
    this.initialLon,
    this.initialCity,
  });

  @override
  State<ForecastScreen> createState() => _ForecastScreenState();
}

class _ForecastScreenState extends State<ForecastScreen> {
  final TextEditingController _cityController = TextEditingController();
  Map<String, dynamic> _forecastData = {};
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isLoadingSavedLocation = true;
  int _selectedDayIndex = 0;
  String _displayLocation = '';
  String _originalLocation = '';

  @override
  void initState() {
    super.initState();
    print('🔍 ForecastScreen iniciado');
    _loadSavedLocationAndForecast();
  }

  void _loadSavedLocationAndForecast() async {
    setState(() {
      _isLoadingSavedLocation = true;
    });

    try {
      final savedLocation = await _loadPreciseLocation();
      print(
          '🎯 ForecastScreen - Localização salva encontrada: "$savedLocation"');

      if (savedLocation != null && savedLocation.isNotEmpty) {
        print('🚀 USANDO LOCALIZAÇÃO SALVA DO HOME: "$savedLocation"');
        _displayLocation = savedLocation;
        _originalLocation = savedLocation;
        _cityController.text = savedLocation;
        await _fetchForecast();
      } else if (widget.initialCity != null && widget.initialCity!.isNotEmpty) {
        print('🎯 Usando initialCity: "${widget.initialCity}"');
        _displayLocation = widget.initialCity!;
        _originalLocation = widget.initialCity!;
        _cityController.text = widget.initialCity!;
        await _fetchForecast();
      } else {
        print('⚠️ NENHUMA LOCALIZAÇÃO SALVA ENCONTRADA');
        setState(() {
          _isLoadingSavedLocation = false;
        });
      }
    } catch (e) {
      print('❌ Erro ao carregar localização: $e');
      if (mounted) {
        setState(() {
          _isLoadingSavedLocation = false;
          _errorMessage = 'Erro ao carregar localização';
        });
      }
    }
  }

  Future<String?> _loadPreciseLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final location = prefs.getString('precise_location_name');
      print('📖 ForecastScreen - Lendo SharedPreferences: "$location"');
      return location;
    } catch (e) {
      print('❌ Erro ao ler SharedPreferences: $e');
      return null;
    }
  }

  Future<void> _fetchForecast() async {
    if (_cityController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Digite o nome de uma cidade';
      });
      return;
    }

    print('🌤️ Buscando previsão para: "${_cityController.text}"');

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _forecastData = {};
    });

    try {
      final fullLocationResult = await WeatherService.getFiveDayForecastSmart(
        cityName: _cityController.text,
      );

      print('🔍 Resultado busca completa: ${fullLocationResult['success']}');

      if (fullLocationResult['success']) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _forecastData = fullLocationResult;
            _selectedDayIndex = 0;
            _isLoadingSavedLocation = false;
          });
        }
        print('✅ Previsão carregada com sucesso!');
        return;
      }

      final locationParts = _cityController.text.split(',');
      if (locationParts.length > 1) {
        final cityName = locationParts.last.trim();
        print('🔄 Tentando com apenas a cidade: "$cityName"');

        final cityResult = await WeatherService.getFiveDayForecastSmart(
          cityName: cityName,
        );

        if (mounted) {
          setState(() {
            _isLoading = false;
            if (cityResult['success']) {
              _forecastData = cityResult;
              _selectedDayIndex = 0;
              _isLoadingSavedLocation = false;
              print('✅ Previsão carregada com fallback!');
            } else {
              _errorMessage =
                  'Não foi possível obter previsão para "$cityName"';
              _isLoadingSavedLocation = false;
              print('❌ Fallback também falhou: ${cityResult['message']}');
            }
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage =
                fullLocationResult['message'] ?? 'Erro ao buscar previsão';
            _isLoadingSavedLocation = false;
          });
        }
        print('❌ Busca falhou: ${fullLocationResult['message']}');
      }
    } catch (e) {
      print('❌ ERRO CRÍTICO na busca: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Erro interno ao buscar previsão';
          _isLoadingSavedLocation = false;
        });
      }
    }
  }

  Widget _buildDayCard(Map<String, dynamic> dayForecast, int index) {
    final date = dayForecast['date'] as DateTime;
    final isSelected = index == _selectedDayIndex;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDayIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 60,
        height: 80,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    kPrimaryColor,
                    kPrimaryColor.withOpacity(0.8),
                  ],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    Colors.grey[50]!,
                  ],
                ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? kPrimaryColor : Colors.grey[200]!,
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? kPrimaryColor.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.1),
              blurRadius: isSelected ? 8 : 4,
              offset: Offset(0, isSelected ? 4 : 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _getDayAbbreviation(date.weekday),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey[600],
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              date.day.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _getWeatherIcon(dayForecast),
              style: const TextStyle(fontSize: 22),
            ),
          ],
        ),
      ),
    );
  }

  String _getWeatherIcon(Map<String, dynamic> dayForecast) {
    if (dayForecast['icon'] != null) {
      return dayForecast['icon'].toString();
    }
    if (dayForecast['condition'] != null) {
      return _mapConditionToIcon(dayForecast['condition'].toString());
    }
    return '🌈';
  }

  String _mapConditionToIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'céu limpo':
      case 'ensolarado':
        return '☀️';
      case 'nublado':
      case 'nuvens dispersas':
        return '☁️';
      case 'chuva':
      case 'chuvisco':
        return '🌧️';
      case 'tempestade':
        return '⛈️';
      case 'neve':
        return '❄️';
      case 'nevoeiro':
        return '🌫️';
      default:
        return '🌈';
    }
  }

  Widget _buildDayDetails() {
    if (_forecastData['forecast'] == null ||
        _forecastData['forecast'].isEmpty) {
      return Container();
    }

    final day = _forecastData['forecast'][_selectedDayIndex];
    final date = day['date'] as DateTime;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey[50]!,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header com data e ícone
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getFullDayName(date.weekday),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${date.day} de ${_getMonthName(date.month)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      kPrimaryColor.withOpacity(0.15),
                      kPrimaryColor.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getWeatherIcon(day),
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Grid de informações 2x2
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.5,
            children: [
              _buildInfoCard(
                '🔥',
                'Máxima',
                '${day['max_temperature'] ?? day['temperature'] ?? 'N/A'}°',
                const Color(0xFFFF6B6B),
                true,
              ),
              _buildInfoCard(
                '❄️',
                'Mínima',
                '${day['min_temperature'] ?? 'N/A'}°',
                const Color(0xff376cff),
                true,
              ),
              _buildInfoCard(
                '💧',
                'Umidade',
                '${day['humidity'] ?? 'N/A'}%',
                const Color(0xFF45B7D1),
                false,
              ),
              _buildInfoCard(
                '🌧️',
                'Chuva',
                '${day['chance_of_rain'] ?? 'N/A'}%',
                const Color(0xFF9B59B6),
                false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    String icon,
    String label,
    String value,
    Color color,
    bool isHighlighted,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: isHighlighted
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withOpacity(0.2),
                  color.withOpacity(0.05),
                ],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.grey[50]!,
                ],
              ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isHighlighted ? color.withOpacity(0.3) : Colors.grey[200]!,
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              icon,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isHighlighted ? color : const Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationHeader() {
    if (_forecastData.isEmpty) return Container();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kPrimaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_on,
              color: kPrimaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _originalLocation.isNotEmpty
                    ? _originalLocation
                    : _displayLocation.isNotEmpty
                        ? _displayLocation
                        : _forecastData['location']?['name'] ??
                            _forecastData['city'] ??
                            'Local desconhecido',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              Text(
                'Previsão para os próximos 5 dias',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: Colors.grey[200]!,
            width: 1.5,
          ),
        ),
        child: TextField(
          controller: _cityController,
          decoration: InputDecoration(
            hintText: 'Pesquisar localização...',
            hintStyle: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
            ),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            suffixIcon: Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: kPrimaryColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.search, color: Colors.white, size: 20),
                onPressed: _fetchForecast,
              ),
            ),
          ),
          style: const TextStyle(fontSize: 14),
          onSubmitted: (_) => _fetchForecast(),
        ),
      ),
    );
  }

  String _getDayAbbreviation(int weekday) {
    switch (weekday) {
      case 1:
        return 'SEG';
      case 2:
        return 'TER';
      case 3:
        return 'QUA';
      case 4:
        return 'QUI';
      case 5:
        return 'SEX';
      case 6:
        return 'SÁB';
      case 7:
        return 'DOM';
      default:
        return '';
    }
  }

  String _getFullDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Segunda-feira';
      case 2:
        return 'Terça-feira';
      case 3:
        return 'Quarta-feira';
      case 4:
        return 'Quinta-feira';
      case 5:
        return 'Sexta-feira';
      case 6:
        return 'Sábado';
      case 7:
        return 'Domingo';
      default:
        return '';
    }
  }

  String _getMonthName(int month) {
    switch (month) {
      case 1:
        return 'Janeiro';
      case 2:
        return 'Fevereiro';
      case 3:
        return 'Março';
      case 4:
        return 'Abril';
      case 5:
        return 'Maio';
      case 6:
        return 'Junho';
      case 7:
        return 'Julho';
      case 8:
        return 'Agosto';
      case 9:
        return 'Setembro';
      case 10:
        return 'Outubro';
      case 11:
        return 'Novembro';
      case 12:
        return 'Dezembro';
      default:
        return '';
    }
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: kPrimaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              color: kPrimaryColor,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Carregando previsão...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.cloud_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Nenhuma previsão disponível',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pesquise uma cidade para ver a previsão',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Próximos 5 dias',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        toolbarHeight: 44,
      ),
      body: _isLoadingSavedLocation
          ? _buildLoadingState()
          : Column(
              children: [
                _buildSearchSection(),
                if (_errorMessage.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red[200]!, width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline,
                            color: Colors.red[700], size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage,
                            style: TextStyle(
                              color: Colors.red[700],
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_isLoading) Expanded(child: _buildLoadingState()),
                if (_forecastData.isNotEmpty && !_isLoading)
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildLocationHeader(),

                          // Dias da semana (rolagem horizontal)
                          Container(
                            height: 90,
                            margin: const EdgeInsets.only(top: 8, bottom: 4),
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              itemCount: _forecastData['forecast']?.length ?? 0,
                              itemBuilder: (context, index) {
                                return _buildDayCard(
                                  _forecastData['forecast'][index],
                                  index,
                                );
                              },
                            ),
                          ),

                          // Detalhes do dia selecionado
                          _buildDayDetails(),
                        ],
                      ),
                    ),
                  ),
                if (_forecastData.isEmpty &&
                    !_isLoading &&
                    _errorMessage.isEmpty)
                  Expanded(child: _buildEmptyState()),
              ],
            ),
    );
  }
}
