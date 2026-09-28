/// Model representing authenticated user profile in Flutter app.
class AuthUser {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final double monthlyIncome;
  final double monthlyCapacity;
  final bool isActive;

  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.monthlyIncome = 75000.0,
    this.monthlyCapacity = 25000.0,
    this.isActive = true,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id']?.toString() ?? '',
      name: json['display_name']?.toString() ?? json['name']?.toString() ?? 'User',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      monthlyIncome: double.tryParse(json['monthly_income']?.toString() ?? '75000') ?? 75000.0,
      monthlyCapacity: double.tryParse(json['monthly_capacity']?.toString() ?? '25000') ?? 25000.0,
      isActive: json['is_active'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'display_name': name,
    'email': email,
    'phone': phone,
    'monthly_income': monthlyIncome,
    'monthly_capacity': monthlyCapacity,
    'is_active': isActive,
  };

  AuthUser copyWith({
    String? name,
    String? email,
    String? phone,
    double? monthlyIncome,
    double? monthlyCapacity,
  }) {
    return AuthUser(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      monthlyCapacity: monthlyCapacity ?? this.monthlyCapacity,
      isActive: isActive,
    );
  }
}
