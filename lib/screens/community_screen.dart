import 'package:flutter/material.dart';
import 'dart:async';
import '../services/auth_service.dart';
import '../models/user_model.dart' as app_model;
import '../models/community_model.dart';
import '../services/community_service.dart';
import '../utils/constants.dart';
import '../utils/widgets.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  List<CommunityWeather> _communityData = [];
  bool _isLoading = true;
  String _selectedFilter = 'Todos';
  String _selectedPeriod = '4h';
  late Timer _autoRefreshTimer;

  // ✅ CONTROLAR ANIMAÇÃO DOS USUÁRIOS FAKE
  final Map<String, bool> _fakeUserAnimations = {};
  final Map<String, Timer> _animationTimers = {};
  final Map<String, int> _blinkCounters = {};
  final Map<String, bool> _completedAnimations = {};

  app_model.User? _currentUser; // ✅ USUÁRIO TIPADO

  // ✅ MÉTODO CORRIGIDO: Helper que devolve ícone e texto conforme o tipo de usuário
  ({IconData icon, String text}) _getUserTypeInfo(String userType) {
    if (userType == 'motorista') {
      return (icon: Icons.two_wheeler_outlined, text: 'Motorista/Veículo');
    } else if (userType == 'turista') {
      return (icon: Icons.directions_walk, text: 'Turista/Transeunte');
    }
    return (icon: Icons.group, text: 'Não definido');
  }

  @override
  void initState() {
    super.initState();
    // ✅ CARREGA USUÁRIO LOGADO
    _loadUserData();
    _loadCommunityData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _autoRefreshTimer.cancel();
    // ✅ Cancelar todos os timers de animação
    _animationTimers.forEach((key, timer) {
      timer.cancel();
    });
    _animationTimers.clear();
    super.dispose();
  }

  // ✅ MÉTODO CORRIGIDO: Animação de 3 piscadas com 0.75 segundos
  void _startFakeUserAnimation(String username) {
    // Se já completou a animação, não inicia novamente
    if (_completedAnimations[username] == true) {
      return;
    }
    _blinkCounters[username] = 0;
    // Inicia contador
    void blink() {
      if (_blinkCounters[username]! < 6) {
        // 3 piscadas = 6 estados (on/off)
        setState(() {
          _fakeUserAnimations[username] = !_fakeUserAnimations[username]!;
          _blinkCounters[username] = _blinkCounters[username]! + 1;
        });
        // ✅ CORREÇÃO: Agenda próxima piscada com 0.75 segundos
        _animationTimers[username] =
            Timer(const Duration(milliseconds: 750), blink);
      } else {
        // ✅ CORREÇÃO: Finaliza animação após 3 piscadas e fixa sem piscar
        setState(() {
          _fakeUserAnimations[username] = false;
          _completedAnimations[username] = true; // Marca como finalizado
        });
        _animationTimers.remove(username);
        _blinkCounters.remove(username);
      }
    }

    // Inicia primeira piscada
    setState(() {
      _fakeUserAnimations[username] = true;
    });
    _animationTimers[username] =
        Timer(const Duration(milliseconds: 750), blink);
  }

  // ✅ MÉTODO ATUALIZADO: Carregar dados com animação
  void _loadCommunityData({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
      });
    }
    final allData = await CommunityService.getCommunityInteractions();
    // ✅ NOVO: Identificar novos usuários fake e iniciar animação
    final newFakeUsers =
        allData.where((item) => _isFakeUser(item.username)).toList();
    for (final user in newFakeUsers) {
      // Só inicia animação se for um usuário novo que ainda não completou a animação
      if (!_completedAnimations.containsKey(user.username)) {
        _startFakeUserAnimation(user.username);
      }
    }
    // Aplica filtro de período
    List<CommunityWeather> filteredData =
        _filterByPeriod(allData, _selectedPeriod);
    // Aplica filtro de tipo de usuário
    if (_selectedFilter != 'Todos') {
      filteredData = filteredData
          .where((item) => item.userType == _selectedFilter)
          .toList();
    }
    if (mounted) {
      setState(() {
        _communityData = filteredData;
        if (!silent) {
          _isLoading = false;
        }
      });
    }
  }

  void _startAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        _loadCommunityData(silent: true);
      }
    });
  }

  List<CommunityWeather> _filterByPeriod(
    List<CommunityWeather> data,
    String period,
  ) {
    final now = DateTime.now();
    DateTime cutoffTime;
    switch (period) {
      case '2h':
        cutoffTime = now.subtract(const Duration(hours: 2));
        break;
      case '4h':
        cutoffTime = now.subtract(const Duration(hours: 4));
        break;
      case '8h':
        cutoffTime = now.subtract(const Duration(hours: 8));
        break;
      case '24h':
        cutoffTime = now.subtract(const Duration(hours: 24));
        break;
      default:
        cutoffTime = now.subtract(const Duration(hours: 4));
    }
    return data.where((item) {
      return item.dateTime.isAfter(cutoffTime);
    }).toList();
  }

  List<CommunityWeather> get _filteredData {
    if (_selectedFilter == 'Todos') return _communityData;
    return _communityData
        .where((item) => item.userType == _selectedFilter)
        .toList();
  }

  // ✅ MÉTODO CORRIGIDO: Encontra o clima mais mencionado
  String get _mostMentionedWeather {
    if (_communityData.isEmpty) return 'Nenhum dado ainda';
    final weatherCount = <String, int>{};
    for (final interaction in _communityData) {
      weatherCount[interaction.weatherStatus] =
          (weatherCount[interaction.weatherStatus] ?? 0) + 1;
    }
    final mostMentioned =
        weatherCount.entries.reduce((a, b) => a.value > b.value ? a : b);
    return '${mostMentioned.key} (${mostMentioned.value}x)';
  }

  bool get _hasCommunityData {
    return _communityData.isNotEmpty;
  }

  // ✅ MÉTODO: Verificar se é usuário fake
  bool _isFakeUser(String username) {
    final fakeUsernames = [
      'Caio_motoca',
      'Erik_entregador',
      'David_andarilho',
      'Well_motoca',
      'Nadine_panfleteira',
      'Julia_da_Rave',
      'Pedro_pixador',
      'Inacio_4e20'
    ];
    return fakeUsernames.contains(username);
  }

  Widget _buildWeatherIcon(String status) {
    switch (status) {
      case 'Ensolarado':
        return const Icon(Icons.wb_sunny, color: Colors.orange, size: 20);
      case 'Nublado':
        return const Icon(Icons.cloud, color: Colors.grey, size: 20);
      case 'Chuvoso':
        return const Icon(Icons.grain, color: Colors.blue, size: 20);
      case 'Tempestade':
        return const Icon(Icons.thunderstorm, color: Colors.purple, size: 20);
      case 'Frio Intenso':
        return const Icon(Icons.ac_unit, color: Colors.cyan, size: 20);
      case 'Úmido':
        return const Icon(Icons.water_drop, color: Colors.lightBlue, size: 20);
      case 'Ventania':
        return const Icon(Icons.air, color: Colors.green, size: 20);
      case 'Nevoeiro':
        return const Icon(Icons.foggy, color: Colors.grey, size: 20);
      case 'Noite Clara':
        return const Icon(Icons.nights_stay, color: Colors.indigo, size: 20);
      default:
        return const Icon(Icons.cloud, color: Colors.grey, size: 20);
    }
  }

  // ✅ MÉTODO ATUALIZADO: Item da comunidade com animação MAIS TRANSPARENTE
  Widget _buildCommunityItem(CommunityWeather data) {
    final isFakeUser = _isFakeUser(data.username);
    final isAnimating = _fakeUserAnimations[data.username] == true;
    final hasCompletedAnimation = _completedAnimations[data.username] == true;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: data.isCurrentUser
            ? kPrimaryColor.withOpacity(0.05)
            : (isFakeUser
                ? (isAnimating
                    ? Colors.orange
                        .withOpacity(0.08) // ✅ MUITO MAIS TRANSPARENTE
                    : Colors.orange.withOpacity(0.02))
                : Colors.white),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: data.isCurrentUser
              ? kPrimaryColor.withOpacity(0.3)
              : (isFakeUser
                  ? (isAnimating
                      ? Colors.orange
                          .withOpacity(0.3) // ✅ BORDA MAIS TRANSPARENTE
                      : Colors.orange.withOpacity(0.15))
                  : const Color(0xFFE5E7EB)),
          width: data.isCurrentUser ? 2 : (isAnimating ? 1.5 : 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isAnimating ? 0.05 : 0.03),
            blurRadius: isAnimating ? 4 : 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho com usuário e comparação
          Row(
            children: [
              // Ícone do usuário - COM ANIMAÇÃO MUITO TRANSPARENTE
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: data.isCurrentUser
                      ? kPrimaryColor.withOpacity(0.1)
                      : (isFakeUser
                          ? (isAnimating
                              ? Colors.orange
                                  .withOpacity(0.1) // ✅ MUITO TRANSPARENTE
                              : Colors.orange.withOpacity(0.05))
                          : const Color(0xFFF3F4F6)),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  data.userIcon,
                  color: data.isCurrentUser
                      ? kPrimaryColor
                      : (isFakeUser
                          ? (isAnimating
                              ? Colors.orange
                                  .withOpacity(0.6) // ✅ ÍCONE MAIS TRANSPARENTE
                              : Colors.orange.withOpacity(0.7))
                          : const Color(0xFF6B7280)),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 300),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: data.isCurrentUser
                                ? kPrimaryColor
                                : (isFakeUser
                                    ? (isAnimating
                                        ? Colors.orange.withOpacity(
                                            0.6) // ✅ TEXTO MAIS TRANSPARENTE
                                        : Colors.orange.withOpacity(0.7))
                                    : const Color(0xFF1F2937)),
                            fontSize: 14,
                          ),
                          child: Text(data.username),
                        ),
                        if (data.isCurrentUser) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: kPrimaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Reportou',
                              style: TextStyle(
                                color: kPrimaryColor,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                        if (isFakeUser) ...[
                          const SizedBox(width: 6),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isAnimating
                                  ? Colors.orange
                                      .withOpacity(0.1) // ✅ MUITO TRANSPARENTE
                                  : Colors.orange.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              hasCompletedAnimation
                                  ? 'Comunidade'
                                  : 'Novo!', // ✅ MOSTRA "Novo!" apenas durante animação
                              style: TextStyle(
                                color: isAnimating
                                    ? Colors.orange.withOpacity(
                                        0.6) // ✅ TEXTO MAIS TRANSPARENTE
                                    : Colors.orange.withOpacity(0.7),
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.userType,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Comparação API vs Usuário
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    _buildWeatherIcon(data.weatherStatus),
                    const SizedBox(height: 4),
                    Text(
                      'Reportou',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: kPrimaryColor,
                      ),
                    ),
                    Text(
                      data.weatherStatus,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const Text(
                  'vs',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Column(
                  children: [
                    _buildWeatherIcon(data.apiWeatherStatus),
                    const SizedBox(height: 4),
                    const Text(
                      'App Clima Interativo',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      data.apiWeatherStatus,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Localização e horário
          Row(
            children: [
              Icon(Icons.location_on, size: 12, color: const Color(0xFF6B7280)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  data.location,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.access_time, size: 12, color: const Color(0xFF6B7280)),
              const SizedBox(width: 4),
              Text(
                data.timeAgo,
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['Todos', 'Motorista/Veículo', 'Turista/Transeunte'];
    return Wrap(
      spacing: 8,
      children: filters.map((filter) {
        final isSelected = _selectedFilter == filter;
        return FilterChip(
          label: Text(filter),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _selectedFilter = selected ? filter : 'Todos';
              _loadCommunityData();
            });
          },
          backgroundColor: Colors.white,
          selectedColor: kPrimaryColor.withOpacity(0.1),
          checkmarkColor: kPrimaryColor,
          labelStyle: TextStyle(
            color: isSelected ? kPrimaryColor : const Color(0xFF6B7280),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
          side: BorderSide(
            color: isSelected ? kPrimaryColor : const Color(0xFFE5E7EB),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPeriodSelector() {
    final periods = [
      {'label': '2h', 'value': '2h'},
      {'label': '4h', 'value': '4h'},
      {'label': '8h', 'value': '8h'},
      {'label': '24h', 'value': '24h'},
    ];
    return Wrap(
      spacing: 8,
      children: periods.map((period) {
        final isSelected = _selectedPeriod == period['value'];
        return ChoiceChip(
          label: Text(period['label']!),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _selectedPeriod = period['value']!;
              _loadCommunityData();
            });
          },
          backgroundColor: Colors.white,
          selectedColor: kSecondaryColor.withOpacity(0.1),
          labelStyle: TextStyle(
            color: isSelected ? kSecondaryColor : const Color(0xFF6B7280),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
          side: BorderSide(
            color: isSelected ? kSecondaryColor : const Color(0xFFE5E7EB),
          ),
        );
      }).toList(),
    );
  }

  // Widget para o destaque do clima mais mencionado
  Widget _buildMostMentionedHighlight() {
    if (!_hasCommunityData) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFE5E7EB).withOpacity(0.3),
              const Color(0xFFF3F4F6).withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF9CA3AF).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.info_outline,
                color: const Color(0xFF6B7280),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Aguardando dados...',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Registre seu primeiro clima para ver estatísticas!',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    final mostMentioned = _mostMentionedWeather;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            kSecondaryColor.withOpacity(0.15),
            kSecondaryColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: kSecondaryColor.withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: kSecondaryColor.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kSecondaryColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.trending_up,
              color: kSecondaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Clima mais mencionado na sua região:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: kSecondaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  mostMentioned,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ MÉTODO PARA CARREGAR USUÁRIO LOGADO
  Future<void> _loadUserData() async {
    final user = await AuthService.getCurrentUser();
    if (mounted) {
      setState(() {
        _currentUser = user;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _currentUser;
    final userTypeRaw = currentUser?.userType ?? 'turista';
    final userInfo = _getUserTypeInfo(userTypeRaw);
    final userIcon = userInfo.icon;
    final userTypeDisplay = userInfo.text;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8FAFC), Color(0xFFEFF6FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header da Comunidade
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Header Container
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(userIcon, size: 32, color: kPrimaryColor),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Sua Comunidade: $userTypeDisplay',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1F2937),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Total de registros: ${_communityData.length}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF6B7280),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Destaque do clima mais mencionado
                            _buildMostMentionedHighlight(),
                            const SizedBox(height: 12),
                            // Seletor de Período
                            const Text(
                              'Período:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF4B5563),
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildPeriodSelector(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Filtros
                      const Text(
                        'Filtrar por:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF4B7280),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildFilterChips(),
                      const SizedBox(height: 16),
                      // Lista da Comunidade
                      _isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(40.0),
                              child: Column(
                                children: [
                                  CircularProgressIndicator(
                                    color: kPrimaryColor,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Carregando comunidade...',
                                    style: TextStyle(color: Color(0xFF6B7280)),
                                  ),
                                ],
                              ),
                            )
                          : _filteredData.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.all(40.0),
                                  child: Column(
                                    children: [
                                      Icon(Icons.group_off,
                                          size: 64, color: Color(0xFF9CA3AF)),
                                      SizedBox(height: 16),
                                      Text(
                                        'Nenhum registro na comunidade',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Color(0xFF6B7280),
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Seja o primeiro a registrar o clima!',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF9CA3AF),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Column(
                                  children: [
                                    const SizedBox(height: 8),
                                    ..._filteredData
                                        .map(
                                            (data) => _buildCommunityItem(data))
                                        .toList(),
                                  ],
                                ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
