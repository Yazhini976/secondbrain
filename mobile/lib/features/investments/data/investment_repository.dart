import 'package:flutter/foundation.dart';
import 'package:second_brain/features/investments/models/investment.dart';
import 'package:second_brain/features/investments/data/investment_sample_data.dart';
import 'package:second_brain/features/investments/data/investment_api.dart';
import 'package:second_brain/features/reminders/services/automatic_reminder_service.dart';

/// Investment Repository.
/// Domain layer abstraction between Flutter UI and backend REST API.
/// Extends [ChangeNotifier] so Home and Investments screens reactively rebuild.
class InvestmentRepository extends ChangeNotifier {
  static final InvestmentRepository instance = InvestmentRepository._internal();

  final InvestmentApi _api;
  List<Investment> _investments = [];
  bool _isLoading = false;
  String? _errorMessage;

  InvestmentRepository._internal({InvestmentApi? api})
      : _api = api ?? InvestmentApi() {
    _investments = [];
  }

  /// Factory constructor for testing / dependency injection.
  factory InvestmentRepository({InvestmentApi? api}) {
    return InvestmentRepository._internal(api: api);
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<Investment> getInvestments() => List.unmodifiable(_investments);

  /// Loads investments from backend with optional category type filter.
  Future<List<Investment>> loadInvestments({String? type}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final remoteList = await _api.getInvestments(type: type);
      _investments = remoteList;
      _isLoading = false;
      notifyListeners();
      return _investments;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('ApiException: ', '');
      _isLoading = false;
      notifyListeners();
      // Fall back to current in-memory list for offline/test mode
      if (type != null) {
        return getInvestmentsByType(InvestmentTypeExtension.fromString(type));
      }
      return getInvestments();
    }
  }

  /// Fetches portfolio summary from backend.
  Future<InvestmentSummaryData?> fetchSummary() async {
    try {
      return await _api.getInvestmentSummary();
    } catch (e) {
      return null;
    }
  }

  List<Investment> getInvestmentsByType(InvestmentType type) =>
      _investments.where((i) => i.type == type).toList();

  Investment? getInvestmentById(String id) {
    try {
      return _investments.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Sum of [totalPaid] across all investments — used for the Home summary card.
  double getTotalInvested() =>
      _investments.fold(0.0, (sum, i) => sum + i.totalPaid);

  /// Returns the [limit] most-recently added investments.
  List<Investment> getRecent({int limit = 5}) {
    final sorted = List<Investment>.from(_investments)
      ..sort((a, b) {
        final aDate = a.startDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.startDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
    return sorted.take(limit).toList();
  }

  /// Adds an investment via backend API and updates local state.
  Future<Investment> addInvestment(Investment investment) async {
    // 1. Immediately update local state for UI responsiveness and synchronous tests
    final existingIndex = _investments.indexWhere((i) => i.id == investment.id);
    if (existingIndex == -1) {
      _investments.add(investment);
    }
    notifyListeners();
    try {
      AutomaticReminderService.instance.syncInvestment(investment);
    } catch (_) {}

    // 2. Perform backend sync
    try {
      final created = await _api.createInvestment(investment);
      final idx = _investments.indexWhere((i) => i.id == investment.id || i.id == created.id);
      if (idx != -1) {
        _investments[idx] = created;
      } else {
        _investments.add(created);
      }
      notifyListeners();
      try {
        AutomaticReminderService.instance.syncInvestment(created);
      } catch (_) {}
      return created;
    } catch (e) {
      return investment;
    }
  }

  /// Updates an investment via backend API and updates local state.
  Future<Investment> updateInvestment(Investment updated) async {
    // 1. Immediately update local state
    final index = _investments.indexWhere((i) => i.id == updated.id);
    if (index != -1) {
      _investments[index] = updated;
    } else {
      _investments.add(updated);
    }
    notifyListeners();
    try {
      AutomaticReminderService.instance.syncInvestment(updated);
    } catch (_) {}

    // 2. Perform backend sync
    try {
      final serverUpdated = await _api.updateInvestment(updated);
      final idx = _investments.indexWhere((i) => i.id == serverUpdated.id);
      if (idx != -1) {
        _investments[idx] = serverUpdated;
      } else {
        _investments.add(serverUpdated);
      }
      notifyListeners();
      try {
        AutomaticReminderService.instance.syncInvestment(serverUpdated);
      } catch (_) {}
      return serverUpdated;
    } catch (e) {
      return updated;
    }
  }

  /// Deletes an investment via backend API and updates local state.
  Future<void> deleteInvestment(String id) async {
    // 1. Immediately remove from local state
    _investments.removeWhere((i) => i.id == id);
    notifyListeners();
    try {
      AutomaticReminderService.instance.removeInvestmentReminder(id);
    } catch (_) {}

    // 2. Perform backend sync
    try {
      await _api.deleteInvestment(id);
    } catch (_) {}
  }

  /// Resets the repository to initial sample data for testing.
  void resetSampleData() {
    _investments = List<Investment>.from(InvestmentSampleData.investments);
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}
