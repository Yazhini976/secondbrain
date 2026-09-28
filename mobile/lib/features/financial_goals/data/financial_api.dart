import 'package:second_brain/core/network/api_client.dart';
import 'package:second_brain/features/financial_goals/models/financial_goal.dart';
import 'package:second_brain/features/financial_goals/models/financial_analysis.dart';

/// Remote API client for Financial Intelligence Engine backend endpoints.
class FinancialApi {
  final ApiClient _client;

  FinancialApi({ApiClient? client}) : _client = client ?? ApiClient();

  /// Fetches financial goals from backend.
  Future<List<FinancialGoal>> getGoals() async {
    final response = await _client.get('/financial/goals');
    final List<dynamic> list = response as List<dynamic>;
    return list
        .map((json) => FinancialGoal.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Creates a new financial goal.
  Future<FinancialGoal> createGoal(FinancialGoal goal) async {
    final response = await _client.post('/financial/goals', body: goal.toJson());
    return FinancialGoal.fromJson(response as Map<String, dynamic>);
  }

  /// Updates an existing financial goal.
  Future<FinancialGoal> updateGoal(FinancialGoal goal) async {
    final response =
        await _client.patch('/financial/goals/${goal.id}', body: goal.toJson());
    return FinancialGoal.fromJson(response as Map<String, dynamic>);
  }

  /// Deletes a financial goal.
  Future<void> deleteGoal(String id) async {
    await _client.delete('/financial/goals/$id');
  }

  /// Fetches complete deterministic financial analysis (cash flow, conflict, scenarios).
  Future<FinancialAnalysisResponseData> getFinancialAnalysis() async {
    final response = await _client.get('/financial/analysis');
    return FinancialAnalysisResponseData.fromJson(response as Map<String, dynamic>);
  }

  /// Generates feasible trade-off scenarios.
  Future<List<FinancialScenarioData>> generateScenarios() async {
    final response = await _client.post('/financial/scenarios/generate');
    final List<dynamic> list = response as List<dynamic>;
    return list
        .map((json) => FinancialScenarioData.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Applies a selected scenario upon explicit user confirmation.
  Future<void> applyScenario(String scenarioId) async {
    await _client.post('/financial/scenarios/$scenarioId/apply');
  }

  /// Sends natural language question to AI Interaction Layer.
  Future<Map<String, dynamic>> sendAIChatMessage(String message) async {
    final response = await _client.post(
      '/financial/ai/chat',
      body: {'message': message},
    );
    return response as Map<String, dynamic>;
  }
}
