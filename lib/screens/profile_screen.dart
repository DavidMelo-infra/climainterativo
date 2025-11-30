import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart' as app_model;
import '../utils/constants.dart';
import '../utils/widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  app_model.User? _currentUser;
  bool _isLoading = true;
  String? _error;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _userTypeController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await AuthService.getCurrentUser();
      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
      if (user != null) {
        _nameController.text = user.name;
        _usernameController.text = user.username;
        _emailController.text = user.email;
        _userTypeController.text = user.userType;
      }
    } catch (e) {
      setState(() {
        _error = 'Erro ao carregar dados do usuário';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateProfile() async {
    if (_currentUser == null) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final updatedUser = app_model.User(
        id: _currentUser!.id,
        name: _nameController.text,
        username: _usernameController.text,
        email: _emailController.text,
        password: _currentUser!.password,
        userType: _userTypeController.text,
      );
      await AuthService.updateCurrentUser(updatedUser);
      if (mounted) {
        setState(() {
          _currentUser = updatedUser;
          _isLoading = false;
          _isEditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil atualizado com sucesso!')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Erro ao atualizar perfil: $e';
      });
    }
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        // Reset controllers to original values when cancelling edit
        _nameController.text = _currentUser?.name ?? '';
        _usernameController.text = _currentUser?.username ?? '';
        _emailController.text = _currentUser?.email ?? '';
        _userTypeController.text = _currentUser?.userType ?? '';
      }
    });
  }

  // ------------------------------------------------------------------
  // Funções auxiliares para o layout (mantidas como estavam)
  // ------------------------------------------------------------------
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

  // ------------------------------------------------------------------
  // Helper que devolve ícone e texto conforme o tipo de usuário
  // ------------------------------------------------------------------
  ({IconData icon, String text}) _getUserTypeInfo(String userType) {
    if (userType == 'motorista') {
      return (icon: Icons.two_wheeler_outlined, text: 'Motorista/Veículo');
    } else if (userType == 'turista') {
      return (icon: Icons.directions_walk, text: 'Transeunte/Turista');
    }
    return (icon: Icons.group, text: 'Não definido');
  }

  // ------------------------------------------------------------------
  // Linha de informação (mantida, mas agora usa o helper acima)
  // ------------------------------------------------------------------
  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon,
    bool isEditing,
    TextEditingController? controller,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: kPrimaryColor),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF4B5563),
                fontSize: 15,
              ),
            ),
          ),
          Expanded(
            child: isEditing && controller != null
                ? TextFormField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: value,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: kPrimaryColor),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  )
                : Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.normal,
                      color: Color(0xFF1F2937),
                      fontSize: 15,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // Seletor de tipo de usuário com ícones (usado na edição)
  // ------------------------------------------------------------------
  Widget _buildUserTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Perfil de usuário:',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF4B5563),
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildUserTypeOption(
              Icons.two_wheeler_outlined,
              'motorista/veículo',
              'motorista',
            ),
            const SizedBox(width: 12),
            _buildUserTypeOption(
              Icons.directions_walk,
              'transeunte/turista',
              'turista',
            ),
          ],
        ),
      ],
    );
  }

  // ------------------------------------------------------------------
  // Opção individual do seletor (ícone + texto)
  // ------------------------------------------------------------------
  Widget _buildUserTypeOption(IconData icon, String title, String value) {
    final isSelected = _userTypeController.text == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _userTypeController.text = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(12),
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

  // ------------------------------------------------------------------
  // Montagem da área de informações do usuário
  // ------------------------------------------------------------------
  Widget _buildUserInfo() {
    if (_currentUser == null) {
      return const Center(
        child: Text(
          'Usuário não encontrado',
          style: TextStyle(color: Colors.white),
        ),
      );
    }
    final userInfo = _getUserTypeInfo(_currentUser!.userType);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow(
          'Nome:',
          _currentUser!.name,
          Icons.person_outline,
          _isEditing,
          _isEditing ? _nameController : null,
        ),
        _buildInfoRow(
          'Usuário:',
          _currentUser!.username,
          Icons.alternate_email,
          _isEditing,
          _isEditing ? _usernameController : null,
        ),
        // Email field is read‑only
        _buildInfoRow(
          'Email:',
          _currentUser!.email,
          Icons.mail_outline,
          false,
          null,
        ),
        if (_isEditing)
          _buildUserTypeSelector()
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(userInfo.icon, size: 20, color: kPrimaryColor),
              const SizedBox(width: 12),
              SizedBox(
                width: 80,
                child: const Text(
                  'Perfil de usuário:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4B5563),
                    fontSize: 15,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  userInfo.text,
                  style: const TextStyle(
                    fontWeight: FontWeight.normal,
                    color: Color(0xFF1F2937),
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  // ------------------------------------------------------------------
  // Botões de ação (Editar / Salvar / Cancelar / Sair)
  // ------------------------------------------------------------------
  Widget _buildActionButtons() {
    if (_isEditing) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _toggleEdit,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: kPrimaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: kPrimaryColor),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  text: 'Salvar',
                  onPressed: _updateProfile,
                  isLoading: _isLoading,
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      return Column(
        children: [
          CustomButton(
            text: 'Editar Perfil',
            onPressed: _toggleEdit,
            backgroundColor: kPrimaryColor,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () async {
              await AuthService.logout();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  loginRoute,
                  (route) => false,
                );
              }
            },
            child: const Text(
              'Sair da Conta',
              style: TextStyle(color: Colors.red, fontSize: 16),
            ),
          ),
        ],
      );
    }
  }

  // ------------------------------------------------------------------
  // Build da tela
  // ------------------------------------------------------------------
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
            SafeArea(
              child: Center(
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(24.0),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: Column(
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
                                            color:
                                                Colors.black.withOpacity(0.1),
                                            blurRadius: 10,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(Icons.person,
                                          size: 40, color: kPrimaryColor),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Meu Perfil',
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Gerencie suas informações',
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
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    if (_error != null)
                                      Container(
                                        padding: const EdgeInsets.all(12.0),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFEF2F2),
                                          border: Border.all(
                                              color: const Color(0xFFFEE2E2)),
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                        child: Text(
                                          _error!,
                                          style: const TextStyle(
                                            color: Color(0xFFB91C1C),
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 16),
                                    _buildUserInfo(),
                                    const SizedBox(height: 24),
                                    _buildActionButtons(),
                                  ],
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.only(top: 24.0),
                                child: Text(
                                  '© 2025 Clima Interativo. Todos os direitos reservados.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFBFDBFE),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
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
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _userTypeController.dispose();
    super.dispose();
  }
}
