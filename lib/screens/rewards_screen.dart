import 'package:flutter/material.dart';
import '../models/reward_model.dart';
import '../services/ranking_service.dart';
import '../utils/constants.dart';
import '../utils/widgets.dart';
import '../services/auth_service.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  final List<Reward> _rewards = [
    Reward(
      id: '1',
      title: '1 Mês Metflix',
      description: 'Assinatura básica por 1 mês - Para novos usuários',
      pointsRequired: 1000,
      iconPath: 'assets/rewards/netflix.png',
      storeName: 'Metflix',
      voucherCode: 'METFLIX200',
    ),
    Reward(
      id: '2',
      title: 'McOferta Especial',
      description: 'Big Mac + Batata Média + Refri - Apenas R\$ 15,90',
      pointsRequired: 300,
      iconPath: 'assets/rewards/mcdonalds.png',
      storeName: 'MeEngorda\'s',
      voucherCode: 'MEENGORDA80',
    ),
    Reward(
      id: '3',
      title: 'Spotfail Premium',
      description: '1 mês de Spotfail Premium sem anúncios',
      pointsRequired: 800,
      iconPath: 'assets/rewards/spotify.png',
      storeName: 'Spotfail',
      voucherCode: 'SPOTFAIL150',
    ),
    Reward(
      id: '4',
      title: '10% Off Minotauro',
      description: 'Desconto de 10% em qualquer produto esportivo',
      pointsRequired: 350,
      iconPath: 'assets/rewards/centauro.png',
      storeName: 'Minotauro',
      voucherCode: 'MINOTAURO10',
    ),
  ];

  int _userPoints = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserPoints();
  }

  void _loadUserPoints() async {
    try {
      print('🔍 Carregando pontos do usuário...');
      // Primeiro verifica se o usuário está autenticado
      final currentUser = await AuthService.getCurrentUser();
      if (currentUser == null) {
        print('❌ Usuário não autenticado');
        if (mounted) {
          setState(() {
            _userPoints = 0;
            _isLoading = false;
          });
        }
        return;
      }
      print('✅ Usuário autenticado: ${currentUser.email}');
      // Agora carrega os pontos do ranking
      final userRanking = await RankingService.getCurrentUserRanking();
      print('🔍 Resultado do RankingService: $userRanking');
      if (mounted) {
        setState(() {
          if (userRanking != null) {
            _userPoints = userRanking.totalPoints;
            print('✅ Pontos carregados: $_userPoints');
          } else {
            _userPoints = 0;
            print('⚠️ Ranking não encontrado, pontos definidos como 0');
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Erro ao carregar pontos: $e');
      if (mounted) {
        setState(() {
          _userPoints = 0;
          _isLoading = false;
        });
      }
    }
  }

  void _showRewardDetails(Reward reward) {
    final canRedeem = _userPoints >= reward.pointsRequired;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ícone da loja - MAIOR E MAIS DESTAQUE
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      reward.iconPath,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: kPrimaryColor.withOpacity(0.1),
                          child: Icon(
                            Icons.store,
                            size: 60,
                            color: kPrimaryColor,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  reward.storeName.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  reward.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4B5563),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  reward.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: canRedeem
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: canRedeem ? Colors.green : Colors.orange,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${reward.pointsRequired} PONTOS',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: canRedeem ? Colors.green : Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        canRedeem
                            ? 'Você pode resgatar!'
                            : 'Pontos necessários',
                        style: TextStyle(
                          fontSize: 14,
                          color: canRedeem ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF6B7280),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Voltar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: canRedeem
                            ? () {
                                _showRedeemConfirmation(reward);
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              canRedeem ? kSecondaryColor : Colors.grey,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          canRedeem
                              ? 'RESGATAR PRÊMIO >'
                              : 'Pontos Insuficientes',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRedeemConfirmation(Reward reward) {
    Navigator.of(context).pop(); // Fecha o dialog anterior
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.celebration,
                  size: 64,
                  color: Colors.green,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Parabéns! 🎉',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Você resgatou: ${reward.title}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Na loja: ${reward.storeName}',
                  style: TextStyle(
                    fontSize: 14,
                    color: kPrimaryColor,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kPrimaryColor),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Código do Voucher:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        reward.voucherCode,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Apresente este código na loja para resgatar seu benefício',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  '⚠️ Esta é uma demonstração visual.\nEm uma versão futura, esta função será totalmente integrada.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      setState(() {
                        _userPoints -= reward.pointsRequired;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Entendi - Fechar',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRewardCard(Reward reward) {
    final canRedeem = _userPoints >= reward.pointsRequired;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: canRedeem ? kSecondaryColor : const Color(0xFFE5E7EB),
              width: canRedeem ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // IMAGEM GRANDE E RETANGULAR - ESTILO NETFLIX
              Container(
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  color: kPrimaryColor.withOpacity(0.05),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: Image.asset(
                    reward.iconPath,
                    width: double.infinity,
                    height: 140,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: kPrimaryColor.withOpacity(0.1),
                        child: Icon(
                          Icons.store,
                          size: 60,
                          color: kPrimaryColor,
                        ),
                      );
                    },
                  ),
                ),
              ),
              // CONTEÚDO DO CARD
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // NOME DA LOJA
                    Text(
                      reward.storeName.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6B7280),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // TÍTULO DO PRÊMIO
                    Text(
                      reward.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // DESCRIÇÃO
                    Text(
                      reward.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // PONTOS E BOTÃO
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: canRedeem
                            ? Colors.green.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${reward.pointsRequired} pontos',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: canRedeem ? Colors.green : Colors.grey,
                                ),
                              ),
                              Text(
                                canRedeem ? 'Disponível' : 'Pontos necessários',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: canRedeem ? Colors.green : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          ElevatedButton(
                            onPressed: () => _showRewardDetails(reward),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  canRedeem ? kSecondaryColor : Colors.grey,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: Text(
                              canRedeem ? 'RESGATAR >' : 'Visualizar',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recompensas e Vouchers'),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8FAFC), Color(0xFFEFF6FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            // Header com pontos do usuário
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Seus Pontos Disponíveis',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _isLoading
                      ? const CircularProgressIndicator(color: kPrimaryColor)
                      : Text(
                          '$_userPoints',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: kPrimaryColor,
                          ),
                        ),
                  const SizedBox(height: 4),
                  Text(
                    'Continue registrando climas para ganhar mais pontos!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: kPrimaryColor.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Lista de recompensas
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: kPrimaryColor),
                      )
                    : ListView.separated(
                        itemCount: _rewards.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          return _buildRewardCard(_rewards[index]);
                        },
                      ),
              ),
            ),
            // Footer informativo
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.orange.withOpacity(0.1),
              child: const Text(
                '💡 Esta é uma demonstração visual. Os vouchers serão ativados em breve!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
