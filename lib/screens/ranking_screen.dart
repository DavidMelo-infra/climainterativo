import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/ranking_service.dart';
import '../models/ranking_model.dart';
import '../utils/constants.dart';
import '../utils/widgets.dart';
import 'rewards_screen.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  UserRanking? _userRanking;
  final List<UserRanking> _globalRanking = [];
  StreamSubscription? _userRankingSubscription;
  StreamSubscription? _globalRankingSubscription;
  bool _isLoading = true;
  bool _hasUser = false;

  @override
  void initState() {
    super.initState();
    _initializeRankingData();
  }

  @override
  void dispose() {
    _userRankingSubscription?.cancel();
    _globalRankingSubscription?.cancel();
    super.dispose();
  }

  void _initializeRankingData() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // Usuário não logado - mostra mensagem
      if (mounted) {
        setState(() {
          _hasUser = false;
          _isLoading = false;
        });
      }
      return;
    }

    // ✅ USUÁRIO LOGADO - Carrega dados
    _hasUser = true;

    // ✅ PRIMEIRO: Carrega ranking do usuário com método DEFINITIVO
    RankingService.getCurrentUserRankingDefinitive().then((userRanking) {
      if (mounted) {
        setState(() {
          _userRanking = userRanking;
        });
      }
    }).catchError((error) {
      print('❌ Erro ao carregar ranking do usuário: $error');
    });

    // ✅ SEGUNDO: Configura stream para atualizações em tempo real
    _userRankingSubscription =
        RankingService.getCurrentUserRankingStream(user.uid)
            .listen((userRanking) {
      if (mounted) {
        setState(() {
          _userRanking = userRanking;
        });
      }
    });

    // ✅ TERCEIRO: Carrega ranking global
    _loadGlobalRanking();

    // ✅ QUARTO: Configura stream do ranking global
    _globalRankingSubscription =
        RankingService.getGlobalRankingStream().listen((globalRanking) {
      if (mounted) {
        setState(() {
          _globalRanking.clear();
          _globalRanking.addAll(globalRanking);
          _isLoading = false;
        });
      }
    });
  }

  void _loadGlobalRanking() async {
    try {
      final globalRanking = await RankingService.getGlobalRanking();
      if (mounted) {
        setState(() {
          _globalRanking.clear();
          _globalRanking.addAll(globalRanking);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Erro ao carregar ranking global: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ✅ MÉTODO AUXILIAR: Lógica plural/singular
  String _getPointsText(int points) {
    return points == 1 ? 'ponto' : 'pontos';
  }

  String _getInteractionsText(int interactions) {
    return interactions == 1 ? 'interação' : 'interações';
  }

  String _getDaysText(int days) {
    return days == 1 ? 'dia' : 'dias';
  }

  Widget _buildLevelBadge(String level, String emoji, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(
            level,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserStats() {
    // ✅ VERIFICA SE USUÁRIO NÃO ESTÁ LOGADO
    if (!_hasUser) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: kPrimaryColor.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.person_outline, size: 48, color: Color(0xFF6B7280)),
              SizedBox(height: 12),
              Text(
                'Faça login para ver\nseu progresso!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ✅ USUÁRIO LOGADO MAS AINDA CARREGANDO
    if (_userRanking == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: kPrimaryColor.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Column(
            children: [
              CircularProgressIndicator(color: kPrimaryColor),
              SizedBox(height: 12),
              Text(
                'Carregando seu progresso...',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ✅ USUÁRIO LOGADO COM DADOS CARREGADOS
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: kPrimaryColor.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _userRanking!.userName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_userRanking!.totalPoints} ${_getPointsText(_userRanking!.totalPoints)}',
                    style: TextStyle(
                      fontSize: 16,
                      color: kPrimaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              _buildLevelBadge(
                _userRanking!.levelName,
                _userRanking!.levelEmoji,
                _getLevelColor(_userRanking!.currentLevel),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 1,
            color: kPrimaryColor.withOpacity(0.1),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Dias Consecutivos',
                '${_userRanking!.consecutiveDays} ${_getDaysText(_userRanking!.consecutiveDays)}',
                Icons.calendar_today,
              ),
              _buildStatItem(
                'Interações',
                '${_userRanking!.interactions.length} ${_getInteractionsText(_userRanking!.interactions.length)}',
                Icons.assignment,
              ),
              _buildStatItem(
                'Próximo Nível',
                _userRanking!.pointsToNextLevel > 0
                    ? '${_userRanking!.pointsToNextLevel} ${_getPointsText(_userRanking!.pointsToNextLevel)}'
                    : 'Máx',
                Icons.trending_up,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: kPrimaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: kPrimaryColor),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Color _getLevelColor(int level) {
    switch (level) {
      case 0:
        return const Color(0xFFCD7F32);
      case 1:
        return const Color(0xFFC0C0C0);
      case 2:
        return const Color(0xFFFFD700);
      case 3:
        return const Color(0xFFE5E4E2);
      default:
        return kPrimaryColor;
    }
  }

  Widget _buildRankingList() {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: kPrimaryColor.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Column(
          children: [
            CircularProgressIndicator(color: kPrimaryColor),
            SizedBox(height: 16),
            Text(
              'Carregando ranking...',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      );
    }

    if (_globalRanking.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: kPrimaryColor.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(Icons.emoji_events,
                size: 64, color: kPrimaryColor.withOpacity(0.3)),
            const SizedBox(height: 16),
            const Text(
              'Ranking Vazio',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Seja o primeiro a registrar climas\n e aparecer no ranking!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _globalRanking.length,
        itemBuilder: (context, index) {
          final user = _globalRanking[index];
          final isCurrentUser = user.userId == _userRanking?.userId;

          return Container(
            margin: const EdgeInsets.only(bottom: 1),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isCurrentUser
                  ? kPrimaryColor.withOpacity(0.05)
                  : Colors.white,
              borderRadius: index == 0
                  ? const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    )
                  : index == _globalRanking.length - 1
                      ? const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        )
                      : BorderRadius.zero,
              border: isCurrentUser
                  ? Border.all(color: kPrimaryColor.withOpacity(0.3))
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _getRankColor(index),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: index < 3 ? Colors.white : kPrimaryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  user.levelEmoji,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.userName,
                        style: TextStyle(
                          fontWeight:
                              isCurrentUser ? FontWeight.bold : FontWeight.w600,
                          color: const Color(0xFF1F2937),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${user.totalPoints} ${_getPointsText(user.totalPoints)} • ${user.levelName}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                if (index < 3)
                  Text(
                    ['🥇', '🥈', '🥉'][index],
                    style: const TextStyle(fontSize: 24),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getRankColor(int index) {
    switch (index) {
      case 0:
        return const Color(0xFFFFD700); // Ouro
      case 1:
        return const Color(0xFFC0C0C0); // Prata
      case 2:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return kPrimaryColor.withOpacity(0.1);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              // Header fixo
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Meu Progresso',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildUserStats(),

                    // ✅ BOTÃO DE RECOMPENSAS PREMIUM
                    const SizedBox(height: 16),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF6B35).withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const RewardsScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          minimumSize: const Size(double.infinity, 60),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.card_giftcard, size: 24),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'RESGATAR RECOMPENSAS',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    'Troque seus pontos por prêmios',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFFF0F0F0),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Ranking Global',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
              ),

              // ✅ LISTA COM SCROLL COMPLETO
              Expanded(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildRankingList(),
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
