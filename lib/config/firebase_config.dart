// lib/config/firebase_config.dart
class FirebaseConfig {
  static bool isInitialized = false;
  static String? projectId;
  static String? apiKey;
  static String? authDomain;

  // Métodos estáticos para acesso às configurações
  static bool get isFirebaseReady => isInitialized;

  static String? get currentProjectId => projectId;
  static String? get currentApiKey => apiKey;
  static String? get currentAuthDomain => authDomain;

  // Configurações padrão de fallback
  static const String fallbackProjectId = "clima-interativo-d91af";
  static const String fallbackApiKey =
      "AIzaSyC4L6O5v9YQhJ7Y8X2W3Z4X5Y6Z7A8B9C0D";
  static const String fallbackAuthDomain =
      "clima-interativo-d91af.firebaseapp.com";
}
