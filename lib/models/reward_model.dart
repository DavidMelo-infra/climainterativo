// ARQUIVO: lib/models/reward_model.dart
class Reward {
  final String id;
  final String title;
  final String description;
  final int pointsRequired;
  final String iconPath; // Caminho da imagem/ícone da loja
  final String storeName;
  final String voucherCode; // Código do voucher (para versão futura)
  final bool isAvailable;

  const Reward({
    required this.id,
    required this.title,
    required this.description,
    required this.pointsRequired,
    required this.iconPath,
    required this.storeName,
    required this.voucherCode,
    this.isAvailable = true,
  });
}
