import 'dart:convert';
import 'package:http/http.dart' as http;

class HomeAssistantApi {
  final String baseUrl;
  final String accessToken;

  HomeAssistantApi(this.baseUrl, this.accessToken);

  Future<void> createOrUpdateState(String entityId, Map<String, dynamic> stateData) async {
    final url = '$baseUrl/api/states/$entityId';
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(stateData),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update state: ${response.body}');
    }
  }
}
