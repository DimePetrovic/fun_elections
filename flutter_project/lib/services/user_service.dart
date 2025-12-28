import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  static const String baseUrl = 'http://localhost:5052/api';
  static const String _userIdKey = 'user_id';
  static const String _usernameKey = 'username';

  // Get or create user
  Future<Map<String, String>> getOrCreateUser() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if user already exists locally
    String? userId = prefs.getString(_userIdKey);
    String? username = prefs.getString(_usernameKey);
    
    if (userId != null && username != null) {
      // User exists, verify with backend
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/user/$userId'),
        );
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          return {
            'userId': data['userId'],
            'username': data['username'],
          };
        }
      } catch (e) {
        print('Error verifying user: $e');
      }
    }
    
    // Create new user
    return await _registerNewUser();
  }

  Future<Map<String, String>> _registerNewUser() async {
    try {
      // Generate random username and password
      final randomId = DateTime.now().millisecondsSinceEpoch.toString();
      final username = 'User$randomId';
      final password = 'Pass123!$randomId';
      
      final response = await http.post(
        Uri.parse('$baseUrl/user/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'displayName': username,
          'email': '$username@temp.com',
          'password': password,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final userId = data['userId'];
        final displayName = data['displayName'] ?? data['username'];
        
        // Save locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userIdKey, userId);
        await prefs.setString(_usernameKey, displayName);
        
        return {
          'userId': userId,
          'username': displayName,
        };
      }
      
      throw Exception('Failed to register user: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error registering user: $e');
    }
  }

  Future<bool> updateUsername(String userId, String newUsername) async {
    try {
      if (newUsername.isEmpty || newUsername.length > 16) {
        return false;
      }

      final response = await http.put(
        Uri.parse('$baseUrl/user/$userId/username'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'username': newUsername}),
      );
      
      if (response.statusCode == 200) {
        // Update locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_usernameKey, newUsername);
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error updating username: $e');
      return false;
    }
  }

  Future<bool> checkUsernameAvailability(String username) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/check-username/$username'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['available'] ?? false;
      }
      
      return false;
    } catch (e) {
      print('Error checking username: $e');
      return false;
    }
  }

  Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  Future<String?> getCurrentUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }
}
