import 'package:second_brain/features/financial_goals/models/financial_goal.dart';

class CashFlowSummaryData {
  final double monthlyIncome;
  final double monthlyExpenses;
  final double existingCommitments;
  final double availableCapacity;
  final double totalGoalContributions;
  final double remainingGoalCapacity;

  CashFlowSummaryData({
    required this.monthlyIncome,
    required this.monthlyExpenses,
    required this.existingCommitments,
    required this.availableCapacity,
    required this.totalGoalContributions,
    required this.remainingGoalCapacity,
  });

  factory CashFlowSummaryData.fromJson(Map<String, dynamic> json) {
    return CashFlowSummaryData(
      monthlyIncome: double.tryParse(json['monthly_income']?.toString() ?? '0') ?? 0.0,
      monthlyExpenses: double.tryParse(json['monthly_expenses']?.toString() ?? '0') ?? 0.0,
      existingCommitments: double.tryParse(json['existing_commitments']?.toString() ?? '0') ?? 0.0,
      availableCapacity: double.tryParse(json['available_capacity']?.toString() ?? '0') ?? 0.0,
      totalGoalContributions: double.tryParse(json['total_goal_contributions']?.toString() ?? '0') ?? 0.0,
      remainingGoalCapacity: double.tryParse(json['remaining_goal_capacity']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class ConflictReportData {
  final bool hasConflict;
  final double monthlyCapacity;
  final double totalRequiredContribution;
  final double monthlyShortfall;
  final List<String> affectedGoalNames;
  final String conflictReason;

  ConflictReportData({
    required this.hasConflict,
    required this.monthlyCapacity,
    required this.totalRequiredContribution,
    required this.monthlyShortfall,
    required this.affectedGoalNames,
    required this.conflictReason,
  });

  factory ConflictReportData.fromJson(Map<String, dynamic> json) {
    final names = (json['affected_goal_names'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    return ConflictReportData(
      hasConflict: (json['has_conflict'] as bool?) ?? false,
      monthlyCapacity: double.tryParse(json['monthly_capacity']?.toString() ?? '0') ?? 0.0,
      totalRequiredContribution: double.tryParse(json['total_required_contribution']?.toString() ?? '0') ?? 0.0,
      monthlyShortfall: double.tryParse(json['monthly_shortfall']?.toString() ?? '0') ?? 0.0,
      affectedGoalNames: names,
      conflictReason: (json['conflict_reason'] ?? '') as String,
    );
  }
}

class GoalChangeDetailData {
  final String goalId;
  final String goalName;
  final String actionType;
  final double originalTarget;
  final double newTarget;
  final DateTime originalDeadline;
  final DateTime newDeadline;
  final double originalContribution;
  final double newContribution;

  GoalChangeDetailData({
    required this.goalId,
    required this.goalName,
    required this.actionType,
    required this.originalTarget,
    required this.newTarget,
    required this.originalDeadline,
    required this.newDeadline,
    required this.originalContribution,
    required this.newContribution,
  });

  factory GoalChangeDetailData.fromJson(Map<String, dynamic> json) {
    return GoalChangeDetailData(
      goalId: (json['goal_id'] ?? '').toString(),
      goalName: (json['goal_name'] ?? '').toString(),
      actionType: (json['action_type'] ?? '').toString(),
      originalTarget: double.tryParse(json['original_target']?.toString() ?? '0') ?? 0.0,
      newTarget: double.tryParse(json['new_target']?.toString() ?? '0') ?? 0.0,
      originalDeadline: json['original_deadline'] != null
          ? DateTime.parse(json['original_deadline'].toString())
          : DateTime.now(),
      newDeadline: json['new_deadline'] != null
          ? DateTime.parse(json['new_deadline'].toString())
          : DateTime.now(),
      originalContribution: double.tryParse(json['original_contribution']?.toString() ?? '0') ?? 0.0,
      newContribution: double.tryParse(json['new_contribution']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class FinancialScenarioData {
  final String id;
  final String name;
  final String description;
  final List<GoalChangeDetailData> changes;
  final bool isFeasible;
  final double monthlyRequirement;
  final double monthlyCapacity;
  final double monthlySurplusOrGap;
  final List<String> affectedGoals;
  final List<String> tradeoffs;

  FinancialScenarioData({
    required this.id,
    required this.name,
    required this.description,
    required this.changes,
    required this.isFeasible,
    required this.monthlyRequirement,
    required this.monthlyCapacity,
    required this.monthlySurplusOrGap,
    required this.affectedGoals,
    required this.tradeoffs,
  });

  factory FinancialScenarioData.fromJson(Map<String, dynamic> json) {
    final rawChanges = (json['changes'] as List<dynamic>?) ?? [];
    final changesList = rawChanges
        .map((c) => GoalChangeDetailData.fromJson(c as Map<String, dynamic>))
        .toList();

    final rawGoals = (json['affected_goals'] as List<dynamic>?) ?? [];
    final goalsList = rawGoals.map((g) => g.toString()).toList();

    final rawTradeoffs = (json['tradeoffs'] as List<dynamic>?) ?? [];
    final tradeoffsList = rawTradeoffs.map((t) => t.toString()).toList();

    return FinancialScenarioData(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Scenario').toString(),
      description: (json['description'] ?? '').toString(),
      changes: changesList,
      isFeasible: (json['is_feasible'] as bool?) ?? true,
      monthlyRequirement: double.tryParse(json['monthly_requirement']?.toString() ?? '0') ?? 0.0,
      monthlyCapacity: double.tryParse(json['monthly_capacity']?.toString() ?? '0') ?? 0.0,
      monthlySurplusOrGap: double.tryParse(json['monthly_surplus_or_gap']?.toString() ?? '0') ?? 0.0,
      affectedGoals: goalsList,
      tradeoffs: tradeoffsList,
    );
  }
}

class FinancialAnalysisResponseData {
  final CashFlowSummaryData cashFlow;
  final List<FinancialGoal> goals;
  final ConflictReportData conflict;
  final List<FinancialScenarioData> scenarios;
  final bool overallFeasibility;

  FinancialAnalysisResponseData({
    required this.cashFlow,
    required this.goals,
    required this.conflict,
    required this.scenarios,
    required this.overallFeasibility,
  });

  factory FinancialAnalysisResponseData.fromJson(Map<String, dynamic> json) {
    final rawGoals = (json['goals'] as List<dynamic>?) ?? [];
    final goalsList = rawGoals
        .map((g) => FinancialGoal.fromJson(g as Map<String, dynamic>))
        .toList();

    final rawScenarios = (json['scenarios'] as List<dynamic>?) ?? [];
    final scenariosList = rawScenarios
        .map((s) => FinancialScenarioData.fromJson(s as Map<String, dynamic>))
        .toList();

    return FinancialAnalysisResponseData(
      cashFlow: CashFlowSummaryData.fromJson(json['cash_flow'] as Map<String, dynamic>),
      goals: goalsList,
      conflict: ConflictReportData.fromJson(json['conflict'] as Map<String, dynamic>),
      scenarios: scenariosList,
      overallFeasibility: (json['overall_feasibility'] as bool?) ?? true,
    );
  }
}
