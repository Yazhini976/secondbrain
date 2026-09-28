import 'package:second_brain/core/network/api_client.dart';
import 'package:second_brain/features/reminders/models/reminder.dart';

/// Remote data source for Reminders API endpoints.
class ReminderApi {
  final ApiClient _client;

  ReminderApi({ApiClient? client}) : _client = client ?? ApiClient();

  /// Fetches reminders from backend with optional category filtering.
  Future<List<Reminder>> getReminders({String? category}) async {
    final queryParams = <String, String>{};
    if (category != null && category.trim().isNotEmpty) {
      queryParams['category'] = category.trim();
    }

    final response = await _client.get(
      '/reminders',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final List<dynamic> list = response as List<dynamic>;
    return list
        .map((json) => Reminder.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Fetches a single reminder by ID.
  Future<Reminder> getReminder(String id) async {
    final response = await _client.get('/reminders/$id');
    return Reminder.fromJson(response as Map<String, dynamic>);
  }

  /// Creates a new reminder via POST request.
  Future<Reminder> createReminder(Reminder reminder) async {
    final response = await _client.post('/reminders', body: reminder.toJson());
    return Reminder.fromJson(response as Map<String, dynamic>);
  }

  /// Updates an existing reminder via PATCH request.
  Future<Reminder> updateReminder(Reminder reminder) async {
    final response =
        await _client.patch('/reminders/${reminder.id}', body: reminder.toJson());
    return Reminder.fromJson(response as Map<String, dynamic>);
  }

  /// Deletes a reminder via DELETE request.
  Future<void> deleteReminder(String id) async {
    await _client.delete('/reminders/$id');
  }
}
