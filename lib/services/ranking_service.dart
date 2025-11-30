import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/ranking_model.dart';

class RankingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _collectionName = 'rankings';

  // ✅ SISTEMA DE PONTOS FIXOS POR AÇÃO
  static const int POINTS_BUTTON_CLICK =
      1; // 1 ponto por clicar no botão de tempo
  static const int POINTS_PHOTO_UPLOAD = 4; // 4 pontos por tirar foto

  // ✅ MÉTODO DEFINITIVO: Sempre retorna UserRanking (cria se não existir)
  static Future<UserRanking> getCurrentUserRankingDefinitive() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não está autenticado');
    }
    try {
      final doc =
          await _firestore.collection(_collectionName).doc(user.uid).get();
      if (doc.exists) {
        return _userRankingFromFirestore(doc);
      } else {
        // ✅ SEMPRE cria ranking se não existir
        return await _createUserRanking(
            user.uid, user.displayName ?? 'Usuário');
      }
    } catch (e) {
      print('❌ Erro crítico ao buscar ranking: $e');
      // ✅ FALLBACK: cria ranking mesmo com erro
      return await _createUserRanking(user.uid, user.displayName ?? 'Usuário');
    }
  }

  // ✅ MÉTODO: Registrar clique no botão de tempo (1 PONTO)
  static Future<Map<String, dynamic>> registerWeatherButtonClick() async {
    final user = _auth.currentUser;
    if (user == null) {
      return {'success': false, 'message': 'Usuário não logado'};
    }
    try {
      final userRanking = await getCurrentUserRankingDefinitive();
      final now = DateTime.now();

      // VERIFICAR LIMITE DE 3 INTERAÇÕES POR DIA (8h em 8h)
      final todayInteractions = userRanking.interactions.where((interaction) {
        final interactionDate = DateTime(
          interaction.date.year,
          interaction.date.month,
          interaction.date.day,
        );
        final today = DateTime(now.year, now.month, now.day);
        return interactionDate == today;
      }).toList();

      // Limite de 3 interações por dia
      if (todayInteractions.length >= 3) {
        return {
          'success': false,
          'message': 'Limite de 3 interações por dia atingido!'
        };
      }

      // Verificar slot de 8h atual
      final currentSlot = _getCurrentTimeSlot(now);
      final hasInteractedInSlot = todayInteractions.any((interaction) {
        return _getCurrentTimeSlot(interaction.date) == currentSlot;
      });

      if (hasInteractedInSlot) {
        return {
          'success': false,
          'message':
              'Você já registrou o clima neste período (${_getSlotName(currentSlot)})!'
        };
      }

      // ✅ PONTOS FIXOS: 1 PONTO POR CLIQUE NO BOTÃO
      int basePoints = POINTS_BUTTON_CLICK;
      bool isConsecutive = _checkConsecutiveDays(userRanking, now);
      int consecutiveBonus = isConsecutive
          ? _calculateConsecutiveBonus(userRanking.consecutiveDays + 1)
          : 0;
      int totalPoints = basePoints + consecutiveBonus;

      print(
          '🎯 BOTÃO CLIMÁTICO: $basePoints (base) + $consecutiveBonus (bonus) = $totalPoints pontos');

      // Cria nova interação
      final newInteraction = WeatherInteraction(
        date: now,
        userWeatherStatus: 'Botão Climático',
        apiWeatherStatus: 'Ação Registrada',
        points: totalPoints,
        isConsecutiveDay: isConsecutive,
      );

      // Atualiza ranking
      userRanking.interactions.add(newInteraction);
      userRanking.totalPoints += totalPoints;
      if (isConsecutive) {
        userRanking.consecutiveDays++;
      } else {
        userRanking.consecutiveDays = 1;
      }
      userRanking.currentLevel = _calculateLevel(userRanking.totalPoints);

      final monthKey = '${now.year}-${now.month}';
      userRanking.monthlyPoints[monthKey] =
          (userRanking.monthlyPoints[monthKey] ?? 0) + totalPoints;

      // ✅ SALVA NO FIRESTORE
      await _firestore.collection(_collectionName).doc(user.uid).set(
            _userRankingToFirestore(userRanking),
            SetOptions(merge: true),
          );

      return {
        'success': true,
        'points': totalPoints,
        'basePoints': basePoints,
        'bonusPoints': consecutiveBonus,
        'consecutiveDays': userRanking.consecutiveDays,
        'totalPoints': userRanking.totalPoints,
        'level': userRanking.levelName,
        'timeSlot': _getSlotName(currentSlot),
        'action': 'button_click',
      };
    } catch (e) {
      print('❌ Erro ao registrar clique: $e');
      return {'success': false, 'message': 'Erro ao salvar no servidor'};
    }
  }

  // ✅ MÉTODO: Registrar upload de foto (4 PONTOS)
  static Future<Map<String, dynamic>> registerPhotoUpload() async {
    final user = _auth.currentUser;
    if (user == null) {
      return {'success': false, 'message': 'Usuário não logado'};
    }
    try {
      final userRanking = await getCurrentUserRankingDefinitive();
      final now = DateTime.now();

      // VERIFICAR LIMITE DE 3 INTERAÇÕES POR DIA (8h em 8h)
      final todayInteractions = userRanking.interactions.where((interaction) {
        final interactionDate = DateTime(
          interaction.date.year,
          interaction.date.month,
          interaction.date.day,
        );
        final today = DateTime(now.year, now.month, now.day);
        return interactionDate == today;
      }).toList();

      // Limite de 3 interações por dia
      if (todayInteractions.length >= 3) {
        return {
          'success': false,
          'message': 'Limite de 3 interações por dia atingido!'
        };
      }

      // Verificar slot de 8h atual
      final currentSlot = _getCurrentTimeSlot(now);
      final hasInteractedInSlot = todayInteractions.any((interaction) {
        return _getCurrentTimeSlot(interaction.date) == currentSlot;
      });

      if (hasInteractedInSlot) {
        return {
          'success': false,
          'message':
              'Você já registrou o clima neste período (${_getSlotName(currentSlot)})!'
        };
      }

      // ✅ PONTOS FIXOS: 4 PONTOS POR FOTO
      int basePoints = POINTS_PHOTO_UPLOAD;
      bool isConsecutive = _checkConsecutiveDays(userRanking, now);
      int consecutiveBonus = isConsecutive
          ? _calculateConsecutiveBonus(userRanking.consecutiveDays + 1)
          : 0;
      int totalPoints = basePoints + consecutiveBonus;

      print(
          '📸 FOTO UPLOAD: $basePoints (base) + $consecutiveBonus (bonus) = $totalPoints pontos');

      // Cria nova interação
      final newInteraction = WeatherInteraction(
        date: now,
        userWeatherStatus: 'Foto do Clima',
        apiWeatherStatus: 'Foto Registrada',
        points: totalPoints,
        isConsecutiveDay: isConsecutive,
      );

      // Atualiza ranking
      userRanking.interactions.add(newInteraction);
      userRanking.totalPoints += totalPoints;
      if (isConsecutive) {
        userRanking.consecutiveDays++;
      } else {
        userRanking.consecutiveDays = 1;
      }
      userRanking.currentLevel = _calculateLevel(userRanking.totalPoints);

      final monthKey = '${now.year}-${now.month}';
      userRanking.monthlyPoints[monthKey] =
          (userRanking.monthlyPoints[monthKey] ?? 0) + totalPoints;

      // ✅ SALVA NO FIRESTORE
      await _firestore.collection(_collectionName).doc(user.uid).set(
            _userRankingToFirestore(userRanking),
            SetOptions(merge: true),
          );

      return {
        'success': true,
        'points': totalPoints,
        'basePoints': basePoints,
        'bonusPoints': consecutiveBonus,
        'consecutiveDays': userRanking.consecutiveDays,
        'totalPoints': userRanking.totalPoints,
        'level': userRanking.levelName,
        'timeSlot': _getSlotName(currentSlot),
        'action': 'photo_upload',
      };
    } catch (e) {
      print('❌ Erro ao registrar foto: $e');
      return {'success': false, 'message': 'Erro ao salvar no servidor'};
    }
  }

  // ✅ MÉTODO: Obter ranking do usuário atual do Firestore (mantido para compatibilidade)
  static Future<UserRanking?> getCurrentUserRanking() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    try {
      final doc =
          await _firestore.collection(_collectionName).doc(user.uid).get();
      if (doc.exists) {
        return _userRankingFromFirestore(doc);
      } else {
        // Cria novo ranking se não existir
        return await _createUserRanking(
            user.uid, user.displayName ?? 'Usuário');
      }
    } catch (e) {
      print('❌ Erro ao buscar ranking: $e');
      return null;
    }
  }

  // ✅ MÉTODO: Criar ranking inicial para usuário
  static Future<UserRanking> _createUserRanking(
      String userId, String userName) async {
    final newRanking = UserRanking(
      userId: userId,
      userName: userName,
      totalPoints: 0,
      currentLevel: 0,
      consecutiveDays: 0,
      interactions: [],
      monthlyPoints: {},
    );
    await _firestore
        .collection(_collectionName)
        .doc(userId)
        .set(_userRankingToFirestore(newRanking));
    return newRanking;
  }

  // ✅ MÉTODO: Obter ranking global do Firestore
  static Future<List<UserRanking>> getGlobalRanking() async {
    try {
      final query = await _firestore
          .collection(_collectionName)
          .orderBy('totalPoints', descending: true)
          .limit(50)
          .get();
      return query.docs.map((doc) => _userRankingFromFirestore(doc)).toList();
    } catch (e) {
      print('❌ Erro ao buscar ranking global: $e');
      return [];
    }
  }

  // ✅ MÉTODOS AUXILIARES
  static int _calculateConsecutiveBonus(int consecutiveDays) {
    if (consecutiveDays >= 15) return 10;
    if (consecutiveDays >= 7) return 5;
    if (consecutiveDays >= 3) return 2;
    return 0;
  }

  static bool _checkConsecutiveDays(UserRanking ranking, DateTime today) {
    if (ranking.interactions.isEmpty) return false;
    final yesterday = today.subtract(const Duration(days: 1));
    final lastInteraction = ranking.interactions.last;
    final lastInteractionDate = DateTime(
      lastInteraction.date.year,
      lastInteraction.date.month,
      lastInteraction.date.day,
    );
    return lastInteractionDate == yesterday;
  }

  static int _calculateLevel(int totalPoints) {
    if (totalPoints >= 101) return 3;
    if (totalPoints >= 51) return 2;
    if (totalPoints >= 21) return 1;
    return 0;
  }

  static int _getCurrentTimeSlot(DateTime dateTime) {
    final hour = dateTime.hour;
    if (hour >= 0 && hour < 8) return 0;
    if (hour >= 8 && hour < 16) return 1;
    return 2;
  }

  static String _getSlotName(int slot) {
    switch (slot) {
      case 0:
        return 'Manhã (00h-08h)';
      case 1:
        return 'Tarde (08h-16h)';
      case 2:
        return 'Noite (16h-00h)';
      default:
        return 'Período';
    }
  }

  // ✅ CONVERSÃO: UserRanking para Firestore
  static Map<String, dynamic> _userRankingToFirestore(UserRanking ranking) {
    return {
      'userId': ranking.userId,
      'userName': ranking.userName,
      'totalPoints': ranking.totalPoints,
      'currentLevel': ranking.currentLevel,
      'consecutiveDays': ranking.consecutiveDays,
      'interactions': ranking.interactions
          .map((interaction) => {
                'date': interaction.date.millisecondsSinceEpoch,
                'userWeatherStatus': interaction.userWeatherStatus,
                'apiWeatherStatus': interaction.apiWeatherStatus,
                'points': interaction.points,
                'isConsecutiveDay': interaction.isConsecutiveDay,
              })
          .toList(),
      'monthlyPoints': ranking.monthlyPoints,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }

  // ✅ CONVERSÃO: Firestore para UserRanking
  static UserRanking _userRankingFromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserRanking(
      userId: data['userId'] ?? doc.id,
      userName: data['userName'] ?? 'Usuário',
      totalPoints: data['totalPoints'] ?? 0,
      currentLevel: data['currentLevel'] ?? 0,
      consecutiveDays: data['consecutiveDays'] ?? 0,
      interactions: _parseInteractions(data['interactions']),
      monthlyPoints: _parseMonthlyPoints(data['monthlyPoints']),
    );
  }

  static List<WeatherInteraction> _parseInteractions(dynamic interactionsData) {
    if (interactionsData is! List) return [];
    return interactionsData.map((item) {
      return WeatherInteraction(
        date: DateTime.fromMillisecondsSinceEpoch(item['date'] ?? 0),
        userWeatherStatus: item['userWeatherStatus'] ?? '',
        apiWeatherStatus: item['apiWeatherStatus'],
        points: item['points'] ?? 0,
        isConsecutiveDay: item['isConsecutiveDay'] ?? false,
      );
    }).toList();
  }

  static Map<String, int> _parseMonthlyPoints(dynamic monthlyPointsData) {
    if (monthlyPointsData is! Map) return {};
    final Map<String, int> result = {};
    monthlyPointsData.forEach((key, value) {
      if (value is int) {
        result[key.toString()] = value;
      }
    });
    return result;
  }

  // ✅ STREAMS em tempo real
  static Stream<List<UserRanking>> getGlobalRankingStream() {
    return _firestore
        .collection(_collectionName)
        .orderBy('totalPoints', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(_userRankingFromFirestore).toList());
  }

  static Stream<UserRanking?> getCurrentUserRankingStream(String userId) {
    return _firestore.collection(_collectionName).doc(userId).snapshots().map(
        (snapshot) =>
            snapshot.exists ? _userRankingFromFirestore(snapshot) : null);
  }
}
