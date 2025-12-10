import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class LocationService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  static Future<List<Map<String, dynamic>>> getLocations({bool includeInactive = false}) async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final url = '$baseUrl/api/locations?include_inactive=$includeInactive';
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => Map<String, dynamic>.from(item)).toList();
    } else {
      throw Exception('Failed to load locations: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> addLocation(String name, {String? description}) async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/api/locations'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'name': name,
        'description': description,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      final error = json.decode(response.body);
      throw Exception(error['detail'] ?? 'Failed to add location');
    }
  }

  static Future<void> updateLocation(
    int locationId, {
    String? name,
    String? description,
    bool? isActive,
  }) async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;
    if (isActive != null) body['is_active'] = isActive;

    final response = await http.put(
      Uri.parse('$baseUrl/api/locations/$locationId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(body),
    );

    if (response.statusCode != 200) {
      final error = json.decode(response.body);
      throw Exception(error['detail'] ?? 'Failed to update location');
    }
  }

  static Future<void> deleteLocation(int locationId) async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.delete(
      Uri.parse('$baseUrl/api/locations/$locationId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      final error = json.decode(response.body);
      throw Exception(error['detail'] ?? 'Failed to delete location');
    }
  }
}
