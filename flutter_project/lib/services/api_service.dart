import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/election.dart';
import 'user_service.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:5052/api';
  final UserService _userService = UserService();
  
  // TODO: Replace with actual auth token management
  String? _authToken;

  void setAuthToken(String token) {
    _authToken = token;
  }

  Future<Map<String, String>> get _headers async {
    final userId = await _userService.getCurrentUserId();
    return {
      'Content-Type': 'application/json',
      if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      if (userId != null) 'X-User-Id': userId,
    };
  }

  // Election endpoints
  
  Future<List<Map<String, dynamic>>> getAllElections() async {
    final headers = await _headers;
    final response = await http.get(
      Uri.parse('$baseUrl/election'),
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    }
    throw Exception('Failed to load elections: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> getElectionById(String id) async {
    print('DEBUG: Getting election by ID: $id'); // Debug log
    final headers = await _headers;
    final response = await http.get(
      Uri.parse('$baseUrl/election/$id'),
      headers: headers,
    );
    
    print('DEBUG: Response status: ${response.statusCode}'); // Debug log
    print('DEBUG: Response body: ${response.body}'); // Debug log
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 404) {
      throw Exception('Election not found');
    }
    throw Exception('Failed to load election: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> getElectionByCode(String code) async {
    final headers = await _headers;
    final response = await http.get(
      Uri.parse('$baseUrl/election/code/$code'),
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 404) {
      throw Exception('Election not found');
    }
    throw Exception('Failed to load election: ${response.statusCode}');
  }

  Future<List<Map<String, dynamic>>> getPublicElections() async {
    final headers = await _headers;
    final response = await http.get(
      Uri.parse('$baseUrl/election/public'),
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    }
    throw Exception('Failed to load public elections: ${response.statusCode}');
  }

  Future<List<Map<String, dynamic>>> getMyElections() async {
    final headers = await _headers;
    final response = await http.get(
      Uri.parse('$baseUrl/election/my'),
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    }
    throw Exception('Failed to load my elections: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> createElection(Map<String, dynamic> electionData) async {
    final headers = await _headers;
    final response = await http.post(
      Uri.parse('$baseUrl/election'),
      headers: headers,
      body: json.encode(electionData),
    );
    
    if (response.statusCode == 201) {
      return json.decode(response.body);
    }
    throw Exception('Failed to create election: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> updateElection(String id, Map<String, dynamic> electionData) async {
    final headers = await _headers;
    final response = await http.put(
      Uri.parse('$baseUrl/election/$id'),
      headers: headers,
      body: json.encode(electionData),
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 404) {
      throw Exception('Election not found');
    }
    throw Exception('Failed to update election: ${response.statusCode}');
  }

  Future<void> deleteElection(String id) async {
    final headers = await _headers;
    final url = '$baseUrl/election/$id';
    print('DEBUG: Attempting DELETE to: $url');
    
    final response = await http.delete(
      Uri.parse(url),
      headers: headers,
    );
    
    print('DEBUG: DELETE response status: ${response.statusCode}');
    print('DEBUG: DELETE response body: ${response.body}');
    
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Failed to delete election: ${response.statusCode}');
    }
  }

  Future<void> joinElection(String id) async {
    final headers = await _headers;
    final response = await http.post(
      Uri.parse('$baseUrl/election/$id/join'),
      headers: headers,
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to join election: ${response.statusCode}');
    }
  }

  Future<void> leaveElection(String id) async {
    final headers = await _headers;
    final response = await http.post(
      Uri.parse('$baseUrl/election/$id/leave'),
      headers: headers,
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to leave election: ${response.statusCode}');
    }
  }

  // Match endpoints

  Future<void> finishMatch(String matchId) async {
    final headers = await _headers;
    final response = await http.post(
      Uri.parse('$baseUrl/match/$matchId/finish'),
      headers: headers,
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to finish match: ${response.statusCode}');
    }
  }

  Future<void> voteInMatch(String matchId, String candidateId) async {
    final headers = await _headers;
    final response = await http.post(
      Uri.parse('$baseUrl/match/$matchId/vote/$candidateId'),
      headers: headers,
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to vote: ${response.statusCode}');
    }
  }

  Future<String?> getUserVoteInMatch(String matchId) async {
    final headers = await _headers;
    final response = await http.get(
      Uri.parse('$baseUrl/match/$matchId/user-vote'),
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['candidateId'];
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getMatchesByElectionId(String electionId) async {
    final headers = await _headers;
    final response = await http.get(
      Uri.parse('$baseUrl/match/election/$electionId'),
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    }
    throw Exception('Failed to load matches: ${response.statusCode}');
  }

  Future<Map<String, dynamic>?> getActiveMatch(String electionId) async {
    final headers = await _headers;
    final response = await http.get(
      Uri.parse('$baseUrl/match/election/$electionId/active'),
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 404) {
      return null;
    }
    throw Exception('Failed to load active match: ${response.statusCode}');
  }

  Future<void> endMatch(String matchId) async {
    final headers = await _headers;
    final response = await http.post(
      Uri.parse('$baseUrl/match/$matchId/end'),
      headers: headers,
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to end match: ${response.statusCode}');
    }
  }
}
