import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../utils/widgets.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  final String registerRoute;
  final String homeRoute;

  const LoginScreen({
    super.key,
    required this.registerRoute,
    required this.homeRoute,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _error;
  bool _showPassword = false;

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _error = 'Por favor, preencha todos os campos';
      });
      return;
    }
    if (!_emailController.text.contains('@')) {
      setState(() {
        _error = 'Email inválido';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await AuthService.login(
        _emailController.text,
        _passwordController.text,
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        if (result['success'] == true) {
          final user = result['user'];
          final bool needsProfile = result['needsProfile'] == true;
          _showSuccessDialog(
            'Bem-vindo(a), ${user['name']}! ',
            'Login realizado com sucesso. Redirecionando para a tela de Perfil/Home...',
          );
          //  NAVEGAÇÃO CORRETA BASEADA NO userType
          if (needsProfile) {
            // Se userType está vazio, vai para seleção de perfil
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/profile-selection', //  ROTA DA TELA DE SELEÇÃO DE PERFIL
              (route) => false,
            );
          } else {
            // Se userType está definido, vai para home
            Navigator.pushNamedAndRemoveUntil(
              context,
              widget.homeRoute,
              (route) => false,
            );
          }
        } else {
          setState(() {
            _error = result['message'] ?? 'Email ou senha incorretos';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erro ao fazer login: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() {
      _isGoogleLoading = true;
      _error = null;
    });
    try {
      final result = await AuthService.loginWithGoogle();
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
        if (result['success'] == true) {
          final user = result['user'];
          final bool needsProfile = result['needsProfile'] == true;
          _showSuccessDialog(
            'Bem-vindo(a), ${user['name']}! ',
            'Login com Google realizado com sucesso!',
          );
          //  NAVEGAÇÃO CORRETA BASEADA NO userType
          if (needsProfile) {
            // Se userType está vazio, vai para seleção de perfil
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/profile-selection', //  ROTA DA TELA DE SELEÇÃO DE PERFIL
              (route) => false,
            );
          } else {
            // Se userType está definido, vai para home
            Navigator.pushNamedAndRemoveUntil(
              context,
              widget.homeRoute,
              (route) => false,
            );
          }
        } else {
          setState(() {
            _error = result['message'] ?? 'Erro ao fazer login com Google';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erro ao fazer login com Google: $e';
          _isGoogleLoading = false;
        });
      }
    }
  }

  void _showSuccessDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: const Text('OK', style: TextStyle(color: kPrimaryColor)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildAnimatedBackground(
    double top,
    double left,
    double size,
    Color color,
  ) {
    return Positioned(
      top: top,
      left: left,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 50,
              spreadRadius: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleSignInButton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ElevatedButton(
        onPressed: _isGoogleLoading ? null : _loginWithGoogle,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.grey[800],
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey[300]!),
          ),
          elevation: 2,
        ),
        child: _isGoogleLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: const Icon(
                      Icons.g_mobiledata,
                      size: 24,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Entrar com Google',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [kGradientStart, kGradientMiddle, kGradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            _buildAnimatedBackground(80, 40, 200, Colors.white),
            _buildAnimatedBackground(
              MediaQuery.of(context).size.height * 0.7,
              MediaQuery.of(context).size.width * 0.6,
              300,
              kSecondaryColor,
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 32.0),
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.cloud,
                                  size: 40, color: kPrimaryColor),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Clima Interativo',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Previsão do tempo ao seu alcance',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFFBFDBFE),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(32.0),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(16.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 25,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Entrar na sua conta',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            // Botão Google Sign-In
                            _buildGoogleSignInButton(),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16.0),
                              child: Row(
                                children: [
                                  Expanded(
                                      child: Divider(color: Color(0xFFE5E7EB))),
                                  Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 12),
                                    child: Text(
                                      'ou',
                                      style:
                                          TextStyle(color: Color(0xFF6B7280)),
                                    ),
                                  ),
                                  Expanded(
                                      child: Divider(color: Color(0xFFE5E7EB))),
                                ],
                              ),
                            ),
                            CustomInputField(
                              label: 'Email',
                              hintText: 'seu@email.com',
                              prefixIcon: Icons.mail_outline,
                              onChanged: (value) =>
                                  _emailController.text = value,
                            ),
                            const SizedBox(height: 20),
                            CustomInputField(
                              label: 'Senha',
                              hintText: '••••••••',
                              prefixIcon: Icons.lock_outline,
                              isPassword: true,
                              showPassword: _showPassword,
                              onTogglePassword: () {
                                setState(() {
                                  _showPassword = !_showPassword;
                                });
                              },
                              onChanged: (value) =>
                                  _passwordController.text = value,
                            ),
                            // Link Esqueceu a senha - ATUALIZADO
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ForgotPasswordScreen(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Esqueceu a senha?',
                                  style: TextStyle(color: kPrimaryColor),
                                ),
                              ),
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.all(12.0),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  border: Border.all(
                                      color: const Color(0xFFFEE2E2)),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Text(
                                  _error!,
                                  style: const TextStyle(
                                    color: Color(0xFFB91C1C),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            CustomButton(
                              text: 'Entrar',
                              onPressed: _isLoading ? null : _login,
                              isLoading: _isLoading,
                            ),
                            const SizedBox(height: 24),
                            Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Não tem uma conta? ',
                                    style: TextStyle(color: Color(0xFF6B7280)),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        widget.registerRoute,
                                      );
                                    },
                                    child: const Text(
                                      'Cadastre-se',
                                      style: TextStyle(
                                        color: kPrimaryColor,
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
                      const Padding(
                        padding: EdgeInsets.only(top: 24.0),
                        child: Text(
                          '© 2025 Clima Interativo. Todos os direitos reservados.',
                          style:
                              TextStyle(fontSize: 12, color: Color(0xFFBFDBFE)),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
