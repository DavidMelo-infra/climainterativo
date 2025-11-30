import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart' as app_model;
import 'local_storage_service.dart';
import '../config/firebase_config.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static bool _isFirebaseReady() {
    if (!FirebaseConfig.isInitialized) {
      print('❌ FIREBASE NÃO INICIALIZADO');
      return false;
    }
    return true;
  }

  // ✅ MÉTODO: Salvar usuário no Firestore
  static Future<void> _saveUserToFirestore(app_model.User user) async {
    try {
      await _firestore.collection('users').doc(user.id).set({
        'name': user.name,
        'username': user.username,
        'email': user.email,
        'user_type': user.userType,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      print('✅ USUÁRIO SALVO NO FIRESTORE: ${user.email}');
      print('✅ USERTYPE NO FIRESTORE: ${user.userType}');
    } catch (e) {
      print('❌ ERRO AO SALVAR NO FIRESTORE: $e');
    }
  }

  // ✅ MÉTODO: Buscar usuário do Firestore
  static Future<app_model.User?> _getUserFromFirestore(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data()!;
        print('✅ DADOS RECUPERADOS DO FIRESTORE: ${data['user_type']}');
        return app_model.User(
          id: userId,
          name: data['name'] ?? '',
          username: data['username'] ?? '',
          email: data['email'] ?? '',
          password: '', // Não salvar senha no Firestore
          userType: data['user_type'] ?? '',
        );
      }
      return null;
    } catch (e) {
      print('❌ ERRO AO BUSCAR DO FIRESTORE: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>> register(
    String name,
    String username,
    String email,
    String password,
    String userType,
  ) async {
    if (!_isFirebaseReady()) {
      return {'success': false, 'message': 'Firebase não configurado'};
    }
    try {
      print('🔹 REGISTER - Iniciando registro para: $email');
      print('🔹 REGISTER - UserType recebido: $userType');
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      final user = userCredential.user;
      if (user != null) {
        await user.updateDisplayName(name);
        final appUser = app_model.User(
            id: user.uid,
            name: name,
            username: username,
            email: email,
            password: '',
            userType: userType);
        // ✅ SALVA EM AMBOS: Local e Firestore
        await _saveUserData(appUser);
        await _saveUserToFirestore(appUser);
        print('✅ REGISTER - Usuário criado com sucesso!');
        print('✅ REGISTER - Tipo salvo: ${appUser.userType}');
        return {
          'success': true,
          'user': appUser.toMap(),
          'message': 'Conta criada com sucesso!'
        };
      }
      return {'success': false, 'message': 'Erro ao criar conta'};
    } on FirebaseAuthException catch (e) {
      String message = 'Erro ao criar conta';
      if (e.code == 'email-already-in-use')
        message = 'Email já está em uso';
      else if (e.code == 'weak-password')
        message = 'Senha muito fraca';
      else if (e.code == 'invalid-email') message = 'Email inválido';
      print('❌ REGISTER - Erro Firebase: $message');
      return {'success': false, 'message': message};
    } catch (e) {
      print('❌ REGISTER - Erro geral: $e');
      return {'success': false, 'message': 'Erro: $e'};
    }
  }

  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    if (!_isFirebaseReady())
      return {'success': false, 'message': 'Firebase não configurado'};
    try {
      print('🔹 LOGIN - Iniciando login para: $email');
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);
      final user = userCredential.user;
      if (user != null) {
        app_model.User appUser;
        // ✅ PRIMEIRO TENTA BUSCAR DO FIRESTORE
        final firestoreUser = await _getUserFromFirestore(user.uid);
        if (firestoreUser != null) {
          appUser = firestoreUser;
          print('✅ LOGIN - Dados carregados do Firestore');
        } else {
          // Fallback para dados locais
          final cachedUserBeforeLogin = await _getCachedUserData();
          if (cachedUserBeforeLogin != null &&
              cachedUserBeforeLogin['id'] == user.uid &&
              cachedUserBeforeLogin['user_type']?.isNotEmpty == true) {
            appUser = app_model.User.fromMap(cachedUserBeforeLogin);
            print('✅ LOGIN - Mantendo dados COMPLETOS do cache');
          } else {
            final existingUserType = cachedUserBeforeLogin?['user_type'] ?? '';
            appUser = app_model.User(
              id: user.uid,
              name: cachedUserBeforeLogin?['name'] ??
                  user.displayName ??
                  'Usuário',
              username: cachedUserBeforeLogin?['username'] ??
                  user.email!.split('@')[0],
              email: user.email!,
              password: '',
              userType: existingUserType,
            );
            print('⚠️ LOGIN - Criando usuário, userType: $existingUserType');
          }
        }
        print('✅ LOGIN - UserType FINAL: ${appUser.userType}');
        // ✅ ATUALIZA AMBOS: Local e Firestore
        await _saveUserData(appUser);
        await _saveUserToFirestore(appUser);
        return {
          'success': true,
          'user': appUser.toMap(),
          'needsProfile': appUser.userType.isEmpty
        };
      }
      return {'success': false, 'message': 'Erro ao fazer login'};
    } on FirebaseAuthException catch (e) {
      String message = 'Erro ao fazer login';
      if (e.code == 'user-not-found')
        message = 'Email não cadastrado';
      else if (e.code == 'wrong-password') message = 'Senha incorreta';
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'Erro: $e'};
    }
  }

  static Future<Map<String, dynamic>> loginWithGoogle() async {
    if (!_isFirebaseReady())
      return {'success': false, 'message': 'Firebase não configurado'};
    try {
      print("🔐 INICIANDO GOOGLE SIGN-IN...");
      if (kIsWeb) {
        final GoogleAuthProvider provider = GoogleAuthProvider();
        provider.addScope('email');
        final UserCredential userCredential =
            await _auth.signInWithPopup(provider);
        return await _processGoogleLogin(userCredential.user);
      } else {
        final GoogleSignIn googleSignIn =
            GoogleSignIn(scopes: ['email', 'profile']);
        await googleSignIn.signOut();
        print("📱 SOLICITANDO CONTA GOOGLE...");
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        if (googleUser == null)
          return {'success': false, 'message': 'Login cancelado'};
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);
        final UserCredential userCredential =
            await _auth.signInWithCredential(credential);
        return await _processGoogleLogin(userCredential.user);
      }
    } catch (e) {
      print("💥 ERRO NO LOGIN GOOGLE: $e");
      return {'success': false, 'message': 'Erro no login Google: $e'};
    }
  }

  static Future<Map<String, dynamic>> _processGoogleLogin(User? user) async {
    if (user == null)
      return {'success': false, 'message': 'Usuário não retornado'};
    // ✅ TENTA BUSCAR USUÁRIO EXISTENTE NO FIRESTORE
    final existingUser = await _getUserFromFirestore(user.uid);
    if (existingUser != null && existingUser.userType.isNotEmpty) {
      print('✅ LOGIN GOOGLE - Usuário existente encontrado no Firestore');
      await _saveUserData(existingUser);
      return {
        'success': true,
        'user': existingUser.toMap(),
        'needsProfile': false
      };
    }
    // ✅ SE NÃO EXISTIR, CRIA NOVO COM userType VAZIO
    final appUser = app_model.User(
        id: user.uid,
        name: user.displayName ?? 'Usuário Google',
        username: user.email!.split('@')[0],
        email: user.email!,
        password: '',
        userType: '');
    await _saveUserData(appUser);
    await _saveUserToFirestore(appUser);
    print("🎉 LOGIN GOOGLE COMPLETO: ${user.email}");
    return {'success': true, 'user': appUser.toMap(), 'needsProfile': true};
  }

  static Future<Map<String, dynamic>> updateUserProfile(String userType) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final currentUser = await getCurrentUser();
        if (currentUser == null) {
          return {'success': false, 'message': 'Usuário não encontrado'};
        }
        final updatedUser = currentUser.copyWith(userType: userType);
        print('🔹 UPDATE_USER_PROFILE - Atualizando userType para: $userType');
        // ✅ ATUALIZA EM AMBOS: Local e Firestore
        await _saveUserData(updatedUser);
        await _saveUserToFirestore(updatedUser);
        return {'success': true, 'user': updatedUser.toMap()};
      }
      return {'success': false, 'message': 'Usuário não encontrado'};
    } catch (e) {
      print('❌ ERRO NO UPDATE_USER_PROFILE: $e');
      return {'success': false, 'message': 'Erro ao atualizar perfil: $e'};
    }
  }

  static Future<app_model.User?> getCurrentUser() async {
    if (!_isFirebaseReady()) return null;
    final user = _auth.currentUser;
    if (user != null) {
      // ✅ PRIMEIRO TENTA BUSCAR DO FIRESTORE
      final firestoreUser = await _getUserFromFirestore(user.uid);
      if (firestoreUser != null && firestoreUser.userType.isNotEmpty) {
        print(
            '✅ GET_CURRENT_USER - Dados do Firestore: ${firestoreUser.userType}');
        return firestoreUser;
      }
      // ✅ FALLBACK PARA DADOS LOCAIS
      final cachedData = await _getCachedUserData();
      print('🔹 AuthService.getCurrentUser → cachedData: $cachedData');
      if (cachedData != null &&
          (cachedData['user_type'] == null ||
              cachedData['user_type'].isEmpty)) {
        print('🔧 REPARO URGENTE - user_type vazio detectado');
        await repairUserData();
        final repairedData = await _getCachedUserData();
        if (repairedData != null) {
          final repairedUser = app_model.User.fromMap(repairedData);
          print('✅ USUÁRIO REPARADO - UserType: ${repairedUser.userType}');
          return repairedUser;
        }
      }
      final currentUser = app_model.User(
        id: user.uid,
        name: cachedData?['name'] ?? user.displayName ?? 'Usuário',
        username:
            cachedData?['username'] ?? user.email!.split('@')[0] ?? 'user',
        email: user.email ?? '',
        password: '',
        userType: cachedData?['user_type'] ?? '',
      );
      print(
          '🔹 AuthService.getCurrentUser → userType: ${currentUser.userType}');
      return currentUser;
    }
    return null;
  }

  // ... (os outros métodos permanecem iguais: needsProfileSelection, _saveUserData, _getCachedUserData, logout, etc.)
  static Future<bool> needsProfileSelection() async {
    final user = await getCurrentUser();
    return user != null && user.userType.isEmpty;
  }

  static Future<void> _saveUserData(app_model.User user) async {
    try {
      final prefs = await LocalStorageService.getPrefs();
      final userMap = user.toMap();
      print('💾 SALVANDO DADOS LOCAIS:');
      print(' - Nome: ${user.name}');
      print(' - Email: ${user.email}');
      print(' - UserType: ${user.userType}');
      print(' - UserType no map: ${userMap['user_type']}');
      await prefs.setString('user_data', jsonEncode(userMap));
      print('✅ DADOS LOCAIS SALVOS COM SUCESSO!');
    } catch (e) {
      print('❌ ERRO AO SALVAR LOCAL: $e');
    }
  }

  static Future<Map<String, dynamic>?> _getCachedUserData() async {
    try {
      final prefs = await LocalStorageService.getPrefs();
      final userJson = prefs.getString('user_data');
      if (userJson != null) {
        final userMap = jsonDecode(userJson);
        if (userMap['user_type'] == null || userMap['user_type'].isEmpty) {
          if (userMap['userType'] != null && userMap['userType'].isNotEmpty) {
            print(
                '🔧 REPARANDO: userType encontrado em userType: ${userMap['userType']}');
            userMap['user_type'] = userMap['userType'];
            await prefs.setString('user_data', jsonEncode(userMap));
            print(
                '✅ DADOS REPARADOS - user_type agora: ${userMap['user_type']}');
          } else {
            print('⚠️ DADOS CORROMPIDOS - user_type está vazio');
          }
        }
        return userMap;
      }
    } catch (e) {
      print('❌ ERRO AO LER CACHE: $e');
    }
    return null;
  }

  static Future<void> logout() async {
    try {
      if (_isFirebaseReady()) {
        await _auth.signOut();
        if (!kIsWeb) {
          final GoogleSignIn googleSignIn = GoogleSignIn();
          await googleSignIn.signOut();
        }
      }
      await LocalStorageService.clearUserCredentials();
      print('✅ LOGOUT REALIZADO');
    } catch (e) {
      print('❌ ERRO NO LOGOUT: $e');
    }
  }

  static Future<void> _clearUserData() async {
    try {
      final prefs = await LocalStorageService.getPrefs();
      await prefs.remove('user_data');
      print('✅ DADOS REMOVIDOS');
    } catch (e) {
      print('❌ ERRO AO LIMPAR: $e');
    }
  }

  static Future<bool> initializeUserSession() async {
    try {
      print('🔄 INICIALIZANDO SESSÃO...');
      if (!_isFirebaseReady()) {
        print('❌ FIREBASE NÃO INICIALIZADO');
        return false;
      }
      final user = _auth.currentUser;
      if (user != null) {
        print('✅ USUÁRIO LOGADO: ${user.email}');
        // ✅ TENTA BUSCAR DO FIRESTORE PRIMEIRO
        final firestoreUser = await _getUserFromFirestore(user.uid);
        if (firestoreUser != null && firestoreUser.userType.isNotEmpty) {
          await _saveUserData(firestoreUser);
          print('✅ SESSÃO INICIALIZADA COM DADOS DO FIRESTORE');
          return true;
        }
        // ✅ FALLBACK PARA DADOS LOCAIS
        final cachedUser = await _getCachedUserData();
        if (cachedUser != null && cachedUser['user_type']?.isNotEmpty == true) {
          print(
              '✅ DADOS EXISTENTES ENCONTRADOS - UserType: ${cachedUser['user_type']}');
          print('✅ MANTENDO DADOS EXISTENTES DO USUÁRIO');
          return true;
        }
        final appUser = app_model.User(
          id: user.uid,
          name: user.displayName ?? 'Usuário',
          username: user.email?.split('@')[0] ?? 'user',
          email: user.email ?? '',
          password: '',
          userType: cachedUser?['user_type'] ?? '',
        );
        await _saveUserData(appUser);
        print('✅ NOVA SESSÃO INICIALIZADA');
        return true;
      }
      print('❌ NENHUM USUÁRIO LOGADO');
      return false;
    } catch (e) {
      print('❌ ERRO AO INICIALIZAR SESSÃO: $e');
      return false;
    }
  }

  static Future<void> updateCurrentUser(app_model.User updatedUser) async {
    try {
      if (!_isFirebaseReady()) {
        print('❌ FIREBASE NÃO INICIALIZADO PARA ATUALIZAÇÃO');
        return;
      }
      final user = _auth.currentUser;
      if (user != null) {
        if (updatedUser.name != user.displayName) {
          await user.updateDisplayName(updatedUser.name);
          print('✅ PERFIL ATUALIZADO NO FIREBASE AUTH: ${updatedUser.name}');
        }
      }
      // ✅ ATUALIZA EM AMBOS: Local e Firestore
      await _saveUserData(updatedUser);
      await _saveUserToFirestore(updatedUser);
      print('✅ USUÁRIO ATUALIZADO: ${updatedUser.email}');
      print('✅ USERTYPE SALVO: ${updatedUser.userType}');
    } catch (e) {
      print('❌ ERRO AO ATUALIZAR USUÁRIO: $e');
      rethrow;
    }
  }

  static Future<void> repairUserData() async {
    try {
      print('🔧 REPARANDO DADOS DO USUÁRIO...');
      final user = _auth.currentUser;
      if (user != null) {
        final cachedData = await _getCachedUserData();
        if (cachedData != null &&
            (cachedData['user_type'] == null ||
                cachedData['user_type'].isEmpty)) {
          print('⚠️ DADOS CORROMPIDOS ENCONTRADOS - REPARANDO...');
          final repairedUser = app_model.User(
            id: user.uid,
            name: cachedData['name'] ?? user.displayName ?? 'Usuário',
            username: cachedData['username'] ?? user.email!.split('@')[0],
            email: user.email!,
            password: '',
            userType: 'turista',
          );
          await _saveUserData(repairedUser);
          await _saveUserToFirestore(repairedUser);
          print('✅ DADOS REPARADOS - UserType definido como: turista');
        } else {
          print('✅ DADOS JÁ ESTÃO CORRETOS');
        }
      }
    } catch (e) {
      print('❌ ERRO NO REPARO: $e');
    }
  }

  static Future<Map<String, dynamic>> resetPassword(String email) async {
    if (!_isFirebaseReady()) {
      return {'success': false, 'message': 'Firebase não configurado'};
    }
    try {
      print('🔹 RESET_PASSWORD - Solicitando reset para: $email');
      await _auth.sendPasswordResetEmail(email: email);
      print('✅ RESET_PASSWORD - Email enviado com sucesso');
      return {
        'success': true,
        'message':
            'Email de recuperação enviado! Verifique sua caixa de entrada.'
      };
    } on FirebaseAuthException catch (e) {
      String message = 'Erro ao enviar email de recuperação';
      if (e.code == 'user-not-found') {
        message = 'Email não cadastrado no sistema';
      } else if (e.code == 'invalid-email') {
        message = 'Email inválido';
      } else if (e.code == 'network-request-failed') {
        message = 'Erro de conexão. Verifique sua internet';
      }
      print('❌ RESET_PASSWORD - Erro: $message');
      return {'success': false, 'message': message};
    } catch (e) {
      print('❌ RESET_PASSWORD - Erro geral: $e');
      return {'success': false, 'message': 'Erro inesperado: $e'};
    }
  }
}
