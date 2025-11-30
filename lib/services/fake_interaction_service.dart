import 'dart:async';
import '../services/ranking_service.dart';

class FakeInteractionService {
  static bool _fakeInteractionsStarted = false;
  static int _currentFakeUserIndex = 0;

  // ✅ LISTA DE USUÁRIOS FAKE PARA O RANKING
  static final List<Map<String, dynamic>> _fakeRankingUsers = [
    {
      'userName': 'Caio Motoca',
      'username': 'Caio_motoca',
      'userType': 'Motorista/Veículo',
    },
    {
      'userName': 'Erik Entregador',
      'username': 'Erik_entregador',
      'userType': 'Motorista/Veículo',
    },
    {
      'userName': 'David Andarilho',
      'username': 'David_andarilho',
      'userType': 'Turista/Transeunte',
    },
    {
      'userName': 'Well Motoca',
      'username': 'Well_motoca',
      'userType': 'Motorista/Veículo',
    },
    {
      'userName': 'Nadine Panfleteira',
      'username': 'Nadine_panfleteira',
      'userType': 'Turista/Transeunte',
    },
    {
      'userName': 'Julia da Rave',
      'username': 'Julia_da_Rave',
      'userType': 'Turista/Transeunte',
    },
    {
      'userName': 'Pedro Pixador',
      'username': 'Pedro_pixador',
      'userType': 'Turista/Transeunte',
    },
    {
      'userName': 'Inacio 4e20',
      'username': 'Inacio_4e20',
      'userType': 'Turista/Transeunte',
    },
  ];

  // ✅ INICIAR INTERAÇÕES FAKE NO RANKING
  static void startFakeRankingInteractions() {
    if (_fakeInteractionsStarted) return;

    _fakeInteractionsStarted = true;
    _currentFakeUserIndex = 0;

    print('🏆 Iniciando interações fake no ranking...');

    // Primeira interação após 2 minutos (mesmo tempo da comunidade)
    Future.delayed(const Duration(minutes: 2), () {
      _addNextFakeRankingInteraction();
    });
  }

  // ✅ ADICIONAR PRÓXIMA INTERAÇÃO FAKE NO RANKING
  static void _addNextFakeRankingInteraction() {
    if (_currentFakeUserIndex >= _fakeRankingUsers.length) {
      print('🏆 Todas as interações fake no ranking foram adicionadas');
      return;
    }

    final fakeUser = _fakeRankingUsers[_currentFakeUserIndex];

    // Adiciona o usuário fake no ranking
    //RankingService.addFakeUserToRanking(
    //userName: fakeUser['userName'] as String,
    //username: fakeUser['username'] as String,
    //userType: fakeUser['userType'] as String,
    //);

    print('🏆 Usuário fake adicionado ao ranking: ${fakeUser['username']}');

    _currentFakeUserIndex++;

    // Agenda próxima interação se ainda houver (15 segundos entre cada)
    if (_currentFakeUserIndex < _fakeRankingUsers.length) {
      Future.delayed(const Duration(seconds: 15), () {
        _addNextFakeRankingInteraction();
      });
    }
  }

  // ✅ PARAR INTERAÇÕES FAKE
  static void stopFakeRankingInteractions() {
    _fakeInteractionsStarted = false;
    _currentFakeUserIndex = 0;
    print('🏆 Interações fake no ranking paradas');
  }

  // ✅ REINICIAR INTERAÇÕES FAKE
  static void resetFakeRankingInteractions() {
    _fakeInteractionsStarted = false;
    _currentFakeUserIndex = 0;
    //RankingService.clearFakeUsers();
    print('🏆 Interações fake no ranking resetadas');
  }
}
