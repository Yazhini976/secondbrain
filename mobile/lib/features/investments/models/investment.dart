/// Investment categories supported by Second Brain.
enum InvestmentType {
  gold,
  goldSavingScheme,
  chitFund,
  fd,
  rd,
  insurance,
}

extension InvestmentTypeExtension on InvestmentType {
  String get displayName {
    switch (this) {
      case InvestmentType.gold:
        return 'Gold & Jewellery';
      case InvestmentType.goldSavingScheme:
        return 'Gold Saving Schemes';
      case InvestmentType.chitFund:
        return 'Chit Funds / Kuri';
      case InvestmentType.fd:
        return 'FD';
      case InvestmentType.rd:
        return 'RD';
      case InvestmentType.insurance:
        return 'Insurance';
    }
  }

  static InvestmentType fromString(String raw) {
    switch (raw.trim()) {
      case 'Gold & Jewellery':
      case 'Gold':
        return InvestmentType.gold;
      case 'Gold Saving Schemes':
      case 'Gold Saving Scheme':
        return InvestmentType.goldSavingScheme;
      case 'Chit Funds / Kuri':
      case 'Chit Funds/Kuri':
      case 'Chit Fund':
        return InvestmentType.chitFund;
      case 'FD':
        return InvestmentType.fd;
      case 'RD':
        return InvestmentType.rd;
      case 'Insurance':
        return InvestmentType.insurance;
      default:
        return InvestmentType.fd;
    }
  }
}

class Investment {
  final String id;
  final String name;
  final InvestmentType type;
  final double monthlyContribution;
  final double totalPaid;
  final int installmentsPaid;
  final int totalInstallments;
  final DateTime? startDate;
  final DateTime? nextDueDate;
  final DateTime? maturityDate;
  final String? notes;
  final String? serverStatus;
  final double? progressPercentage;

  Investment({
    String? id,
    required this.name,
    required this.type,
    required this.monthlyContribution,
    required this.totalPaid,
    required this.installmentsPaid,
    required this.totalInstallments,
    this.startDate,
    this.nextDueDate,
    this.maturityDate,
    this.notes,
    this.serverStatus,
    this.progressPercentage,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  factory Investment.fromJson(Map<String, dynamic> json) {
    return Investment(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? 'Untitled Investment',
      type: InvestmentTypeExtension.fromString(json['type'] as String? ?? 'FD'),
      monthlyContribution: double.tryParse(json['monthly_contribution']?.toString() ?? '0') ?? 0.0,
      totalPaid: double.tryParse(json['total_paid']?.toString() ?? '0') ?? 0.0,
      installmentsPaid: (json['installments_paid'] as num?)?.toInt() ?? 0,
      totalInstallments: (json['total_installments'] as num?)?.toInt() ?? 0,
      startDate: json['start_date'] != null ? DateTime.tryParse(json['start_date'].toString()) : null,
      nextDueDate: json['next_due_date'] != null
          ? DateTime.tryParse(json['next_due_date'].toString())
          : (json['next_due'] != null ? DateTime.tryParse(json['next_due'].toString()) : null),
      maturityDate: json['maturity_date'] != null ? DateTime.tryParse(json['maturity_date'].toString()) : null,
      notes: json['notes'] as String?,
      serverStatus: json['status'] as String?,
      progressPercentage: (json['progress_percentage'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type.displayName,
      'monthly_contribution': monthlyContribution,
      'total_paid': totalPaid,
      'total_installments': totalInstallments,
      'installments_paid': installmentsPaid,
      if (startDate != null)
        'start_date': '${startDate!.year.toString().padLeft(4, '0')}-${startDate!.month.toString().padLeft(2, '0')}-${startDate!.day.toString().padLeft(2, '0')}',
      if (nextDueDate != null)
        'next_due_date': '${nextDueDate!.year.toString().padLeft(4, '0')}-${nextDueDate!.month.toString().padLeft(2, '0')}-${nextDueDate!.day.toString().padLeft(2, '0')}',
      if (maturityDate != null)
        'maturity_date': '${maturityDate!.year.toString().padLeft(4, '0')}-${maturityDate!.month.toString().padLeft(2, '0')}-${maturityDate!.day.toString().padLeft(2, '0')}',
      if (notes != null) 'notes': notes,
    };
  }

  Investment copyWith({
    String? name,
    InvestmentType? type,
    double? monthlyContribution,
    double? totalPaid,
    int? installmentsPaid,
    int? totalInstallments,
    DateTime? startDate,
    DateTime? nextDueDate,
    DateTime? maturityDate,
    String? notes,
    String? serverStatus,
    double? progressPercentage,
  }) {
    return Investment(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      monthlyContribution: monthlyContribution ?? this.monthlyContribution,
      totalPaid: totalPaid ?? this.totalPaid,
      installmentsPaid: installmentsPaid ?? this.installmentsPaid,
      totalInstallments: totalInstallments ?? this.totalInstallments,
      startDate: startDate ?? this.startDate,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      maturityDate: maturityDate ?? this.maturityDate,
      notes: notes ?? this.notes,
      serverStatus: serverStatus ?? this.serverStatus,
      progressPercentage: progressPercentage ?? this.progressPercentage,
    );
  }
}

class InvestmentSummaryData {
  final double totalInvested;
  final double totalMonthlyContribution;
  final int activeCount;
  final int completedCount;
  final int overdueCount;
  final int dueSoonCount;

  InvestmentSummaryData({
    required this.totalInvested,
    required this.totalMonthlyContribution,
    required this.activeCount,
    required this.completedCount,
    required this.overdueCount,
    required this.dueSoonCount,
  });

  factory InvestmentSummaryData.fromJson(Map<String, dynamic> json) {
    return InvestmentSummaryData(
      totalInvested: double.tryParse(json['total_invested']?.toString() ?? '0') ?? 0.0,
      totalMonthlyContribution: double.tryParse(json['total_monthly_contribution']?.toString() ?? '0') ?? 0.0,
      activeCount: (json['active_count'] as num?)?.toInt() ?? 0,
      completedCount: (json['completed_count'] as num?)?.toInt() ?? 0,
      overdueCount: (json['overdue_count'] as num?)?.toInt() ?? 0,
      dueSoonCount: (json['due_soon_count'] as num?)?.toInt() ?? 0,
    );
  }
}
