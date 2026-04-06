import 'api_client.dart';

class StatsApi {
  Future<Map<String, dynamic>> monthly(
      {required int year, required int month}) async {
    return ApiClient.instance.get('/stats/monthly?year=$year&month=$month');
  }
}
