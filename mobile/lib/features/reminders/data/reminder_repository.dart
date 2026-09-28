import 'package:flutter/foundation.dart';
import 'package:second_brain/features/reminders/data/reminder_api.dart';
import 'package:second_brain/features/reminders/models/reminder.dart';

/// Reminder Repository.
/// Domain layer abstraction between Flutter UI and FastAPI + PostgreSQL backend.
/// Extends [ChangeNotifier] to broadcast real-time state changes to the UI.
class ReminderRepository extends ChangeNotifier {
  static final ReminderRepository instance = ReminderRepository._internal();

  final ReminderApi _api;
  List<Reminder> _reminders = [];
  bool _isLoading = false;
  String? _errorMessage;

  ReminderRepository._internal({ReminderApi? api})
      : _api = api ?? ReminderApi() {
    _reminders = [];
  }

  factory ReminderRepository({ReminderApi? api}) {
    return ReminderRepository._internal(api: api);
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<Reminder> getAll() => List.unmodifiable(_reminders);
  List<Reminder> getReminders() => getAll();

  /// Clears in-memory reminders when switching users or logging out.
  void clear() {
    _reminders = [];
    _errorMessage = null;
    notifyListeners();
  }

  /// Loads reminders from backend API with optional category filter.
  Future<List<Reminder>> loadReminders({String? category}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final remoteList = await _api.getReminders(category: category);
      _reminders = remoteList;
      _isLoading = false;
      notifyListeners();
      return _reminders;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('ApiException: ', '');
      _isLoading = false;
      notifyListeners();
      return getAll();
    }
  }

  Reminder? getById(String id) {
    try {
      return _reminders.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Adds a reminder via backend API and updates local state.
  Future<Reminder> add(Reminder reminder) async {
    final existingIdx = _reminders.indexWhere((r) => r.id == reminder.id);
    if (existingIdx == -1) {
      _reminders.add(reminder);
    }
    notifyListeners();

    try {
      final created = await _api.createReminder(reminder);
      final idx = _reminders.indexWhere((r) => r.id == reminder.id || r.id == created.id);
      if (idx != -1) {
        _reminders[idx] = created;
      } else {
        _reminders.add(created);
      }
      notifyListeners();
      return created;
    } catch (e) {
      return reminder;
    }
  }

  Future<Reminder> addReminder(Reminder reminder) => add(reminder);

  /// Updates a reminder via backend API and updates local state.
  Future<Reminder> update(Reminder reminder) async {
    final idx = _reminders.indexWhere((r) => r.id == reminder.id);
    if (idx != -1) {
      _reminders[idx] = reminder;
    } else {
      _reminders.add(reminder);
    }
    notifyListeners();

    try {
      final serverUpdated = await _api.updateReminder(reminder);
      final index = _reminders.indexWhere((r) => r.id == serverUpdated.id);
      if (index != -1) {
        _reminders[index] = serverUpdated;
      } else {
        _reminders.add(serverUpdated);
      }
      notifyListeners();
      return serverUpdated;
    } catch (e) {
      return reminder;
    }
  }

  Future<Reminder> updateReminder(Reminder reminder) => update(reminder);

  /// Deletes a reminder via backend API and updates local state.
  Future<void> delete(String id) async {
    _reminders.removeWhere((r) => r.id == id);
    notifyListeners();

    try {
      await _api.deleteReminder(id);
    } catch (_) {}
  }

  Future<void> deleteReminder(String id) => delete(id);

  /// Toggles completion status of a reminder and syncs to backend.
  Future<void> toggleComplete(String id) async {
    final idx = _reminders.indexWhere((r) => r.id == id);
    if (idx != -1) {
      final current = _reminders[idx];
      final updated = current.copyWith(
        isCompleted: !current.isCompleted,
        updatedAt: DateTime.now(),
      );
      await update(updated);
    }
  }

  /// Marks completion status of a reminder and syncs to backend.
  Future<void> markComplete(String id, bool isCompleted) async {
    final idx = _reminders.indexWhere((r) => r.id == id);
    if (idx != -1) {
      final current = _reminders[idx];
      if (current.isCompleted != isCompleted) {
        final updated = current.copyWith(
          isCompleted: isCompleted,
          updatedAt: DateTime.now(),
        );
        await update(updated);
      }
    }
  }

  /// Resets to default sample reminders for tests.
  void resetSampleData() {
    _reminders.clear();
    _reminders.addAll(_generateSampleReminders());
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}

List<Reminder> _generateSampleReminders() {
  final now = DateTime.now();
  final todayDate = DateTime(now.year, now.month, now.day);

  return [
    Reminder(
      id: 'rem_001',
      title: 'Pay monthly chit installment',
      description: 'Transfer monthly installment to chit account before 8 PM',
      dueDate: todayDate,
      reminderDateTime: DateTime(todayDate.year, todayDate.month, todayDate.day, 18, 0),
      category: ReminderCategory.investment,
      priority: ReminderPriority.high,
      isCompleted: false,
      linkedEntityType: 'investment',
      linkedEntityId: 'inv_002',
    ),
    Reminder(
      id: 'rem_002',
      title: 'Renew vehicle insurance',
      description: 'Comprehensive car policy expired on weekend',
      dueDate: todayDate.subtract(const Duration(days: 3)),
      reminderDateTime: DateTime(
        todayDate.year,
        todayDate.month,
        todayDate.day - 3,
        10,
        0,
      ),
      category: ReminderCategory.document,
      priority: ReminderPriority.high,
      isCompleted: false,
      linkedEntityType: 'document',
      linkedEntityId: 'doc_007',
    ),
    Reminder(
      id: 'rem_003',
      title: 'Call service center',
      description: 'Schedule annual vehicle service and oil inspection',
      dueDate: todayDate.add(const Duration(days: 2)),
      reminderDateTime: DateTime(
        todayDate.year,
        todayDate.month,
        todayDate.day + 2,
        14,
        0,
      ),
      category: ReminderCategory.personal,
      priority: ReminderPriority.medium,
      isCompleted: false,
    ),
    Reminder(
      id: 'rem_004',
      title: 'Review savings plan',
      description: 'Check quarterly PPF and mutual fund SIP allocation',
      dueDate: todayDate.add(const Duration(days: 5)),
      reminderDateTime: DateTime(
        todayDate.year,
        todayDate.month,
        todayDate.day + 5,
        10,
        30,
      ),
      category: ReminderCategory.investment,
      priority: ReminderPriority.low,
      isCompleted: false,
    ),
    Reminder(
      id: 'rem_005',
      title: 'Health Insurance Policy Renewal',
      description: 'Annual premium due for Star Health Family Floater',
      dueDate: todayDate.add(const Duration(days: 12)),
      reminderDateTime: DateTime(
        todayDate.year,
        todayDate.month,
        todayDate.day + 12,
        11,
        0,
      ),
      category: ReminderCategory.document,
      priority: ReminderPriority.high,
      isCompleted: false,
      linkedEntityType: 'document',
      linkedEntityId: 'doc_006',
    ),
    Reminder(
      id: 'rem_006',
      title: 'Submit college document',
      description: 'Submitted verified copy of degree certificate to HR portal',
      dueDate: todayDate.subtract(const Duration(days: 1)),
      reminderDateTime: DateTime(
        todayDate.year,
        todayDate.month,
        todayDate.day - 1,
        15,
        0,
      ),
      category: ReminderCategory.personal,
      priority: ReminderPriority.medium,
      isCompleted: true,
      createdAt: now.subtract(const Duration(days: 4)),
      updatedAt: now.subtract(const Duration(hours: 18)),
    ),
  ];
}
