import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:second_brain/core/config/api_config.dart';
import 'package:second_brain/core/auth/auth_user.dart';

/// Authentication and User Session Service.
/// Manages login, signup, user profile, and monthly income/capacity updates.
class AuthService extends ChangeNotifier {
  static final AuthService instance = AuthService._internal();

  AuthUser? _currentUser;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;

  AuthService._internal() {
    // Configure global token provider so all API clients use this token automatically
    ApiConfig.authTokenProvider = () async => _token;
  }

  factory AuthService() => instance;

  AuthUser? get currentUser => _currentUser;
  String? get token => _token;
  bool get isAuthenticated => _token != null && _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Sets default dev user for testing if no active user session
  void ensureDevSession() {
    if (_token == null) {
      _token = 'sb-auth-283a55c3-cc09-4445-8219-a63452a23b6b-session';
      _currentUser = const AuthUser(
        id: '283a55c3-cc09-4445-8219-a63452a23b6b',
        name: 'Yazhini Nedumaran',
        email: 'yazhininedumaran06@gmail.com',
        phone: '9360097382',
        monthlyIncome: 75000.0,
        monthlyCapacity: 25000.0,
      );
      notifyListeners();
    }
  }

  /// Registers a new user with Name, Email, Phone, Password, and Monthly Income.
  Future<bool> signup({
    required String name,
    required String email,
    required String phone,
    required String password,
    double monthlyIncome = 75000.0,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final payload = jsonEncode({
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'phone': phone.trim(),
      'password': password,
      'monthly_income': monthlyIncome.toStringAsFixed(2),
    });

    final urlsToTry = [
      ApiConfig.baseUrl,
      ...ApiConfig.candidateUrls.where((u) => u != ApiConfig.baseUrl),
    ];

    for (final base in urlsToTry) {
      try {
        final url = Uri.parse('$base/auth/signup');
        final response = await http
            .post(
              url,
              headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
              body: payload,
            )
            .timeout(const Duration(seconds: 8));

        ApiConfig.baseUrl = base;
        final data = jsonDecode(response.body);
        if (response.statusCode >= 200 && response.statusCode < 300) {
          _token = data['access_token']?.toString();
          _currentUser = AuthUser.fromJson(data['user'] as Map<String, dynamic>);
          _errorMessage = null;
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          if (data['detail'] is List) {
            _errorMessage = (data['detail'] as List)
                .map((e) => e['msg']?.toString() ?? e.toString())
                .join(', ');
          } else {
            _errorMessage = data['detail']?.toString() ?? 'Registration failed.';
          }
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } catch (_) {
        continue;
      }
    }

    _errorMessage = 'Could not connect to server. Please check your connection.';
    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Logs in an existing user with Phone or Email and Password.
  Future<bool> login({
    required String username,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final payload = jsonEncode({
      'username': username.trim(),
      'password': password,
    });

    final urlsToTry = [
      ApiConfig.baseUrl,
      ...ApiConfig.candidateUrls.where((u) => u != ApiConfig.baseUrl),
    ];

    for (final base in urlsToTry) {
      try {
        final url = Uri.parse('$base/auth/login');
        final response = await http
            .post(
              url,
              headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
              body: payload,
            )
            .timeout(const Duration(seconds: 8));

        ApiConfig.baseUrl = base;
        final data = jsonDecode(response.body);
        if (response.statusCode >= 200 && response.statusCode < 300) {
          _token = data['access_token']?.toString();
          _currentUser = AuthUser.fromJson(data['user'] as Map<String, dynamic>);
          _errorMessage = null;
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          if (data['detail'] is List) {
            _errorMessage = (data['detail'] as List)
                .map((e) => e['msg']?.toString() ?? e.toString())
                .join(', ');
          } else {
            _errorMessage = data['detail']?.toString() ?? 'Invalid credentials.';
          }
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } catch (e) {
        debugPrint('Login attempt to $base failed: $e');
        continue;
      }
    }

    _errorMessage = 'Could not connect to server. Please check your connection.';
    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Fetches latest profile details from `/auth/me`.
  Future<void> fetchProfile() async {
    if (_token == null) return;
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/auth/me');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _currentUser = AuthUser.fromJson(data);
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Updates user's monthly income and/or financial capacity in PostgreSQL.
  Future<bool> updateFinancialProfile({
    double? monthlyIncome,
    double? monthlyCapacity,
  }) async {
    final payload = <String, dynamic>{};
    if (monthlyIncome != null) payload['monthly_income'] = monthlyIncome.toStringAsFixed(2);
    if (monthlyCapacity != null) payload['monthly_capacity'] = monthlyCapacity.toStringAsFixed(2);

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/auth/financial-profile');
      final authToken = _token ?? 'test-token-flutter-device-user';
      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _currentUser = AuthUser.fromJson(data);
        notifyListeners();
        return true;
      }
      return false;
    } catch (_) {
      // Local fallback in case of offline/network issues
      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(
          monthlyIncome: monthlyIncome,
          monthlyCapacity: monthlyCapacity,
        );
        notifyListeners();
      }
      return true;
    }
  }

  /// Logs out the user and clears state.
  void logout() {
    _token = null;
    _currentUser = null;
    notifyListeners();
  }
}
