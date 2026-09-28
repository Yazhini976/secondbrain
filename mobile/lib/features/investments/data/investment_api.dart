import 'package:second_brain/core/network/api_client.dart';
import 'package:second_brain/features/investments/models/investment.dart';

/// Remote data source for Investments API endpoints.
class InvestmentApi {
  final ApiClient _client;

  InvestmentApi({ApiClient? client}) : _client = client ?? ApiClient();

  /// Fetches investments from backend with optional type filtering.
  Future<List<Investment>> getInvestments({String? type}) async {
    final queryParams = <String, String>{};
    if (type != null && type.trim().isNotEmpty) {
      queryParams['type'] = type.trim();
    }

    final response = await _client.get(
      '/investments',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final List<dynamic> list = response as List<dynamic>;
    return list
        .map((json) => Investment.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Fetches single investment details by ID.
  Future<Investment> getInvestment(String id) async {
    final response = await _client.get('/investments/$id');
    return Investment.fromJson(response as Map<String, dynamic>);
  }

  /// Fetches portfolio summary calculated server-side by PostgreSQL.
  Future<InvestmentSummaryData> getInvestmentSummary() async {
    final response = await _client.get('/investments/summary');
    return InvestmentSummaryData.fromJson(response as Map<String, dynamic>);
  }

  /// Creates a new investment record via POST request.
  Future<Investment> createInvestment(Investment investment) async {
    final response = await _client.post('/investments', body: investment.toJson());
    return Investment.fromJson(response as Map<String, dynamic>);
  }

  /// Updates an existing investment record via PATCH request.
  Future<Investment> updateInvestment(Investment investment) async {
    final response =
        await _client.patch('/investments/${investment.id}', body: investment.toJson());
    return Investment.fromJson(response as Map<String, dynamic>);
  }

  /// Deletes an investment record via DELETE request.
  Future<void> deleteInvestment(String id) async {
    await _client.delete('/investments/$id');
  }
}
