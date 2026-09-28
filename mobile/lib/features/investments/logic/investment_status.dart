/// Derived status of an investment — never stored, always calculated.
enum InvestmentStatus { onTrack, dueSoon, overdue, completed }

extension InvestmentStatusExtension on InvestmentStatus {
  String get label {
    switch (this) {
      case InvestmentStatus.onTrack:
        return 'On Track';
      case InvestmentStatus.dueSoon:
        return 'Due Soon';
      case InvestmentStatus.overdue:
        return 'Overdue';
      case InvestmentStatus.completed:
        return 'Completed';
    }
  }

  static InvestmentStatus fromString(String? raw) {
    if (raw == null) return InvestmentStatus.onTrack;
    switch (raw.trim().toLowerCase()) {
      case 'completed':
        return InvestmentStatus.completed;
      case 'overdue':
        return InvestmentStatus.overdue;
      case 'due soon':
      case 'duesoon':
        return InvestmentStatus.dueSoon;
      case 'on track':
      case 'ontrack':
      default:
        return InvestmentStatus.onTrack;
    }
  }
}

/// Deterministic status logic.
///
/// Rules (evaluated in priority order):
/// 1. Completed  — installmentsPaid >= totalInstallments
/// 2. Overdue    — nextDueDate is in the past (before today's start)
/// 3. Due Soon   — nextDueDate is within the next 5 days
/// 4. On Track   — otherwise
InvestmentStatus deriveStatus({
  required int installmentsPaid,
  required int totalInstallments,
  required DateTime? nextDueDate,
}) {
  if (totalInstallments > 0 && installmentsPaid >= totalInstallments) {
    return InvestmentStatus.completed;
  }

  if (nextDueDate != null) {
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final due = DateTime(nextDueDate.year, nextDueDate.month, nextDueDate.day);

    if (due.isBefore(today)) {
      return InvestmentStatus.overdue;
    }

    const dueSoonDays = 5;
    final diff = due.difference(today).inDays;
    if (diff >= 0 && diff <= dueSoonDays) {
      return InvestmentStatus.dueSoon;
    }
  }

  return InvestmentStatus.onTrack;
}
