class User {
  final String? id;
  final String name;
  final String username;
  final String email;
  final String password;
  final String userType; // 'motorista', 'turista', ou '' para não definido

  const User({
    this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.password,
    required this.userType,
  });

  factory User.empty() {
    return const User(
      id: null,
      name: '',
      username: '',
      email: '',
      password: '',
      userType: '', // Vazio por padrão
    );
  }

  User copyWith({
    String? id,
    String? name,
    String? username,
    String? email,
    String? password,
    String? userType,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      userType: userType ?? this.userType,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'email': email,
      'password': password,
      'user_type': userType, // Padronizado para snake_case
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id']?.toString(),
      name: map['name'] ?? '',
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      password: map['password'] ?? '',
      userType:
          map['user_type'] ?? map['userType'] ?? '', // Vazio se não definido
    );
  }

  bool get hasProfileSelected => userType.isNotEmpty;
  bool get isDriver => userType == 'motorista';
  bool get isTourist => userType == 'turista';
}
