import 'package:flutter/foundation.dart';
import 'package:second_brain/core/auth/auth_service.dart';
import 'package:second_brain/core/network/api_client.dart';

/// Stores editable user profile fields.
/// Extends [ChangeNotifier] so any widget (e.g., HomeHeader) rebuilds
/// automatically when the user updates their name.
class UserProfileRepository extends ChangeNotifier {
  static final UserProfileRepository instance =
      UserProfileRepository._internal();

  final ApiClient _api;

  UserProfileRepository._internal({ApiClient? api}) : _api = api ?? ApiClient();

  String _name = 'Yazhini';
  String _subtitle = 'Welcome back';

  String get name => _name;
  String get subtitle => _subtitle;

  /// Loads user profile dynamically from backend API (/auth/me).
  Future<void> loadProfile() async {
    final authUser = AuthService.instance.currentUser;
    if (authUser != null && authUser.name.isNotEmpty) {
      _name = authUser.name.split(' ').first;
      notifyListeners();
    }
    try {
      final res = await _api.get('/auth/me');
      if (res is Map<String, dynamic>) {
        final displayName = res['display_name'] as String?;
        if (displayName != null && displayName.trim().isNotEmpty) {
          _name = displayName.trim().split(' ').first;
          notifyListeners();
        }
      }
    } catch (_) {
      // Graceful offline fallback
    }
  }

  /// Returns a time-aware greeting based on current hour.
  String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void updateName(String name) {
    final trimmed = name.trim();
    if (trimmed.isNotEmpty && trimmed != _name) {
      _name = trimmed;
      notifyListeners();
    }
  }

  void updateSubtitle(String subtitle) {
    final trimmed = subtitle.trim();
    if (trimmed != _subtitle) {
      _subtitle = trimmed;
      notifyListeners();
    }
  }
}
