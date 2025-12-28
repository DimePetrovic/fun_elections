import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/election.dart';

// ElectionStore manages all elections and their state
// Using Provider + ChangeNotifier for simplicity
// TODO: Replace with backend API calls when integrating with server
class ElectionStore extends ChangeNotifier {
  final List<Election> _elections = [];
  final String _currentUserId = 'user123'; // Mock user ID
  final _uuid = const Uuid();

  ElectionStore() {
    // No mock data - start with empty elections list
  }

  List<Election> get elections => _elections;
  String get currentUserId => _currentUserId;

  List<Election> get publicElections =>
      _elections.where((e) => e.isPublic).toList();

  List<Election> get createdElections =>
      _elections.where((e) => e.creatorId == _currentUserId).toList();

  List<Election> get participatingElections => _elections
      .where((e) =>
          e.participantIds.contains(_currentUserId) &&
          e.creatorId != _currentUserId)
      .toList();

  List<Election> get endedElections =>
      _elections.where((e) => e.isEnded).toList();

  Election? getElectionById(String id) {
    try {
      return _elections.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  Election? getElectionByCode(String code) {
    try {
      return _elections.firstWhere((e) => e.code == code && !e.isPublic);
    } catch (_) {
      return null;
    }
  }

  // Create a new election
  String createElection({
    required String name,
    required String description,
    required ElectionFormat format,
    required List<String> competitorNames,
    bool isPublic = true,
    int? numberOfGroups,
    bool hasWeightedGroups = false,
    LegacySubformat? legacySubformat,
    int? legacyVoteCount,
  }) {
    final id = _uuid.v4();
    final code = isPublic ? '' : _generateCode();

    // Create competitors
    final competitors = competitorNames
        .map((name) => Competitor(
              id: _uuid.v4(),
              name: name,
            ))
        .toList();

    // Generate structure based on format
    List<Round> rounds = [];
    List<Group> groups = [];

    switch (format) {
      case ElectionFormat.knockout:
        rounds = _generateKnockoutRounds(competitors);
        break;
      case ElectionFormat.group:
        groups = _generateGroups(competitors, numberOfGroups ?? 1);
        // TODO: Generate matches within groups
        break;
      case ElectionFormat.league:
        rounds = _generateLeagueRounds(competitors);
        break;
      case ElectionFormat.legacy:
        // Legacy format doesn't need rounds/groups
        break;
    }

    final election = Election(
      id: id,
      name: name,
      description: description,
      format: format,
      code: code,
      creatorId: _currentUserId,
      isPublic: isPublic,
      createdAt: DateTime.now(),
      competitors: competitors,
      groups: groups,
      hasWeightedGroups: hasWeightedGroups,
      rounds: rounds,
      legacySubformat: legacySubformat,
      legacyVoteCount: legacyVoteCount,
      participantIds: [_currentUserId],
    );

    _elections.add(election);
    notifyListeners();
    return id;
  }

  // Join a public election
  bool joinPublicElection(String id) {
    final election = getElectionById(id);
    if (election == null || !election.isPublic) return false;

    if (!election.participantIds.contains(_currentUserId)) {
      final index = _elections.indexOf(election);
      _elections[index] = election.copyWith(
        participantIds: [...election.participantIds, _currentUserId],
      );
      notifyListeners();
    }
    return true;
  }

  // Join a private election with code
  String? joinPrivateElection(String code) {
    final election = getElectionByCode(code);
    if (election == null) return null;

    if (!election.participantIds.contains(_currentUserId)) {
      final index = _elections.indexOf(election);
      _elections[index] = election.copyWith(
        participantIds: [...election.participantIds, _currentUserId],
      );
      notifyListeners();
    }
    return election.id;
  }

  // Randomize competitors order
  void randomizeCompetitors(String electionId) {
    final election = getElectionById(electionId);
    if (election == null) return;

    final shuffled = List<Competitor>.from(election.competitors)..shuffle();
    final index = _elections.indexOf(election);
    _elections[index] = election.copyWith(competitors: shuffled);

    // Regenerate rounds/groups with new order
    if (election.format == ElectionFormat.knockout) {
      _elections[index] = _elections[index].copyWith(
        rounds: _generateKnockoutRounds(shuffled),
      );
    }

    notifyListeners();
  }

  // Reorder competitors manually
  void reorderCompetitors(String electionId, int oldIndex, int newIndex) {
    final election = getElectionById(electionId);
    if (election == null) return;

    final competitors = List<Competitor>.from(election.competitors);
    if (newIndex > oldIndex) newIndex--;
    final item = competitors.removeAt(oldIndex);
    competitors.insert(newIndex, item);

    final index = _elections.indexOf(election);
    _elections[index] = election.copyWith(competitors: competitors);

    // Regenerate structure with new order
    if (election.format == ElectionFormat.knockout) {
      _elections[index] = _elections[index].copyWith(
        rounds: _generateKnockoutRounds(competitors),
      );
    }

    notifyListeners();
  }

  // Cast a vote in current match
  // Returns true if vote was successful, false if user already voted
  bool vote(String electionId, String competitorId) {
    final election = getElectionById(electionId);
    if (election == null) return false;

    // For legacy format, check if user already voted
    if (election.format == ElectionFormat.legacy) {
      if (election.legacyVotedUserIds.contains(currentUserId)) {
        return false; // User already voted
      }
      
      // Update competitor votes
      final competitorIndex = election.competitors.indexWhere((c) => c.id == competitorId);
      if (competitorIndex == -1) return false;
      
      final updatedCompetitors = List<Competitor>.from(election.competitors);
      updatedCompetitors[competitorIndex] = updatedCompetitors[competitorIndex].copyWith(
        points: updatedCompetitors[competitorIndex].points + 1,
      );
      
      // Mark user as voted
      final updatedVotedUserIds = Set<String>.from(election.legacyVotedUserIds)..add(currentUserId);
      
      final index = _elections.indexOf(election);
      _elections[index] = election.copyWith(
        competitors: updatedCompetitors,
        legacyVotedUserIds: updatedVotedUserIds,
      );
      notifyListeners();
      return true;
    }

    // For knockout/league formats, check current match
    final currentMatch = election.currentMatch;
    if (currentMatch == null) return false;
    
    // Check if user already voted in this match
    if (currentMatch.votedUserIds.contains(currentUserId)) {
      return false; // User already voted in this match
    }

    final votes = Map<String, int>.from(currentMatch.votes);
    votes[competitorId] = (votes[competitorId] ?? 0) + 1;
    
    final updatedVotedUserIds = Set<String>.from(currentMatch.votedUserIds)..add(currentUserId);

    _updateMatch(
      election, 
      currentMatch.id, 
      currentMatch.copyWith(
        votes: votes,
        votedUserIds: updatedVotedUserIds,
      ),
    );
    return true;
  }

  // Move to next match
  void nextMatch(String electionId) {
    final election = getElectionById(electionId);
    if (election == null) return;

    final index = _elections.indexOf(election);
    var newMatchIndex = election.currentMatchIndex + 1;
    var newRoundIndex = election.currentRoundIndex;

    if (election.rounds.isNotEmpty &&
        newMatchIndex >= election.rounds[newRoundIndex].matches.length) {
      newMatchIndex = 0;
      newRoundIndex++;
    }

    _elections[index] = election.copyWith(
      currentMatchIndex: newMatchIndex,
      currentRoundIndex: newRoundIndex,
    );

    notifyListeners();
  }

  // End the election
  void endElection(String electionId) {
    final election = getElectionById(electionId);
    if (election == null) return;

    final index = _elections.indexOf(election);
    _elections[index] = election.copyWith(isActive: false);
    notifyListeners();
  }

  // Helper: Generate knockout rounds (bracket-style)
  List<Round> _generateKnockoutRounds(List<Competitor> competitors) {
    final rounds = <Round>[];
    var currentCompetitors = competitors.map((c) => c.id).toList();
    var roundNum = 1;

    while (currentCompetitors.length > 1) {
      final matches = <Match>[];
      for (var i = 0; i < currentCompetitors.length; i += 2) {
        if (i + 1 < currentCompetitors.length) {
          matches.add(Match(
            id: _uuid.v4(),
            competitorIds: [currentCompetitors[i], currentCompetitors[i + 1]],
          ));
        }
      }

      rounds.add(Round(
        id: _uuid.v4(),
        roundNumber: roundNum,
        matches: matches,
      ));

      // Next round has half the competitors (winners only)
      currentCompetitors = List.generate(
        matches.length,
        (i) => 'winner_${roundNum}_$i',
      );
      roundNum++;
    }

    return rounds;
  }

  // Helper: Generate groups
  List<Group> _generateGroups(List<Competitor> competitors, int numGroups) {
    final groups = <Group>[];
    final competitorsPerGroup = (competitors.length / numGroups).ceil();

    for (var i = 0; i < numGroups; i++) {
      final start = i * competitorsPerGroup;
      final end = min((i + 1) * competitorsPerGroup, competitors.length);
      final groupCompetitors = competitors.sublist(start, end);

      groups.add(Group(
        id: _uuid.v4(),
        name: 'Group ${String.fromCharCode(65 + i)}', // A, B, C, etc.
        competitorIds: groupCompetitors.map((c) => c.id).toList(),
      ));
    }

    return groups;
  }

  // Helper: Generate league rounds (round-robin)
  List<Round> _generateLeagueRounds(List<Competitor> competitors) {
    final rounds = <Round>[];
    // Simplified: create one round with all possible matches
    final matches = <Match>[];
    
    for (var i = 0; i < competitors.length; i++) {
      for (var j = i + 1; j < competitors.length; j++) {
        matches.add(Match(
          id: _uuid.v4(),
          competitorIds: [competitors[i].id, competitors[j].id],
        ));
      }
    }

    if (matches.isNotEmpty) {
      rounds.add(Round(
        id: _uuid.v4(),
        roundNumber: 1,
        matches: matches,
      ));
    }

    return rounds;
  }

  // Helper: Update a specific match
  void _updateMatch(Election election, String matchId, Match updatedMatch) {
    final rounds = election.rounds.map((round) {
      final matches = round.matches.map((match) {
        return match.id == matchId ? updatedMatch : match;
      }).toList();
      return round.copyWith(matches: matches);
    }).toList();

    final index = _elections.indexOf(election);
    _elections[index] = election.copyWith(rounds: rounds);
    notifyListeners();
  }

  // Helper: Generate random code
  String _generateCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(4, (_) => chars[random.nextInt(chars.length)]).join();
  }
}
