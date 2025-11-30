import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../utils/widgets.dart';

enum UserType { driver, tourist }

class RegisterScreen extends StatefulWidget {
  final String loginRoute;

  const RegisterScreen({
    super.key,
    required this.loginRoute,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  String _name = '';
  String _username = '';
  String _email = '';
  String _password = '';
  bool _showPassword = false;
  String? _error;
  bool _isLoading = false;
  UserType _selectedUserType = UserType.tourist;

  void _handleRegister() async {
    setState(() {
      _error = null;
      _isLoading = true;
    });

    if (_name.isEmpty ||
        _username.isEmpty ||
        _email.isEmpty ||
        _password.isEmpty) {
      setState(() {
        _error = 'Preencha todos os campos';
        _isLoading = false;
      });
      return;
    }

    if (!_email.contains('@')) {
      setState(() {
        _error = 'Email inválido';
        _isLoading = false;
      });
      return;
    }

    if (_password.length < 6) {
      setState(() {
        _error = 'A senha deve ter pelo menos 6 caracteres';
        _isLoading = false;
      });
      return;
    }

    if (_username.length < 3) {
      setState(() {
        _error = 'Nome de usuário deve ter pelo menos 3 caracteres';
        _isLoading = false;
      });
      return;
    }

    final userType =
        _selectedUserType == UserType.driver ? 'motorista' : 'turista';
    print('🔹 RegisterScreen → userType enviado: $userType');
    final result = await AuthService.register(
      _name,
      _username,
      _email,
      _password,
      userType,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        _showSuccessDialog();
      } else {
        setState(() {
          _error = result['message'];
        });
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 50),
                const SizedBox(height: 16),
                const Text(
                  'Cadastro Concluído!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Parabéns, $_username! 🎉',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sua conta foi criada com sucesso. '
                  'Agora você pode fazer login e começar a compartilhar o clima da sua região.',
                  style: TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.pushReplacementNamed(
                        context,
                        widget.loginRoute,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Fazer Login',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
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

  Widget _buildUserTypeOption(IconData icon, String title, UserType type) {
    final isSelected = _selectedUserType == type;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedUserType = type;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? kPrimaryColor.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? kPrimaryColor : const Color(0xFFD1D5DB),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: kPrimaryColor, size: 24),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: const Color(0xFF1F2937),
                  fontSize: 12,
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [kGradientStart, kGradientMiddle, kGradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Container(
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
                      'Criar Nova Conta',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    CustomInputField(
                      label: 'Nome Completo',
                      hintText: 'Seu nome completo',
                      prefixIcon: Icons.person_outline,
                      onChanged: (value) => _name = value,
                    ),
                    const SizedBox(height: 20),
                    CustomInputField(
                      label: 'Nome de Usuário',
                      hintText: 'seu_usuario',
                      prefixIcon: Icons.alternate_email,
                      onChanged: (value) => _username = value,
                    ),
                    const SizedBox(height: 20),
                    CustomInputField(
                      label: 'Email',
                      hintText: 'seu@email.com',
                      prefixIcon: Icons.mail_outline,
                      onChanged: (value) => _email = value,
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
                      onChanged: (value) => _password = value,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Qual comunidade você pertence?',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // BOTÕES LADO A LADO
                    Row(
                      children: [
                        _buildUserTypeOption(
                          Icons.two_wheeler_outlined,
                          'Motorista/Veículo',
                          UserType.driver,
                        ),
                        const SizedBox(width: 12),
                        _buildUserTypeOption(
                          Icons.directions_walk,
                          'Turista/Transeunte',
                          UserType.tourist,
                        ),
                      ],
                    ),

                    if (_error != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          border: Border.all(color: const Color(0xFFFEE2E2)),
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
                      text: 'Criar Conta',
                      onPressed: _handleRegister,
                      isLoading: _isLoading,
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Já tem uma conta? ',
                            style: TextStyle(color: Color(0xFF6B7280)),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacementNamed(
                                context,
                                widget.loginRoute,
                              );
                            },
                            child: const Text(
                              'Fazer Login',
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
            ),
          ),
        ),
      ),
    );
  }
}
