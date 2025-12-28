import 'package:flutter/material.dart';
import '../services/api_service.dart';

String _getElectionTypeName(int type) {
  switch (type) {
    case 0: return 'Legacy (Single Vote)';
    case 1: return 'Legacy (Multiple Votes)';
    case 2: return 'Legacy (Weighted Votes)';
    case 3: return 'Knockout';
    case 4: return 'Group Then Knockout';
    case 5: return 'League';
    case 6: return 'Group Then League';
    default: return 'Unknown';
  }
}

// Join Public Screen - Shows list of all public elections
class JoinPublicScreen extends StatefulWidget {
  const JoinPublicScreen({super.key});

  @override
  State<JoinPublicScreen> createState() => _JoinPublicScreenState();
}

class _JoinPublicScreenState extends State<JoinPublicScreen> {
  final _apiService = ApiService();
  List<Map<String, dynamic>>? _elections;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPublicElections();
  }

  Future<void> _loadPublicElections() async {
    setState(() => _isLoading = true);
    try {
      final elections = await _apiService.getPublicElections();
      setState(() {
        _elections = elections;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading elections: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _joinElection(String id) async {
    try {
      // First get election details to check status
      final election = await _apiService.getElectionById(id);
      
      // Check if election is active (status = 0)
      if (election['status'] != 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This election has ended. You cannot join.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      
      await _apiService.joinElection(id);
      if (mounted) {
        Navigator.pushNamed(context, '/election/$id');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error joining election: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Public Elections'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _elections == null || _elections!.isEmpty
              ? const Center(child: Text('No public elections available'))
              : RefreshIndicator(
                  onRefresh: _loadPublicElections,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _elections!.length,
                    itemBuilder: (context, index) {
                      final election = _elections![index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(
                            election['name'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (election['description']?.isNotEmpty ?? false)
                                Text(election['description']),
                              const SizedBox(height: 4),
                              Text(
                                _getElectionTypeName(election['electionType']),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.arrow_forward),
                          onTap: () => _joinElection(election['id']),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
