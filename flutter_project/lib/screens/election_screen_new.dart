import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../services/user_service.dart';
import '../services/signalr_service.dart';

// Election Screen - View and interact with an election
// Admin: Can vote, finish match, and delete election
// Participant: Can only vote and leave election
class ElectionScreen extends StatefulWidget {
  final String electionId;

  const ElectionScreen({super.key, required this.electionId});

  @override
  State<ElectionScreen> createState() => _ElectionScreenState();
}

class _ElectionScreenState extends State<ElectionScreen> {
  final _apiService = ApiService();
  final _userService = UserService();
  final _signalRService = SignalRService();
  Map<String, dynamic>? _election;
  List<dynamic>? _matches;
  Map<String, dynamic>? _activeMatch;
  bool _isLoading = true;
  bool _isEndingMatch = false;
  String? _currentUserId;
  String? _userVotedCandidateId; // Track which candidate user voted for
  
  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  @override
  void dispose() {
    _signalRService.disconnect();
    super.dispose();
  }

  Future<void> _initializeUser() async {
    _currentUserId = await _userService.getCurrentUserId();
    await _loadElection();
    
    // Connect to SignalR for real-time updates
    await _signalRService.connect(widget.electionId, () {
      print('SignalR: Match ended notification - refreshing election');
      _loadElection();
    });
  }

  Future<void> _loadElection() async {
    setState(() => _isLoading = true);
    try {
      print('DEBUG ElectionScreen: Loading election with ID: ${widget.electionId}'); // Debug
      final election = await _apiService.getElectionById(widget.electionId);
      print('DEBUG ElectionScreen: Got election: ${election['name']}'); // Debug
      final matches = await _apiService.getMatchesByElectionId(widget.electionId);
      print('DEBUG ElectionScreen: Got ${matches.length} matches'); // Debug
      
      // Load active match
      final activeMatch = await _apiService.getActiveMatch(widget.electionId);
      print('DEBUG ElectionScreen: Active match: $activeMatch'); // Debug
      
      // Check if user has already voted in active match
      String? votedCandidateId;
      if (activeMatch != null) {
        try {
          votedCandidateId = await _apiService.getUserVoteInMatch(activeMatch['id']);
        } catch (e) {
          print('DEBUG: Error getting user vote: $e');
          votedCandidateId = null;
        }
      }
      
      setState(() {
        _election = election;
        _matches = matches;
        _activeMatch = activeMatch;
        _userVotedCandidateId = votedCandidateId;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading election: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  bool get _isAdmin {
    final adminId = _election?['adminId'];
    print('DEBUG: adminId=$adminId, currentUserId=$_currentUserId, isAdmin=${adminId == _currentUserId}');
    return adminId == _currentUserId;
  }
  bool get _isActive => _election?['status'] == 0; // 0 = Active, 1 = Ended

  Future<void> _leaveElection() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Election'),
        content: const Text('Are you sure you want to leave this election?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _apiService.leaveElection(widget.electionId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Left election')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error leaving election: $e')),
        );
      }
    }
  }

  Future<void> _finishMatch(String matchId) async {
    try {
      await _apiService.finishMatch(matchId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Match finished')),
        );
        _loadElection();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error finishing match: $e')),
        );
      }
    }
  }

  Future<void> _vote(String matchId, String candidateId) async {
    try {
      await _apiService.voteInMatch(matchId, candidateId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vote recorded')),
        );
        _loadElection();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error voting: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _election == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_election!['name']),
        actions: [
          if (!_election!['isPublic'] && _election!['code'].isNotEmpty)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _election!['code']));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Code ${_election!['code']} copied!')),
                );
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadElection,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Election Info Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _election!['name'],
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      if (_election!['description']?.isNotEmpty ?? false) ...[
                        const SizedBox(height: 8),
                        Text(_election!['description']),
                      ],
                      if (_isAdmin) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.admin_panel_settings, size: 16),
                            const SizedBox(width: 4),
                            const Text('Admin'),
                          ],
                        ),
                      ],
                      if (!_isActive) ...[
                        const SizedBox(height: 8),
                        const Chip(
                          label: Text('ENDED'),
                          backgroundColor: Colors.grey,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Current Match / Voting Area
              if (_isActive && _activeMatch != null) ...[
                const Text(
                  'Current Match',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildCurrentMatch(),
              ],

              const SizedBox(height: 16),

              // Candidates / Standings
              if (_election!['candidates'] != null && _election!['candidates'].isNotEmpty) ...[
                const Text(
                  'Standings',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildStandings(),
              ],

              const SizedBox(height: 16),

              // Actions
              if (_isActive) ...[
                if (_isAdmin) ...[
                  // Admin actions
                  ElevatedButton.icon(
                    onPressed: () => _showAbandonConfirmation(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.block),
                    label: const Text('Abandon Election'),
                  ),
                  const SizedBox(height: 8),
                ] else ...[
                  // Participant actions
                  OutlinedButton.icon(
                    onPressed: _leaveElection,
                    icon: const Icon(Icons.exit_to_app),
                    label: const Text('Leave Election'),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentMatch() {
    if (_activeMatch == null) {
      // Check if tournament is finished - show final results
      if (_matches != null && _matches!.isNotEmpty) {
        final allFinished = _matches!.every((m) => m['isFinished'] == true);
        if (allFinished) {
          return _buildFinalResults();
        }
      }
      
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No active match', textAlign: TextAlign.center),
        ),
      );
    }

    // Get candidates from active match
    final matchCandidates = _activeMatch!['candidates'] as List<dynamic>? ?? [];
    
    if (matchCandidates.length < 2) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Waiting for candidates...', textAlign: TextAlign.center),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Match ${_activeMatch!['matchIndex']} - Round ${_activeMatch!['roundNumber']}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            // Show candidates
            Row(
              children: [
                Expanded(
                  child: _buildCandidateCard(matchCandidates[0]),
                ),
                const SizedBox(width: 16),
                const Text('VS', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildCandidateCard(matchCandidates[1]),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Admin actions
            if (_isAdmin && _isActive) ...[
              ElevatedButton.icon(
                onPressed: _isEndingMatch ? null : () => _showEndMatchDialog(matchCandidates),
                icon: _isEndingMatch 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check_circle),
                label: Text(_isEndingMatch ? 'Ending Match...' : 'End Match'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCandidateCard(Map<String, dynamic> candidate) {
    final candidateId = candidate['id'];
    final hasVoted = _userVotedCandidateId != null;
    final votedForThis = _userVotedCandidateId == candidateId;
    final electionType = _election?['electionType'] ?? 0;
    
    // Check if user can vote/change vote
    // Legacy Multiple Votes (1) and Legacy Weighted Votes (2) allow multiple votes
    final canChangeVote = electionType == 1 || electionType == 2;
    final canVote = _isActive && (!hasVoted || canChangeVote || votedForThis); // Only allow voting if election is active
    
    return Card(
      elevation: votedForThis ? 8 : 4,
      color: votedForThis ? Colors.green.shade50 : (_isActive ? null : Colors.grey.shade200),
      child: InkWell(
        onTap: canVote ? () => _voteForCandidate(candidateId) : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: votedForThis ? BoxDecoration(
            border: Border.all(color: Colors.green, width: 3),
            borderRadius: BorderRadius.circular(12),
          ) : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  candidate['name'] ?? 'Unknown',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: votedForThis ? Colors.green.shade900 : (_isActive ? null : Colors.grey),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Icon(
                  votedForThis ? Icons.check_circle : Icons.how_to_vote,
                  size: 32,
                  color: votedForThis ? Colors.green : (_isActive ? null : Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  !_isActive ? 'Election Ended' : (votedForThis ? 'Your Vote' : (canVote ? 'Tap to Vote' : 'Already Voted')),
                  style: TextStyle(
                    fontSize: 12,
                    color: votedForThis ? Colors.green.shade700 : Colors.grey,
                    fontWeight: votedForThis ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _voteForCandidate(String candidateId) async {
    // Check if election is still active
    if (!_isActive) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This election has ended. Voting is no longer allowed.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
    
    if (_activeMatch == null) return;

    try {
      await _apiService.voteInMatch(_activeMatch!['id'], candidateId);
      
      // Update local state to show vote immediately
      setState(() {
        _userVotedCandidateId = candidateId;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vote recorded!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error voting: $e')),
        );
      }
    }
  }

  Future<void> _showEndMatchDialog(List<dynamic> matchCandidates) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Match'),
        content: const Text(
          'Are you sure you want to end this match?\n\n'
          'The winner will be determined by vote count.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('End Match'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _endMatch();
    }
  }

  Future<void> _endMatch() async {
    if (_activeMatch == null) return;

    setState(() => _isEndingMatch = true);
    try {
      await _apiService.endMatch(_activeMatch!['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Match ended successfully!')),
        );
        // Reset vote state before loading new match
        setState(() => _userVotedCandidateId = null);
        await _loadElection(); // Reload to get new active match
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error ending match: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isEndingMatch = false);
      }
    }
  }

  Widget _buildFinalResults() {
    // Get winner from matches (last match winner)
    final finishedMatches = _matches!.where((m) => m['isFinished'] == true).toList();
    
    // Build ranking based on knockout progression
    final candidates = List<Map<String, dynamic>>.from(_election!['candidates']);
    
    // Sort by points (which should represent wins/progression)
    candidates.sort((a, b) => (b['points'] as int).compareTo(a['points'] as int));
    
    // Find the final match (highest round number)
    final maxRound = finishedMatches.isEmpty ? 0 : 
        finishedMatches.map((m) => m['roundNumber'] as int).reduce((a, b) => a > b ? a : b);
    final finalMatch = finishedMatches.where((m) => m['roundNumber'] == maxRound).firstOrNull;
    
    final winnerId = finalMatch?['winnerId'];
    
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.emoji_events, size: 64, color: Colors.amber),
            const SizedBox(height: 16),
            const Text(
              'Tournament Finished!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Final Rankings',
              style: TextStyle(fontSize: 18, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // Top 3 podium
            if (candidates.isNotEmpty) ...[
              _buildPodium(candidates, winnerId),
              const SizedBox(height: 24),
              
              // Full rankings
              ...candidates.asMap().entries.map((entry) {
                final index = entry.key;
                final candidate = entry.value;
                final isWinner = candidate['id'] == winnerId;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isWinner ? Colors.amber.shade100 : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isWinner ? Colors.amber : Colors.grey.shade300,
                      width: isWinner ? 2 : 1,
                    ),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getRankColor(index),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(
                          candidate['name'],
                          style: TextStyle(
                            fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                            fontSize: isWinner ? 18 : 16,
                          ),
                        ),
                        if (isWinner) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.emoji_events, color: Colors.amber, size: 20),
                        ],
                      ],
                    ),
                    trailing: Text(
                      '${candidate['points']} pts',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isWinner ? Colors.amber.shade900 : Colors.grey.shade700,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPodium(List<Map<String, dynamic>> candidates, String? winnerId) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 2nd place
        if (candidates.length > 1)
          _buildPodiumPlace(candidates[1], 2, 100, Colors.grey),
        const SizedBox(width: 8),
        // 1st place
        if (candidates.isNotEmpty)
          _buildPodiumPlace(candidates[0], 1, 140, Colors.amber),
        const SizedBox(width: 8),
        // 3rd place
        if (candidates.length > 2)
          _buildPodiumPlace(candidates[2], 3, 80, Colors.brown.shade300),
      ],
    );
  }

  Widget _buildPodiumPlace(Map<String, dynamic> candidate, int place, double height, Color color) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '$place',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 80,
          child: Text(
            candidate['name'],
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 80,
          height: height,
          decoration: BoxDecoration(
            color: color.withOpacity(0.7),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Text(
              '${candidate['points']}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getRankColor(int index) {
    switch (index) {
      case 0:
        return Colors.amber;
      case 1:
        return Colors.grey.shade600;
      case 2:
        return Colors.brown.shade400;
      default:
        return Colors.blue.shade400;
    }
  }

  Widget _buildStandings() {
    final candidates = List<Map<String, dynamic>>.from(_election!['candidates']);
    candidates.sort((a, b) => (b['points'] as int).compareTo(a['points'] as int));

    return Card(
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: candidates.length,
        itemBuilder: (context, index) {
          final candidate = candidates[index];
          return ListTile(
            leading: CircleAvatar(
              child: Text('${index + 1}'),
            ),
            title: Text(candidate['name']),
            trailing: Text(
              '${candidate['points']} pts',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          );
        },
      ),
    );
  }

  void _showAbandonConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Abandon Election'),
        content: const Text(
          'Are you sure? This will end the election immediately. '
          'Users will no longer be able to join or vote.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _abandonElection();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Abandon'),
          ),
        ],
      ),
    );
  }

  Future<void> _abandonElection() async {
    try {
      print('DEBUG: Attempting to abandon election: ${widget.electionId}');
      await _apiService.deleteElection(widget.electionId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Election abandoned'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.pop(context); // Return to previous screen
      }
    } catch (e) {
      print('DEBUG: Error abandoning election: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error abandoning election: $e')),
        );
      }
    }
  }
}
