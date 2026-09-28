/// Derived document status — never stored, always calculated from dates.
enum DocumentStatus { active, expiringSoon, expired }

extension DocumentStatusExtension on DocumentStatus {
  String get label {
    switch (this) {
      case DocumentStatus.active:
        return 'Active';
      case DocumentStatus.expiringSoon:
        return 'Expiring Soon';
      case DocumentStatus.expired:
        return 'Expired';
    }
  }
}

/// Number of days before expiry at which a document is considered 'expiring soon'.
const int _expiringSoonDays = 30;

/// Deterministic document status logic.
///
/// Rules (in priority order):
/// 1. If expiryDate is null → Active (no expiry to track)
/// 2. If expiryDate is before today → Expired
/// 3. If expiryDate is within [_expiringSoonDays] days → Expiring Soon
/// 4. Otherwise → Active
DocumentStatus deriveDocumentStatus({required DateTime? expiryDate}) {
  if (expiryDate == null) return DocumentStatus.active;

  final today = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );
  final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);

  if (expiry.isBefore(today)) return DocumentStatus.expired;

  if (expiry.difference(today).inDays <= _expiringSoonDays) {
    return DocumentStatus.expiringSoon;
  }

  return DocumentStatus.active;
}

/// Unified document status calculation alias requested by Step 8E.
DocumentStatus calculateDocumentStatus(DateTime? expiryDate) =>
    deriveDocumentStatus(expiryDate: expiryDate);

/// Reusable helper to format human-readable relative expiry text.
/// Uses date-only normalization to avoid time-of-day discrepancy bugs.
String getDocumentExpiryRelativeText(DateTime expiryDate) {
  final today = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );
  final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
  final diffDays = expiry.difference(today).inDays;

  if (diffDays < 0) {
    final absDays = diffDays.abs();
    return absDays == 1 ? 'Expired yesterday' : 'Expired $absDays days ago';
  } else if (diffDays == 0) {
    return 'Expires today';
  } else if (diffDays == 1) {
    return 'Expires tomorrow';
  } else {
    return 'Expires in $diffDays days';
  }
}

