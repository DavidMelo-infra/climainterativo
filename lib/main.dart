import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'screens/splash_screen.dart';
import 'screens/register_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/ranking_screen.dart';
import 'screens/community_screen.dart';
import 'screens/main_app_screen.dart';
import 'screens/rewards_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_selection_screen.dart';
import 'screens/forgot_password_screen.dart'; // ← ADICIONADO

import 'utils/constants.dart';
import 'services/auth_service.dart';
import 'firebase_options.dart';
import 'config/firebase_config.dart';

// Função principal de inicialização
Future<void> main() async {
  print("🎯 INICIANDO CLIMA INTERATIVO...");

  // CRÍTICO: Garantir bindings do Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ DETECÇÃO DE DOMÍNIO (APENAS WEB)
  if (kIsWeb) {
    print("🌐 EXECUTANDO NO MODO WEB");
    print("📍 URL COMPLETA: ${Uri.base}");
    print("🔍 DOMÍNIO: ${Uri.base.host}");
    print("🚪 PORTA: ${Uri.base.port}");
    print("📋 CAMINHO: ${Uri.base.path}");
  }

  // ✅ INICIALIZAR FIREBASE PRIMEIRO
  print("🔥 CONFIGURANDO FIREBASE...");
  try {
    // INICIALIZAÇÃO COM CONFIGURAÇÕES ESPECÍFICAS
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // ✅ AGORA USANDO A CLASSE DE CONFIGURAÇÃO
    FirebaseConfig.isInitialized = true;
    FirebaseConfig.projectId = DefaultFirebaseOptions.currentPlatform.projectId;
    FirebaseConfig.apiKey = DefaultFirebaseOptions.currentPlatform.apiKey;
    FirebaseConfig.authDomain =
        DefaultFirebaseOptions.currentPlatform.authDomain ??
            'clima-interativo-d91af.firebaseapp.com';

    print("✅ FIREBASE CONECTADO COM SUCESSO!");
    print("📍 Projeto: ${FirebaseConfig.projectId}");
    print("🔑 Web App ID: 1:368017908513:web:fb7b45f33e86925bfc1460");

    // ✅ DETALHES DA CONEXÃO FIREBASE (APENAS WEB)
    if (kIsWeb) {
      final auth = FirebaseAuth.instance;
      print("🔧 FIREBASE CONFIG WEB:");
      print(" 🆔 App: ${auth.app.name}");
      print(" 🔑 API Key: ${FirebaseConfig.apiKey?.substring(0, 25)}...");
      print(" 📦 Project: ${FirebaseConfig.projectId}");
      if (FirebaseConfig.authDomain != null) {
        print(" 🌐 Auth Domain: ${FirebaseConfig.authDomain}");
      }
    }

    // ✅ TESTE RÁPIDO DO FIREBASE AUTH
    print("🔐 TESTANDO FIREBASE AUTH...");
    final currentUser = FirebaseAuth.instance.currentUser;
    print("👤 USUÁRIO ATUAL: ${currentUser?.email ?? 'Nenhum'}");
  } catch (e) {
    print("❌ FALHA NO FIREBASE: $e");
    FirebaseConfig.isInitialized = false;
  }

  // Tenta restaurar a sessão do usuário
  print("🔐 VERIFICANDO SESSÃO DO USUÁRIO...");
  final bool isLoggedIn = FirebaseConfig.isInitialized
      ? await AuthService.initializeUserSession()
      : false;
  print("📱 STATUS DO LOGIN: $isLoggedIn");

  // Define a rota inicial
  final String initialRoute = isLoggedIn ? homeRoute : splashRoute;
  print("🔄 ROTA INICIAL: $initialRoute");

  // Roda o app
  print("🚀 INICIANDO APLICATIVO...");
  runApp(MyApp(initialRouteOverride: initialRoute));
}

class MyApp extends StatelessWidget {
  final String initialRouteOverride;

  const MyApp({super.key, required this.initialRouteOverride});

  // ✅ GETTER ADICIONADO PARA profileSelectionRoute
  String get profileSelectionRoute => '/profile-selection';

  @override
  Widget build(BuildContext context) {
    print("🎨 CONSTRUINDO INTERFACE...");

    return MaterialApp(
      title: 'Clima Interativo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Inter',
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute:
          FirebaseConfig.isInitialized ? initialRouteOverride : '/error',
      routes: {
        splashRoute: (context) => const SplashScreen(),
        loginRoute: (context) => LoginScreen(
              registerRoute: registerRoute,
              homeRoute: homeRoute,
            ),
        registerRoute: (context) => const RegisterScreen(
              loginRoute: loginRoute,
            ),
        // 🎯 NOVA ROTA ADICIONADA: /profile-selection
        profileSelectionRoute: (context) => const ProfileSelectionScreen(),
        profileRoute: (context) => const ProfileScreen(),
        // ✅ CORRIGIDO - removido loginRoute
        homeRoute: (context) => const MainAppScreen(),
        // ✅ CORRIGIDO - removido loginRoute
        rankingRoute: (context) => const RankingScreen(),
        communityRoute: (context) => const CommunityScreen(),
        rewardsRoute: (context) => const RewardsScreen(),
        '/forgot-password': (context) =>
            const ForgotPasswordScreen(), // ← NOVA ROTA ADICIONADA
        '/error': (context) => _buildErrorScreen(),
      },
      onUnknownRoute: (settings) {
        print("⚠️ Rota não encontrada: ${settings.name}");
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            body: Center(
              child: Text('Página não encontrada: ${settings.name}'),
            ),
          ),
        );
      },
    );
  }

  // 👈 MÉTODO ADICIONADO: TELA DE ERRO DO FIREBASE
  Widget _buildErrorScreen() {
    // Definindo as constantes de cor localmente para compilação
    const Color kGradientStart = Color(0xFF4A90E2);
    const Color kGradientMiddle = Color(0xFF50BFE6);
    const Color kGradientEnd = Color(0xFF63C6D5);
    const Color kPrimaryColor = Color(0xFF4A90E2);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [kGradientStart, kGradientMiddle, kGradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 64),
                const SizedBox(height: 20),
                const Text(
                  'Configuração do Firebase',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'O Firebase não foi inicializado corretamente.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Verifique sua conexão e configurações do Firebase.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white60,
                  ),
                ),
                const SizedBox(height: 25),
                ElevatedButton(
                  onPressed: () {
                    // Tentar reinicializar o app
                    main();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: kPrimaryColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Tentar Novamente'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
