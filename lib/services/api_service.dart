import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  final String _baseUrl = 'https://wildlifenl-uu-michi011.apps.cl01.cp.its.uu.nl/';  // Pas aan naar jouw basis-URL
  final String _token = dotenv.env['API_TOKEN'] ?? 'default_token';


// Login function

Future<Map<String, dynamic>> login(String email) async {
  try {
    final response = await http.post(
      Uri.parse('$_baseUrl/login'),
      body: {
        'email': email,
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('login Failed');
    }
  } catch (e) {
    print('Login error: $e');
    rethrow;
  }
}


// Fetch animal locations
Future<List<dynamic>> fetchAnimalLocations() async {
  try {
    final response = await http.get(
      Uri.parse('$_baseUrl/animals'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      }
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Kan geen dieren locaties ophalen');
    }
  } catch (e) {
    print('Fetch animal locations error: $e');
    rethrow;
  }
}

// Get notifications
Future<List<dynamic>> fetchNotifications(String userId) async {
  try {
    final response = await http.get(
      Uri.parse('$_baseUrl/notifications/$userId'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Kan geen notificaties ophalen');
    }
  } catch (e) {
    print('Fetch notifications error: $e');
    rethrow;
  }
}

}