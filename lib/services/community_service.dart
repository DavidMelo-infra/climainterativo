// ARQUIVO: lib/services/community_service.dart
import 'package:flutter/material.dart';
import '../models/community_model.dart';

class CommunityService {
  static final List<CommunityWeather> _communityInteractions = [];
  static bool _isInitialized = false;
  static bool _fakeUsersStarted = false;

  // ✅ LISTA DE USUÁRIOS FAKE
  static final List<Map<String, dynamic>> _fakeUsers = [
    {
      'userName': 'Caio Motoca',
      'username': 'Caio_motoca',
      'userType': 'Motorista/Veículo',
      'weatherStatus': 'Nublado',
      'apiWeatherStatus': 'Nublado',
      'location': 'Liberdade',
      'userIcon': Icons.two_wheeler_outlined,
    },
    {
      'userName': 'Erik Entregador',
      'username': 'Erik_entregador',
      'userType': 'Motorista/Veículo',
      'weatherStatus': 'Nublado',
      'apiWeatherStatus': 'Nublado',
      'location': 'Liberdade',
      'userIcon': Icons.two_wheeler_outlined,
    },
    {
      'userName': 'David Andarilho',
      'username': 'David_andarilho',
      'userType': 'Turista/Transeunte',
      'weatherStatus': 'Nublado',
      'apiWeatherStatus': 'Nublado',
      'location': 'Liberdade',
      'userIcon': Icons.directions_walk,
    },
    {
      'userName': 'Well Motoca',
      'username': 'Well_motoca',
      'userType': 'Motorista/Veículo',
      'weatherStatus': 'Nublado',
      'apiWeatherStatus': 'Nublado',
      'location': 'Liberdade',
      'userIcon': Icons.two_wheeler_outlined,
    },
    {
      'userName': 'Nadine Panfleteira',
      'username': 'Nadine_panfleteira',
      'userType': 'Turista/Transeunte',
      'weatherStatus': 'Nublado',
      'apiWeatherStatus': 'Nublado',
      'location': 'Liberdade',
      'userIcon': Icons.directions_walk,
    },
    {
      'userName': 'Julia da Rave',
      'username': 'Julia_da_Rave',
      'userType': 'Turista/Transeunte',
      'weatherStatus': 'Nublado',
      'apiWeatherStatus': 'Nublado',
      'location': 'Liberdade',
      'userIcon': Icons.directions_walk,
    },
    {
      'userName': 'Pedro Pixador',
      'username': 'Pedro_pixador',
      'userType': 'Turista/Transeunte',
      'weatherStatus': 'Nublado',
      'apiWeatherStatus': 'Nublado',
      'location': 'Liberdade',
      'userIcon': Icons.directions_walk,
    },
    {
      'userName': 'Inacio 4e20',
      'username': 'Inacio_4e20',
      'userType': 'Turista/Transeunte',
      'weatherStatus': 'Nublado',
      'apiWeatherStatus': 'Nublado',
      'location': 'Liberdade',
      'userIcon': Icons.directions_walk,
    },
  ];

  static int _currentFakeUserIndex = 0;

  // ✅ MÉTODO AUXILIAR: Calcula tempo relativo
  static String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'Agora mesmo';
    if (difference.inMinutes < 60) return '${difference.inMinutes} min atrás';
    if (difference.inHours < 24) return '${difference.inHours} h atrás';
    return '${difference.inDays} dias atrás';
  }

  // ✅ MÉTODO: Iniciar usuários fake
  static void startFakeUsers() {
    if (_fakeUsersStarted) return;

    _fakeUsersStarted = true;
    _currentFakeUserIndex = 0;

    print('🤖 Iniciando sistema de usuários fake...');

    // Primeiro usuário após 15 segundos
    Future.delayed(const Duration(seconds: 15), () {
      _addNextFakeUser();
    });
  }

  // ✅ MÉTODO: Adicionar próximo usuário fake
  static void _addNextFakeUser() {
    if (_currentFakeUserIndex >= _fakeUsers.length) {
      print('🤖 Todos os usuários fake foram adicionados');
      return;
    }

    final fakeUser = _fakeUsers[_currentFakeUserIndex];
    final now = DateTime.now();

    final interaction = CommunityWeather(
      userName: fakeUser['userName'] as String,
      username: fakeUser['username'] as String,
      userType: fakeUser['userType'] as String,
      weatherStatus: fakeUser['weatherStatus'] as String,
      apiWeatherStatus: fakeUser['apiWeatherStatus'] as String,
      location: fakeUser['location'] as String,
      timeAgo: _getTimeAgo(now),
      isCurrentUser: false,
      userIcon: fakeUser['userIcon'] as IconData,
      dateTime: now,
      hasPhoto: false,
    );

    _communityInteractions.insert(0, interaction);
    _currentFakeUserIndex++;

    print('🤖 Usuário fake adicionado: ${fakeUser['username']}');

    // Agenda próximo usuário se ainda houver
    if (_currentFakeUserIndex < _fakeUsers.length) {
      Future.delayed(const Duration(seconds: 15), () {
        _addNextFakeUser();
      });
    }
  }

  // ✅ MÉTODO: Parar usuários fake (opcional)
  static void stopFakeUsers() {
    _fakeUsersStarted = false;
    _currentFakeUserIndex = 0;
    print('🤖 Sistema de usuários fake parado');
  }

  // ✅ MÉTODO: Reiniciar usuários fake
  static void resetFakeUsers() {
    _fakeUsersStarted = false;
    _currentFakeUserIndex = 0;

    // Remove apenas interações fake (mantém as reais)
    _communityInteractions.removeWhere((interaction) {
      return _fakeUsers
          .any((fakeUser) => fakeUser['username'] == interaction.username);
    });

    print('🤖 Usuários fake resetados');
  }

  // Adiciona uma interação à comunidade
  static Future<void> addCommunityInteraction({
    required String userName,
    required String username,
    required String userType,
    required String weatherStatus,
    required String apiWeatherStatus,
    required String location,
    required DateTime dateTime,
    required bool isCurrentUser,
    bool hasPhoto = false,
  }) async {
    // Verifica se já existe uma interação similar nos últimos 5 minutos
    final now = DateTime.now();
    final existingInteraction = _communityInteractions.firstWhere(
      (interaction) =>
          interaction.username == username &&
          interaction.weatherStatus == weatherStatus &&
          interaction.apiWeatherStatus == apiWeatherStatus &&
          now.difference(interaction.dateTime).inMinutes < 5,
      orElse: () => CommunityWeather(
        userName: '',
        username: '',
        userType: '',
        weatherStatus: '',
        apiWeatherStatus: '',
        location: '',
        timeAgo: '',
        isCurrentUser: false,
        userIcon: Icons.person,
        dateTime: DateTime(0),
        hasPhoto: false,
      ),
    );

    if (existingInteraction.userName.isNotEmpty) {
      print('⚠️ Interação similar detectada - não será adicionada novamente');
      return;
    }

    final interaction = CommunityWeather(
      userName: userName,
      username: username,
      userType: userType,
      weatherStatus: weatherStatus,
      apiWeatherStatus: apiWeatherStatus,
      location: location,
      timeAgo: _getTimeAgo(dateTime),
      isCurrentUser: isCurrentUser,
      userIcon: _getUserIcon(userType),
      dateTime: dateTime,
      hasPhoto: hasPhoto,
    );

    _communityInteractions.insert(0, interaction);

    // Limita a lista para manter performance
    if (_communityInteractions.length > 50) {
      _communityInteractions.removeLast();
    }

    print(
        '🌍 Interação salva na comunidade: $username - $weatherStatus ${hasPhoto ? '📸' : ''}');
  }

  // ✅ MÉTODO AUXILIAR: Define ícone do usuário
  static IconData _getUserIcon(String userType) {
    return userType.contains('Motorista')
        ? Icons.two_wheeler_outlined
        : Icons.directions_walk;
  }

  // Carrega todas as interações da comunidade
  static Future<List<CommunityWeather>> getCommunityInteractions() async {
    if (!_isInitialized) {
      _isInitialized = true;
      print('📥 Comunidade inicializada vazia');
    }

    return List.from(_communityInteractions);
  }

  // Obtém o clima mais mencionado
  static String getMostMentionedWeather(List<CommunityWeather> interactions) {
    if (interactions.isEmpty) return 'Nenhum dado';

    final weatherCount = <String, int>{};
    for (final interaction in interactions) {
      weatherCount[interaction.weatherStatus] =
          (weatherCount[interaction.weatherStatus] ?? 0) + 1;
    }

    if (weatherCount.isEmpty) return 'Nenhum dado';

    final mostMentioned = weatherCount.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );

    return '${mostMentioned.key} (${mostMentioned.value}x)';
  }

  // Limpa todos os dados
  static void clearAllData() {
    _communityInteractions.clear();
    _isInitialized = false;
    _fakeUsersStarted = false;
    _currentFakeUserIndex = 0;
    print('🧹 Dados da comunidade limpos');
  }
}
