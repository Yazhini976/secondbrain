import 'package:flutter/foundation.dart';
import 'package:second_brain/features/financial_goals/data/financial_api.dart';
import 'package:second_brain/features/financial_goals/models/financial_goal.dart';
import 'package:second_brain/features/financial_goals/models/financial_analysis.dart';

/// Financial Repository.
/// Domain layer abstraction between Flutter UI and FastAPI + PostgreSQL backend.
/// Extends [ChangeNotifier] so UI components update reactively.
class FinancialRepository extends ChangeNotifier {
  static final FinancialRepository instance = FinancialRepository._internal();

  final FinancialApi _api;
  List<FinancialGoal> _goals = [];
  FinancialAnalysisResponseData? _analysis;
  bool _isLoading = false;
  String? _errorMessage;

  FinancialRepository._internal({FinancialApi? api})
      : _api = api ?? FinancialApi() {
    _goals = [];
  }

  factory FinancialRepository({FinancialApi? api}) {
    return FinancialRepository._internal(api: api);
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  FinancialAnalysisResponseData? get analysis => _analysis;

  List<FinancialGoal> getGoals() => List.unmodifiable(_goals);

  /// Loads goals and full financial analysis from backend API.
  Future<void> loadAnalysis() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final analysisData = await _api.getFinancialAnalysis();
      _analysis = analysisData;
      _goals = analysisData.goals;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('ApiException: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  FinancialGoal? getGoalById(String id) {
    try {
      return _goals.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Adds a financial goal and recalculates analysis.
  Future<FinancialGoal> addGoal(FinancialGoal goal) async {
    final existingIndex = _goals.indexWhere((g) => g.id == goal.id);
    if (existingIndex == -1) {
      _goals.add(goal);
    }
    notifyListeners();

    try {
      final created = await _api.createGoal(goal);
      await loadAnalysis();
      return created;
    } catch (e) {
      return goal;
    }
  }

  /// Updates a financial goal and recalculates analysis.
  Future<FinancialGoal> updateGoal(FinancialGoal goal) async {
    final idx = _goals.indexWhere((g) => g.id == goal.id);
    if (idx != -1) {
      _goals[idx] = goal;
    } else {
      _goals.add(goal);
    }
    notifyListeners();

    try {
      final serverUpdated = await _api.updateGoal(goal);
      await loadAnalysis();
      return serverUpdated;
    } catch (e) {
      return goal;
    }
  }

  /// Deletes a financial goal and recalculates analysis.
  Future<void> deleteGoal(String id) async {
    _goals.removeWhere((g) => g.id == id);
    notifyListeners();

    try {
      await _api.deleteGoal(id);
      await loadAnalysis();
    } catch (_) {}
  }

  /// Applies a selected scenario upon explicit user confirmation.
  Future<void> applyScenario(String scenarioId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _api.applyScenario(scenarioId);
      await loadAnalysis();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('ApiException: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Resets repository to sample data for tests.
  void resetSampleData() {
    _goals = List<FinancialGoal>.from(_sampleGoals);
    _analysis = null;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}

final List<FinancialGoal> _sampleGoals = [
  FinancialGoal(
    id: 'goal_001',
    name: 'Emergency Fund',
    category: FinancialGoalCategory.emergencyFund,
    targetAmount: 200000.0,
    currentAmount: 80000.0,
    monthlyContribution: 8000.0,
    deadline: DateTime(2027, 12, 31),
    priority: FinancialGoalPriority.high,
  ),
  FinancialGoal(
    id: 'goal_002',
    name: 'Home Downpayment',
    category: FinancialGoalCategory.home,
    targetAmount: 3000000.0,
    currentAmount: 400000.0,
    monthlyContribution: 15000.0,
    deadline: DateTime(2030, 6, 30),
    priority: FinancialGoalPriority.high,
  ),
  FinancialGoal(
    id: 'goal_003',
    name: 'Higher Education',
    category: FinancialGoalCategory.education,
    targetAmount: 1000000.0,
    currentAmount: 200000.0,
    monthlyContribution: 8000.0,
    deadline: DateTime(2028, 8, 31),
    priority: FinancialGoalPriority.medium,
  ),
];
