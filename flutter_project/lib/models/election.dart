// Models for the Elections Management App
// These represent the core data structures used throughout the app.
// TODO: When integrating with backend, add fromJson/toJson methods for serialization.

enum ElectionFormat {
  knockout,
  group,
  league,
  legacy,
}

enum LegacySubformat {
  // legacy-1: vote for 1 of n competitors (vote = 1 point)
  voteForOne,
  // legacy-2: vote for m of n competitors (each vote = 1 point)
  voteForMultiple,
  // legacy-3: vote for m of n competitors with weighted points (first=m, second=m-1, etc)
  voteForMultipleWeighted,
}

class Competitor {
  final String id;
  final String name;
  int points;
  int wins;
  int losses;

  Competitor({
    required this.id,
    required this.name,
    this.points = 0,
    this.wins = 0,
    this.losses = 0,
  });

  Competitor copyWith({
    String? id,
    String? name,
    int? points,
    int? wins,
    int? losses,
  }) {
    return Competitor(
      id: id ?? this.id,
      name: name ?? this.name,
      points: points ?? this.points,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
    );
  }
}

class Match {
  final String id;
  final List<String> competitorIds; // IDs of competitors in this match
  String? winnerId;
  bool isComplete;
  Map<String, int> votes; // competitorId -> vote count
  Set<String> votedUserIds; // Track which users have voted

  Match({
    required this.id,
    required this.competitorIds,
    this.winnerId,
    this.isComplete = false,
    Map<String, int>? votes,
    Set<String>? votedUserIds,
  }) : votes = votes ?? {},
       votedUserIds = votedUserIds ?? {};

  Match copyWith({
    String? id,
    List<String>? competitorIds,
    String? winnerId,
    bool? isComplete,
    Map<String, int>? votes,
    Set<String>? votedUserIds,
  }) {
    return Match(
      id: id ?? this.id,
      competitorIds: competitorIds ?? this.competitorIds,
      winnerId: winnerId ?? this.winnerId,
      isComplete: isComplete ?? this.isComplete,
      votes: votes ?? this.votes,
      votedUserIds: votedUserIds ?? this.votedUserIds,
    );
  }
}

class Round {
  final String id;
  // roundNumber removed
  final List<Match> matches;

  Round({
    required this.id,
    // roundNumber removed
    required this.matches,
  });

  Round copyWith({
    String? id,
    // roundNumber removed
    List<Match>? matches,
  }) {
    return Round(
      id: id ?? this.id,
      // roundNumber removed
      matches: matches ?? this.matches,
    );
  }
}

class Group {
  final String id;
  final String name;
  final List<String> competitorIds;

  Group({
    required this.id,
    required this.name,
    required this.competitorIds,
  });

  Group copyWith({
    String? id,
    String? name,
    List<String>? competitorIds,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      competitorIds: competitorIds ?? this.competitorIds,
    );
  }
}

class Election {
  final String id;
  final String name;
  final String description;
  final ElectionFormat format;
  final String code; // For private joining
  final String creatorId;
  final bool isPublic;
  final bool isActive;
  final DateTime createdAt;
  
  // Competitors
  final List<Competitor> competitors;
  
  // For group format
  final List<Group> groups;
  final bool hasWeightedGroups;
  
  // For knockout/league format
  final List<Round> rounds;
  int currentRoundIndex;
  int currentMatchIndex;
  
  // For legacy format
  final LegacySubformat? legacySubformat;
  final int? legacyVoteCount; // m in "vote for m of n"
  final Set<String> legacyVotedUserIds; // Track users who voted in legacy format
  
  // Participants (user IDs who joined)
  final List<String> participantIds;

  Election({
    required this.id,
    required this.name,
    this.description = '',
    required this.format,
    required this.code,
    required this.creatorId,
    this.isPublic = true,
    this.isActive = true,
    required this.createdAt,
    List<Competitor>? competitors,
    List<Group>? groups,
    this.hasWeightedGroups = false,
    List<Round>? rounds,
    this.currentRoundIndex = 0,
    this.currentMatchIndex = 0,
    this.legacySubformat,
    this.legacyVoteCount,
    Set<String>? legacyVotedUserIds,
    List<String>? participantIds,
  })  : competitors = competitors ?? [],
        groups = groups ?? [],
        rounds = rounds ?? [],
        legacyVotedUserIds = legacyVotedUserIds ?? {},
        participantIds = participantIds ?? [];

  bool get isEnded => !isActive;
  
  Match? get currentMatch {
    if (rounds.isEmpty || currentRoundIndex >= rounds.length) return null;
    final round = rounds[currentRoundIndex];
    if (currentMatchIndex >= round.matches.length) return null;
    return round.matches[currentMatchIndex];
  }

  Election copyWith({
    String? id,
    String? name,
    String? description,
    ElectionFormat? format,
    String? code,
    String? creatorId,
    bool? isPublic,
    bool? isActive,
    DateTime? createdAt,
    List<Competitor>? competitors,
    List<Group>? groups,
    bool? hasWeightedGroups,
    List<Round>? rounds,
    int? currentRoundIndex,
    int? currentMatchIndex,
    LegacySubformat? legacySubformat,
    int? legacyVoteCount,
    Set<String>? legacyVotedUserIds,
    List<String>? participantIds,
  }) {
    return Election(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      format: format ?? this.format,
      code: code ?? this.code,
      creatorId: creatorId ?? this.creatorId,
      isPublic: isPublic ?? this.isPublic,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      competitors: competitors ?? this.competitors,
      groups: groups ?? this.groups,
      hasWeightedGroups: hasWeightedGroups ?? this.hasWeightedGroups,
      rounds: rounds ?? this.rounds,
      currentRoundIndex: currentRoundIndex ?? this.currentRoundIndex,
      currentMatchIndex: currentMatchIndex ?? this.currentMatchIndex,
      legacySubformat: legacySubformat ?? this.legacySubformat,
      legacyVoteCount: legacyVoteCount ?? this.legacyVoteCount,
      legacyVotedUserIds: legacyVotedUserIds ?? this.legacyVotedUserIds,
      participantIds: participantIds ?? this.participantIds,
    );
  }
}
